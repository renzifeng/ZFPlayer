//
//  TXPlayerManager.m
//  luotuo
//
//  Created by guduzhonglao on 4/15/20.
//  Copyright © 2020 guduzhonglao. All rights reserved.
//

#import "TXLivePlayerManager.h"

@interface TXLivePlayerManager ()<TXLivePlayListener>

@end

@implementation TXLivePlayerManager

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

- (void)destory {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _isPlaying = NO;
    _isPreparedToPlay = NO;
}

- (void)dealloc {
    [self stop];
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
    _loadState = ZFPlayerLoadStatePrepare;
    if (self.playerPrepareToPlay) self.playerPrepareToPlay(self, self.assetURL);
}

- (void)play {
    if (!_isPreparedToPlay) {
        [self prepareToPlay];
    } else {
        NSString* url = [self.assetURL absoluteString];
        TX_Enum_PlayType playtype;
        if ([url hasPrefix:@"rtmp://"]) {
            playtype=0;
        }else if ([url hasSuffix:@".flv"]){
            playtype=1;
        }else if ([url hasSuffix:@".m3u8"]){
            playtype=3;
        }else{
            playtype=5;
        }
        [_player setupVideoWidget:[UIScreen mainScreen].bounds containView:_view insertIndex:1];
        [self.player startPlay:url type:playtype];
        _isPlaying = YES;
        _playState = ZFPlayerPlayStatePlaying;
    }
}

- (void)stop{
    [self.player stopPlay];
    [self.player removeVideoWidget];
}

- (void)pause{
    [self.player pause];
}

- (void)initializePlayer {
    if (self.player) [self.player stopPlay];
    _player = [[TXLivePlayer alloc] init];
    self.player.isAutoPlay = self.shouldAutoPlay;
    self.player.delegate=self;
    _view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scalingMode = _scalingMode;
    [self.player setRenderMode:RENDER_MODE_FILL_SCREEN];
}

- (void)onPlayEvent:(int)EvtID withParam:(NSDictionary *)param{
    
}

- (ZFPlayerView *)view {
    if (!_view) {
        _view = [[ZFPlayerView alloc] init];
    }
    return _view;
}

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
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    [self.player setMute:muted];
}

- (void)setVolume:(float)volume {
    _volume = MIN(MAX(0, volume), 2);
    [self.player setVolume:volume*100];
}

- (void)setScalingMode:(ZFPlayerScalingMode)scalingMode {
    _scalingMode = scalingMode;
    switch (scalingMode) {
        case ZFPlayerScalingModeNone:
            [self.player setRenderMode:RENDER_MODE_FILL_SCREEN];
            break;
        case ZFPlayerScalingModeAspectFit:
            [self.player setRenderMode:RENDER_MODE_FILL_EDGE];
            break;
        case ZFPlayerScalingModeAspectFill:
            [self.player setRenderMode:RENDER_MODE_FILL_SCREEN];
            break;
        case ZFPlayerScalingModeFill:
            [self.player setRenderMode:RENDER_MODE_FILL_SCREEN];
            break;
        default:
            break;
    }
}

@end
