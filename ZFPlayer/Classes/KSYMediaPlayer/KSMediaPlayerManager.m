//
//  KSMediaPlayerManager.m
//  ZFPlayer
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "KSMediaPlayerManager.h"
#import "ZFPlayerView.h"
#if __has_include(<ZFPlayer/ZFPlayer.h>)
#import <ZFPlayer/ZFPlayer.h>
#else
#import "ZFPlayer.h"
#endif

#if __has_include(<KSYMediaPlayer/KSYMediaPlayer.h>)
#import <KSYMediaPlayer/KSYMediaPlayer.h>

static NSString *const kCurrentPlaybackTime = @"currentPlaybackTime";

@interface KSMediaPlayerManager () {
    ZFKVOController *_playerItemKVO;
}
@property (nonatomic, strong) KSYMoviePlayerController *player;

@end

@implementation KSMediaPlayerManager

@synthesize view                           = _view;
@synthesize currentTime                    = _currentTime;
@synthesize totalTime                      = _totalTime;
@synthesize playerPlayTimeChanged          = _playerPlayTimeChanged;
@synthesize playerBufferTimeChanged        = _playerBufferTimeChanged;
@synthesize playerDidToEnd                 = _playerDidToEnd;
@synthesize bufferTime                     = _bufferTime;
@synthesize playState                      = _playState;
@synthesize loadState                      = _loadState;
@synthesize playerSource                       = _playerSource;
@synthesize playerPrepareToPlay            = _playerPrepareToPlay;
@synthesize playerPlayStatChanged          = _playerPlayStatChanged;
@synthesize playerLoadStatChanged          = _playerLoadStatChanged;
@synthesize seekTime                       = _seekTime;
@synthesize muted                          = _muted;
@synthesize volume                         = _volume;
@synthesize presentationSize               = _presentationSize;
@synthesize isPlaying                      = _isPlaying;
@synthesize rate                           = _rate;
@synthesize isPreparedToPlay               = _isPreparedToPlay;
@synthesize scalingMode                    = _scalingMode;
@synthesize playerPlayFailed               = _playerPlayFailed;

- (void)dealloc {
    [self destory];
}

- (void)destory {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_playerItemKVO safelyRemoveAllObservers];
    _isPlaying = NO;
    _isPreparedToPlay = NO;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _scalingMode = ZFPlayerScalingModeAspectFit;
    }
    return self;
}

- (void)prepareToPlay {
    if (!_playerSource) return;
    _isPreparedToPlay = YES;
    self.loadState = ZFPlayerLoadStatePrepare;
    [self initializePlayer];
    if (self.playerPrepareToPlay) self.playerPrepareToPlay(self, self.playerSource);
    [self.player prepareToPlay];
}

- (void)play {
    if (!_isPreparedToPlay) {
        [self prepareToPlay];
    } else {
        [self.player play];
        self.player.playbackSpeed = self.rate;
        _isPlaying = YES;
        self.playState = ZFPlayerPlayStatePlaying;
    }
}

- (void)pause {
    [self.player pause];
    _isPlaying = NO;
    self.playState = ZFPlayerPlayStatePaused;
}

- (void)stop {
    self.playState = ZFPlayerPlayStatePlayStopped;
    [self.player stop];
    [self.player.view removeFromSuperview];
    [self destory];
    self.player = nil;
    self->_currentTime = 0;
    self->_totalTime = 0;
    self->_bufferTime = 0;
}

- (void)replay {
    @weakify(self)
    [self seekToTime:0 completionHandler:^(BOOL finished) {
        @strongify(self)
        [self play];
    }];
}

/// 更换当前的播放地址
- (void)replaceCurrentPlayerSource:(id<ZFPlayerSource>)playerSource {
    if (self.player) [self stop];
    _playerSource = playerSource;
    [self prepareToPlay];
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler {
    [self.player seekTo:time accurate:YES];
    if (completionHandler) completionHandler(YES);
}

- (UIImage *)thumbnailImageAtCurrentTime {
    return [self.player thumbnailImageAtCurrentTime];
}

- (void)reloadPlayer {
    self.seekTime = self.currentTime;
    [self prepareToPlay];
}

- (void)initializePlayer {
    self.player = [[KSYMoviePlayerController alloc] initWithContentURL:_playerSource];
    self.player.shouldAutoplay = YES;
    [self addPlayerNotification];
    
    [self.view insertSubview:self.player.view atIndex:1];
    self.player.view.frame = self.view.bounds;
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scalingMode = _scalingMode;
    self.player.controlStyle = MPMovieControlStyleNone;
}

- (void)addPlayerNotification {
    /// 准备开始播放了
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPrepared:)
                                                 name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:self.player];
    /// 播放状态改变
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateDidChange:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.player];
    /// 播放完成
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.player];
    /// 缓冲状态改变了
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bufferChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:self.player];
    
    /// 视频的尺寸变化了
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sizeAvailableChange:)
                                                 name:MPMovieNaturalSizeAvailableNotification
                                               object:self.player];
    /// 当视频第一次渲染
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFirstFrame:)
                                                 name:MPMoviePlayerFirstVideoFrameRenderedNotification
                                               object:self.player];
    /// 播放解码状态
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStatusChange:)
                                                 name:MPMoviePlayerPlaybackStatusNotification
                                               object:self.player];
    /// 快接、快退完成
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(seekDone:)
                                                 name:MPMoviePlayerSeekCompleteNotification
                                               object:self.player];
    
    /// 应该刷新url是够调用
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(suggestReloadChange:)
                                                 name:MPMoviePlayerSuggestReloadNotification
                                               object:self.player];
    
    [_playerItemKVO safelyRemoveAllObservers];
    _playerItemKVO = [[ZFKVOController alloc] initWithTarget:_player];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kCurrentPlaybackTime
                              options:NSKeyValueObservingOptionNew
                              context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([keyPath isEqualToString:kCurrentPlaybackTime]) {
            self->_currentTime = self.player.currentPlaybackTime;
            self->_totalTime = self.player.duration;
            self->_bufferTime = self.player.playableDuration;
            if (self.playerPlayTimeChanged) self.playerPlayTimeChanged(self, self->_currentTime, self->_totalTime);
            if (self.playerBufferTimeChanged) self.playerBufferTimeChanged(self, self->_bufferTime);
        }
    });
}

#pragma mark - Notification

/// 播放器初始化视频文件完成通知
- (void)videoPrepared:(NSNotification *)notify {
    self.player.shouldMute = self.muted;
    if (self.seekTime) {
        [self seekToTime:self.seekTime completionHandler:nil];
        self.seekTime = 0; // 滞空, 防止下次播放出错
    }
    [self play];
    self.player.shouldMute = self.muted;
    /// 需要延迟改为ok状态，不然显示会有一点问题。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.loadState = ZFPlayerLoadStatePlaythroughOK;
    });
}

/// 播放完成通知。视频正常播放完成时触发。
- (void)videoFinish:(NSNotification *)notify {
    NSInteger reason = [[notify.userInfo valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
    if (reason == MPMovieFinishReasonPlaybackEnded) {
        self.playState = ZFPlayerPlayStatePlayStopped;
        if (self.playerDidToEnd) self.playerDidToEnd(self);
    } else if (reason == MPMovieFinishReasonPlaybackError) {
        self.playState = ZFPlayerPlayStatePlayFailed;
        NSString *error = [notify.userInfo valueForKey:@"error"];
        ZFPlayerLog(@"player Error : %@", error);
        if (self.playerPlayFailed) self.playerPlayFailed(self, error);
    } else if (reason == MPMovieFinishReasonUserExited){
        /// player userExited
    }
}

/// 播放器Seek完成后发送该通知。
- (void)seekDone:(NSNotification *)notify {
    [self play];
}

/// 视频的尺寸变化了
- (void)sizeAvailableChange:(NSNotification *)notify {
    // 如果想要在宽大于高的时候横屏播放，你可以在这里旋转
}

- (void)bufferChange:(NSNotification *)notify {
    if (self.player.loadState == MPMovieLoadStateStalled) { /// 播放器开始缓冲视频时发送该通知
        ZFPlayerLog(@"player start caching");
        self.loadState = ZFPlayerLoadStateStalled;
    } else {
        self.loadState = ZFPlayerLoadStatePlayable;
    }
}

/// 播放器首帧出现
- (void)videoFirstFrame:(NSNotification *)notify {
    
}

/// 播放状态改变
- (void)playbackStateDidChange:(NSNotification *)notify {
    ZFPlayerLog(@"player playback state: %ld", (long)self.player.playbackState);
}

/// 播放解码状态
- (void)playbackStatusChange:(NSNotification *)notify {
    int status = [[[notify userInfo] valueForKey:MPMoviePlayerPlaybackStatusUserInfoKey] intValue];
    if (MPMovieStatusVideoDecodeWrong == status) {
        ZFPlayerLog(@"Video Decode Wrong!\n");
    } else if(MPMovieStatusAudioDecodeWrong == status) {
        ZFPlayerLog(@"Audio Decode Wrong!\n");
    } else if (MPMovieStatusHWCodecUsed == status ) {
        ZFPlayerLog(@"Hardware Codec used\n");
    } else if (MPMovieStatusSWCodecUsed == status ) {
        ZFPlayerLog(@"Software Codec used\n");
    } else if(MPMovieStatusDLCodecUsed == status) {
        ZFPlayerLog(@"AVSampleBufferDisplayLayer  Codec used");
    }
}

- (void)suggestReloadChange:(NSNotification *)notify {
    [self.player reload:self.playerSource];
}

#pragma mark - getter

- (ZFPlayerView *)view {
    if (!_view) {
        _view = [[ZFPlayerView alloc] init];
        _view.backgroundColor = [UIColor blackColor];
    }
    return _view;
}

- (float)rate {
    return _rate == 0 ?1:_rate;
}

#pragma mark - setter

- (void)setPlayState:(ZFPlayerPlaybackState)playState {
    _playState = playState;
    if (self.playerPlayStatChanged) self.playerPlayStatChanged(self, playState);
}

- (void)setLoadState:(ZFPlayerLoadState)loadState {
    _loadState = loadState;
    if (self.playerLoadStatChanged) self.playerLoadStatChanged(self, loadState);
}

- (void)setPlayerSource:(id<ZFPlayerSource>)playerSource {
    _playerSource = playerSource;
    [self replaceCurrentPlayerSource:playerSource];
}

- (void)setRate:(float)rate {
    _rate = rate;
    self.player.playbackSpeed = rate;
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    self.player.shouldMute = muted;
}

- (void)setVolume:(float)volume {
    _volume = MIN(MAX(0, volume), 2);
    [self.player setVolume:volume rigthVolume:volume];
}

- (void)setScalingMode:(ZFPlayerScalingMode)scalingMode {
    _scalingMode = scalingMode;
    switch (scalingMode) {
        case ZFPlayerScalingModeNone:
            self.player.scalingMode = MPMovieScalingModeNone;
            break;
        case ZFPlayerScalingModeAspectFit:
            self.player.scalingMode = MPMovieScalingModeAspectFit;
            break;
        case ZFPlayerScalingModeAspectFill:
            self.player.scalingMode = MPMovieScalingModeAspectFill;
            break;
        case ZFPlayerScalingModeFill:
            self.player.scalingMode = MPMovieScalingModeFill;
            break;
        default:
            break;
    }
}

@end

#endif
