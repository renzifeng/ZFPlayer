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
#if __has_include(<ZFPlayer/ZFPlayer.h>)
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFPlayerView.h>
#else
#import "ZFPlayer.h"
#import "ZFPlayerView.h"
#endif
#if __has_include(<KSYMediaPlayer/KSYMediaPlayer.h>)

@interface KSMediaPlayerManager ()
@property (nonatomic, strong) KSYMoviePlayerController *player;
@property (nonatomic, assign) BOOL isReadyToPlay;
@property (nonatomic, strong) NSTimer *timer;

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
@synthesize assetURL                       = _assetURL;
@synthesize playerPrepareToPlay            = _playerPrepareToPlay;
@synthesize playerReadyToPlay              = _playerReadyToPlay;
@synthesize playerPlayStateChanged         = _playerPlayStateChanged;
@synthesize playerLoadStateChanged         = _playerLoadStateChanged;
@synthesize seekTime                       = _seekTime;
@synthesize muted                          = _muted;
@synthesize volume                         = _volume;
@synthesize presentationSize               = _presentationSize;
@synthesize isPlaying                      = _isPlaying;
@synthesize rate                           = _rate;
@synthesize isPreparedToPlay               = _isPreparedToPlay;
@synthesize shouldAutoPlay                 = _shouldAutoPlay;
@synthesize scalingMode                    = _scalingMode;
@synthesize playerPlayFailed               = _playerPlayFailed;
@synthesize presentationSizeChanged        = _presentationSizeChanged;

- (void)dealloc {
    [self stop];
}

- (void)destory {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _isPlaying = NO;
    _isPreparedToPlay = NO;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _scalingMode = ZFPlayerScalingModeAspectFit;
        _shouldAutoPlay = YES;
    }
    return self;
}

- (void)prepareToPlay {
    if (!_assetURL) return;
    _isPreparedToPlay = YES;
    [self initializePlayer];
    if (self.shouldAutoPlay) {
        [self play];
    }
    self.loadState = ZFPlayerLoadStatePrepare;
    if (self.playerPrepareToPlay) self.playerPrepareToPlay(self, self.assetURL);
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
    [self.player stop];
    [self.player.view removeFromSuperview];
    [self destory];
    self.player = nil;
    self->_currentTime = 0;
    self->_totalTime = 0;
    self->_bufferTime = 0;
    self.isReadyToPlay = NO;
    [self.timer invalidate];
    self.timer = nil;
    self.playState = ZFPlayerPlayStatePlayStopped;
}

- (void)replay {
    @weakify(self)
    [self seekToTime:0 completionHandler:^(BOOL finished) {
        @strongify(self)
        [self play];
    }];
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler {
    if (self.player.duration > 0) {
        [self.player seekTo:time accurate:YES];
        if (completionHandler) completionHandler(YES);
    } else {
        self.seekTime = time;
    }
}

- (UIImage *)thumbnailImageAtCurrentTime {
    return [self.player thumbnailImageAtCurrentTime];
}

- (void)reloadPlayer {
    self.seekTime = self.currentTime;
    [self prepareToPlay];
}

- (void)initializePlayer {
    if (self.player) [self.player stop];
    self.player = [[KSYMoviePlayerController alloc] initWithContentURL:_assetURL];
    self.player.shouldAutoplay = self.shouldAutoPlay;
    [self.player prepareToPlay];
    [self addPlayerNotification];
    
    [self.view insertSubview:self.player.view atIndex:2];
    self.player.view.backgroundColor = [UIColor clearColor];
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
}

- (void)timerUpdate {
    if (self.player.currentPlaybackTime > 0 && !self.isReadyToPlay) {
        self.isReadyToPlay = YES;
        self.loadState = ZFPlayerLoadStatePlaythroughOK;
    }
    self->_currentTime = self.player.currentPlaybackTime > 0 ? self.player.currentPlaybackTime : 0;
    self->_totalTime = self.player.duration;
    self->_bufferTime = self.player.playableDuration;
    if (self.playerPlayTimeChanged) self.playerPlayTimeChanged(self, self->_currentTime, self->_totalTime);
    if (self.playerBufferTimeChanged) self.playerBufferTimeChanged(self, self->_bufferTime);
}

#pragma mark - Notification

/// 播放器初始化视频文件完成通知
- (void)videoPrepared:(NSNotification *)notify {
    // 视频开始播放的时候开启计时器
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeRefreshInterval > 0 ? self.timeRefreshInterval : 0.1 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    self.player.shouldMute = self.muted;
    if (self.seekTime > 0) {
        [self seekToTime:self.seekTime completionHandler:nil];
        self.seekTime = 0; // 滞空, 防止下次播放出错
    }
    [self play];
    self.player.shouldMute = self.muted;
    if (self.playerReadyToPlay) self.playerReadyToPlay(self, self.assetURL);
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
    } else if (reason == MPMovieFinishReasonUserExited) {
        /// player userExited
    }
}

/// 播放器Seek完成后发送该通知。
- (void)seekDone:(NSNotification *)notify {
    [self play];
}

/// 视频的尺寸变化了
- (void)sizeAvailableChange:(NSNotification *)notify {
    self->_presentationSize = self.player.naturalSize;
    if (self.presentationSizeChanged) {
        self.presentationSizeChanged(self, self->_presentationSize);
    }
}

- (void)bufferChange:(NSNotification *)notify {
    if (self.player.loadState == MPMovieLoadStateStalled) { /// 播放器开始缓冲视频时发送该通知
        ZFPlayerLog(@"player start caching");
        self.loadState = ZFPlayerLoadStateStalled;
    } else {
        if (self.player.currentPlaybackTime > 0) {
            self.loadState = ZFPlayerLoadStatePlayable;
        } else {
            self.loadState = ZFPlayerLoadStateUnknown;
        }
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
    [self.player reload:self.assetURL];
}

#pragma mark - getter

- (ZFPlayerView *)view {
    if (!_view) {
        _view = [[ZFPlayerView alloc] init];
    }
    return _view;
}

- (float)rate {
    return _rate == 0 ?1:_rate;
}

#pragma mark - setter

- (void)setPlayState:(ZFPlayerPlaybackState)playState {
    _playState = playState;
    if (self.playerPlayStateChanged) self.playerPlayStateChanged(self, playState);
}

- (void)setLoadState:(ZFPlayerLoadState)loadState {
    _loadState = loadState;
    if (self.playerLoadStateChanged) self.playerLoadStateChanged(self, loadState);
}

- (void)setAssetURL:(NSURL *)assetURL {
    if (self.player) [self stop];
    _assetURL = assetURL;
    [self prepareToPlay];
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
