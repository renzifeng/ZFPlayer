//
//  ZFPlayerController.m
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

#import "ZFPlayerController.h"
#import <objc/runtime.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "UIScrollView+ZFPlayer.h"
#import "ZFReachabilityManager.h"
#import "ZFPlayerConst.h"

static NSMutableDictionary <NSString* ,NSNumber *> *_zfPlayRecords;

@interface ZFPlayerController ()

@property (nonatomic, strong) ZFPlayerNotification *notification;
@property (nonatomic, strong) UISlider *volumeViewSlider;
@property (nonatomic, assign) NSInteger containerViewTag;
@property (nonatomic, assign) ZFPlayerContainerType containerType;
/// The player's small container view.
@property (nonatomic, strong) ZFFloatView *smallFloatView;
/// Whether the small window is displayed.
@property (nonatomic, assign) BOOL isSmallFloatViewShow;
/// The indexPath is playing.
@property (nonatomic, nullable) NSIndexPath *playingIndexPath;

@end

@implementation ZFPlayerController

@dynamic containerViewTag;
@dynamic playingIndexPath;

- (instancetype)init {
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _zfPlayRecords = @{}.mutableCopy;
        });
        @zf_weakify(self)
        [[ZFReachabilityManager sharedManager] startMonitoring];
        [[ZFReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(ZFReachabilityStatus status) {
            @zf_strongify(self)
            if ([self.controlView respondsToSelector:@selector(videoPlayer:reachabilityChanged:)]) {
                [self.controlView videoPlayer:self reachabilityChanged:status];
            }
        }];
        [self configureVolume];
    }
    return self;
}

/// Get system volume
- (void)configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    self.volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            self.volumeViewSlider = (UISlider *)view;
            break;
        }
    }
}

- (void)dealloc {
    [self.currentPlayerManager stop];
}

+ (instancetype)playerWithPlayerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(nonnull UIView *)containerView {
    ZFPlayerController *player = [[self alloc] initWithPlayerManager:playerManager containerView:containerView];
    return player;
}

+ (instancetype)playerWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag {
    ZFPlayerController *player = [[self alloc] initWithScrollView:scrollView playerManager:playerManager containerViewTag:containerViewTag];
    return player;
}

+ (instancetype)playerWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(UIView *)containerView {
    ZFPlayerController *player = [[self alloc] initWithScrollView:scrollView playerManager:playerManager containerView:containerView];
    return player;
}

- (instancetype)initWithPlayerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(nonnull UIView *)containerView {
    ZFPlayerController *player = [self init];
    player.containerView = containerView;
    player.currentPlayerManager = playerManager;
    player.containerType = ZFPlayerContainerTypeView;
    return player;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag {
    ZFPlayerController *player = [self init];
    player.scrollView = scrollView;
    player.containerViewTag = containerViewTag;
    player.currentPlayerManager = playerManager;
    player.containerType = ZFPlayerContainerTypeCell;
    return player;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(UIView *)containerView {
    ZFPlayerController *player = [self init];
    player.scrollView = scrollView;
    player.containerView = containerView;
    player.currentPlayerManager = playerManager;
    player.containerType = ZFPlayerContainerTypeView;
    return player;
}

- (void)playerManagerCallbcak {
    @zf_weakify(self)
    self.currentPlayerManager.playerPrepareToPlay = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSURL * _Nonnull assetURL) {
        @zf_strongify(self)
        if (self.resumePlayRecord && [_zfPlayRecords valueForKey:assetURL.absoluteString]) {
            NSTimeInterval seekTime = [_zfPlayRecords valueForKey:assetURL.absoluteString].doubleValue;
            self.currentPlayerManager.seekTime = seekTime;
        }
        [self.notification addNotification];
        [self addDeviceOrientationObserver];
        if (self.scrollView) {
            self.scrollView.zf_stopPlay = NO;
        }
        [self layoutPlayerSubViews];
        if (self.playerPrepareToPlay) self.playerPrepareToPlay(asset,assetURL);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:prepareToPlay:)]) {
            [self.controlView videoPlayer:self prepareToPlay:assetURL];
        }
    };
    
    self.currentPlayerManager.playerReadyToPlay = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSURL * _Nonnull assetURL) {
        @zf_strongify(self)
        if (self.playerReadyToPlay) self.playerReadyToPlay(asset,assetURL);
        if (!self.customAudioSession) {
            // Apps using this category don't mute when the phone's mute button is turned on, but play sound when the phone is silent
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
        }
        if (self.viewControllerDisappear) self.pauseByEvent = YES;
    };
    
    self.currentPlayerManager.playerPlayTimeChanged = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSTimeInterval currentTime, NSTimeInterval duration) {
        @zf_strongify(self)
        if (self.playerPlayTimeChanged) self.playerPlayTimeChanged(asset,currentTime,duration);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:currentTime:totalTime:)]) {
            [self.controlView videoPlayer:self currentTime:currentTime totalTime:duration];
        }
        if (self.currentPlayerManager.assetURL.absoluteString) {
            [_zfPlayRecords setValue:@(currentTime) forKey:self.currentPlayerManager.assetURL.absoluteString];
        }
    };
    
    self.currentPlayerManager.playerBufferTimeChanged = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSTimeInterval bufferTime) {
        @zf_strongify(self)
        if ([self.controlView respondsToSelector:@selector(videoPlayer:bufferTime:)]) {
            [self.controlView videoPlayer:self bufferTime:bufferTime];
        }
        if (self.playerBufferTimeChanged) self.playerBufferTimeChanged(asset,bufferTime);
    };
    
    self.currentPlayerManager.playerPlayStateChanged = ^(id  _Nonnull asset, ZFPlayerPlaybackState playState) {
        @zf_strongify(self)
        if (self.playerPlayStateChanged) self.playerPlayStateChanged(asset, playState);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:playStateChanged:)]) {
            [self.controlView videoPlayer:self playStateChanged:playState];
        }
    };
    
    self.currentPlayerManager.playerLoadStateChanged = ^(id  _Nonnull asset, ZFPlayerLoadState loadState) {
        @zf_strongify(self)
        if (loadState == ZFPlayerLoadStatePrepare && CGSizeEqualToSize(CGSizeZero, self.currentPlayerManager.presentationSize)) {
            CGSize size = self.currentPlayerManager.view.frame.size;
            self.orientationObserver.presentationSize = size;
        }
        if (self.playerLoadStateChanged) self.playerLoadStateChanged(asset, loadState);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:loadStateChanged:)]) {
            [self.controlView videoPlayer:self loadStateChanged:loadState];
        }
    };
    
    self.currentPlayerManager.playerDidToEnd = ^(id  _Nonnull asset) {
        @zf_strongify(self)
        if (self.currentPlayerManager.assetURL.absoluteString) {
            [_zfPlayRecords setValue:@(0) forKey:self.currentPlayerManager.assetURL.absoluteString];
        }
        if (self.playerDidToEnd) self.playerDidToEnd(asset);
        if ([self.controlView respondsToSelector:@selector(videoPlayerPlayEnd:)]) {
            [self.controlView videoPlayerPlayEnd:self];
        }
    };
    
    self.currentPlayerManager.playerPlayFailed = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, id  _Nonnull error) {
        @zf_strongify(self)
        if (self.playerPlayFailed) self.playerPlayFailed(asset, error);
        if ([self.controlView respondsToSelector:@selector(videoPlayerPlayFailed:error:)]) {
            [self.controlView videoPlayerPlayFailed:self error:error];
        }
    };
    
    self.currentPlayerManager.presentationSizeChanged = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, CGSize size){
        @zf_strongify(self)
        self.orientationObserver.presentationSize = size;
        if (self.orientationObserver.fullScreenMode == ZFFullScreenModeAutomatic) {
            if (size.width > size.height) {
                self.orientationObserver.fullScreenMode = ZFFullScreenModeLandscape;
            } else {
                self.orientationObserver.fullScreenMode = ZFFullScreenModePortrait;
            }
        }
        if (self.presentationSizeChanged) self.presentationSizeChanged(asset, size);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:presentationSizeChanged:)]) {
            [self.controlView videoPlayer:self presentationSizeChanged:size];
        }
    };
}

- (void)layoutPlayerSubViews {
    if (self.containerView && self.currentPlayerManager.view && self.currentPlayerManager.isPreparedToPlay) {
        UIView *superview = nil;
        if (self.isFullScreen) {
            superview = self.orientationObserver.fullScreenContainerView;
        } else if (self.containerView) {
            superview = self.containerView;
        }
        [superview addSubview:self.currentPlayerManager.view];
        [self.currentPlayerManager.view addSubview:self.controlView];
        
        self.currentPlayerManager.view.frame = superview.bounds;
        self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.controlView.frame = self.currentPlayerManager.view.bounds;
        self.controlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.orientationObserver updateRotateView:self.currentPlayerManager.view containerView:self.containerView];
    }
}

#pragma mark - getter

- (ZFPlayerNotification *)notification {
    if (!_notification) {
        _notification = [[ZFPlayerNotification alloc] init];
        @zf_weakify(self)
        _notification.willResignActive = ^(ZFPlayerNotification * _Nonnull registrar) {
            @zf_strongify(self)
            if (self.isViewControllerDisappear) return;
            if (self.pauseWhenAppResignActive && self.currentPlayerManager.isPlaying) {
                self.pauseByEvent = YES;
            }
            self.orientationObserver.lockedScreen = YES;
            [[UIApplication sharedApplication].keyWindow endEditing:YES];
            if (!self.pauseWhenAppResignActive) {
                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                [[AVAudioSession sharedInstance] setActive:YES error:nil];
            }
        };
        _notification.didBecomeActive = ^(ZFPlayerNotification * _Nonnull registrar) {
            @zf_strongify(self)
            if (self.isViewControllerDisappear) return;
            if (self.isPauseByEvent) self.pauseByEvent = NO;
            self.orientationObserver.lockedScreen = NO;
        };
        _notification.oldDeviceUnavailable = ^(ZFPlayerNotification * _Nonnull registrar) {
            @zf_strongify(self)
            if (self.currentPlayerManager.isPlaying) {
                [self.currentPlayerManager play];
            }
        };
    }
    return _notification;
}

- (ZFFloatView *)smallFloatView {
    if (!_smallFloatView) {
        _smallFloatView = [[ZFFloatView alloc] init];
        _smallFloatView.parentView = [UIApplication sharedApplication].keyWindow;
        _smallFloatView.hidden = YES;
    }
    return _smallFloatView;
}

#pragma mark - setter

- (void)setCurrentPlayerManager:(id<ZFPlayerMediaPlayback>)currentPlayerManager {
    if (!currentPlayerManager) return;
    if (_currentPlayerManager.isPreparedToPlay) {
        [_currentPlayerManager stop];
        [_currentPlayerManager.view removeFromSuperview];
        [self removeDeviceOrientationObserver];
        [self.gestureControl removeGestureToView:self.currentPlayerManager.view];
    }
    _currentPlayerManager = currentPlayerManager;
    self.gestureControl.disableTypes = self.disableGestureTypes;
    [self.gestureControl addGestureToView:currentPlayerManager.view];
    [self playerManagerCallbcak];
    self.controlView.player = self;
    [self layoutPlayerSubViews];
    if (currentPlayerManager.isPreparedToPlay) {
        [self addDeviceOrientationObserver];
    }
    [self.orientationObserver updateRotateView:currentPlayerManager.view containerView:self.containerView];
}

- (void)setContainerView:(UIView *)containerView {
    _containerView = containerView;
    if (self.scrollView) {
        self.scrollView.zf_containerView = containerView;
    }
    if (!containerView) return;
    containerView.userInteractionEnabled = YES;
    [self layoutPlayerSubViews];
    [self.orientationObserver updateRotateView:self.currentPlayerManager.view containerView:containerView];
}

- (void)setControlView:(UIView<ZFPlayerMediaControl> *)controlView {
    if (controlView && controlView != _controlView) {
        [_controlView removeFromSuperview];
    }
    _controlView = controlView;
    if (!controlView) return;
    controlView.player = self;
    [self layoutPlayerSubViews];
}

- (void)setContainerType:(ZFPlayerContainerType)containerType {
    _containerType = containerType;
    if (self.scrollView) {
        self.scrollView.zf_containerType = containerType;
    }
}

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    self.scrollView.zf_WWANAutoPlay = self.isWWANAutoPlay;
    @zf_weakify(self)
    scrollView.zf_playerWillAppearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerWillAppearInScrollView) self.zf_playerWillAppearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerDidAppearInScrollView:)]) {
            [self.controlView playerDidAppearInScrollView:self];
        }
    };
    
    scrollView.zf_playerDidAppearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerDidAppearInScrollView) self.zf_playerDidAppearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerDidAppearInScrollView:)]) {
            [self.controlView playerDidAppearInScrollView:self];
        }
    };
    
    scrollView.zf_playerWillDisappearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerWillDisappearInScrollView) self.zf_playerWillDisappearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerWillDisappearInScrollView:)]) {
            [self.controlView playerWillDisappearInScrollView:self];
        }
    };
    
    scrollView.zf_playerDidDisappearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerDidDisappearInScrollView) self.zf_playerDidDisappearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerDidDisappearInScrollView:)]) {
            [self.controlView playerDidDisappearInScrollView:self];
        }
       
        if (self.stopWhileNotVisible) { /// stop playing
            if (self.containerType == ZFPlayerContainerTypeView) {
                [self stopCurrentPlayingView];
            } else if (self.containerType == ZFPlayerContainerTypeCell) {
                [self stopCurrentPlayingCell];
            }
        } else { /// add to window
            if (!self.isSmallFloatViewShow) {
                [self addPlayerViewToSmallFloatView];
            }
        }
    };
    
    scrollView.zf_playerAppearingInScrollView = ^(NSIndexPath * _Nonnull indexPath, CGFloat playerAppearPercent) {
        @zf_strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerAppearingInScrollView) self.zf_playerAppearingInScrollView(indexPath, playerAppearPercent);
        if ([self.controlView respondsToSelector:@selector(playerAppearingInScrollView:playerAppearPercent:)]) {
            [self.controlView playerAppearingInScrollView:self playerAppearPercent:playerAppearPercent];
        }
        if (!self.stopWhileNotVisible && playerAppearPercent >= self.playerAppearPercent) {
            if (self.containerType == ZFPlayerContainerTypeView) {
                if (self.isSmallFloatViewShow) {
                    [self addPlayerViewToContainerView:self.containerView];
                }
            } else if (self.containerType == ZFPlayerContainerTypeCell) {
                if (self.isSmallFloatViewShow) {
                    [self addPlayerViewToCell];
                }
            }
        }
    };
    
    scrollView.zf_playerDisappearingInScrollView = ^(NSIndexPath * _Nonnull indexPath, CGFloat playerDisappearPercent) {
        @zf_strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerDisappearingInScrollView) self.zf_playerDisappearingInScrollView(indexPath, playerDisappearPercent);
        if ([self.controlView respondsToSelector:@selector(playerDisappearingInScrollView:playerDisappearPercent:)]) {
            [self.controlView playerDisappearingInScrollView:self playerDisappearPercent:playerDisappearPercent];
        }
        if (playerDisappearPercent >= self.playerDisappearPercent) {
            if (self.stopWhileNotVisible) { /// stop playing
                if (self.containerType == ZFPlayerContainerTypeView) {
                    [self stopCurrentPlayingView];
                } else if (self.containerType == ZFPlayerContainerTypeCell) {
                    [self stopCurrentPlayingCell];
                }
            } else {  /// add to window
                if (!self.isSmallFloatViewShow) {
                    [self addPlayerViewToSmallFloatView];
                }
            }
        }
    };
    
    scrollView.zf_playerShouldPlayInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (self.zf_playerShouldPlayInScrollView) self.zf_playerShouldPlayInScrollView(indexPath);
    };
    
    scrollView.zf_scrollViewDidEndScrollingCallback = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (self.zf_scrollViewDidEndScrollingCallback) self.zf_scrollViewDidEndScrollingCallback(indexPath);
    };
}

@end

@implementation ZFPlayerController (ZFPlayerTimeControl)

- (NSTimeInterval)currentTime {
    return self.currentPlayerManager.currentTime;
}

- (NSTimeInterval)totalTime {
    return self.currentPlayerManager.totalTime;
}

- (NSTimeInterval)bufferTime {
    return self.currentPlayerManager.bufferTime;
}

- (float)progress {
    if (self.totalTime == 0) return 0;
    return self.currentTime/self.totalTime;
}

- (float)bufferProgress {
    if (self.totalTime == 0) return 0;
    return self.bufferTime/self.totalTime;
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler {
    [self.currentPlayerManager seekToTime:time completionHandler:completionHandler];
}

@end

@implementation ZFPlayerController (ZFPlayerPlaybackControl)

- (void)playTheNext {
    if (self.assetURLs.count > 0) {
        NSInteger index = self.currentPlayIndex + 1;
        if (index >= self.assetURLs.count) return;
        NSURL *assetURL = [self.assetURLs objectAtIndex:index];
        self.assetURL = assetURL;
        self.currentPlayIndex = [self.assetURLs indexOfObject:assetURL];
    }
}

- (void)playThePrevious {
    if (self.assetURLs.count > 0) {
        NSInteger index = self.currentPlayIndex - 1;
        if (index < 0) return;
        NSURL *assetURL = [self.assetURLs objectAtIndex:index];
        self.assetURL = assetURL;
        self.currentPlayIndex = [self.assetURLs indexOfObject:assetURL];
    }
}

- (void)playTheIndex:(NSInteger)index {
    if (self.assetURLs.count > 0) {
        if (index >= self.assetURLs.count) return;
        NSURL *assetURL = [self.assetURLs objectAtIndex:index];
        self.assetURL = assetURL;
        self.currentPlayIndex = index;
    }
}

- (void)stop {
    if (self.isFullScreen && self.exitFullScreenWhenStop) {
        @zf_weakify(self)
        [self.orientationObserver enterFullScreen:NO animated:NO completion:^{
            @zf_strongify(self)
            [self.currentPlayerManager stop];
            [self.currentPlayerManager.view removeFromSuperview];
        }];
    } else {
        [self.currentPlayerManager stop];
        [self.currentPlayerManager.view removeFromSuperview];
    }
    self.lockedScreen = NO;
    if (self.scrollView) self.scrollView.zf_stopPlay = YES;
    [self.notification removeNotification];
    [self.orientationObserver removeDeviceOrientationObserver];
}

- (void)replaceCurrentPlayerManager:(id<ZFPlayerMediaPlayback>)playerManager {
    self.currentPlayerManager = playerManager;
}

/// Add video to the cell
- (void)addPlayerViewToCell {
    self.isSmallFloatViewShow = NO;
    self.smallFloatView.hidden = YES;
    UIView *cell = [self.scrollView zf_getCellForIndexPath:self.playingIndexPath];
    self.containerView = [cell viewWithTag:self.containerViewTag];
    [self.containerView addSubview:self.currentPlayerManager.view];
    self.currentPlayerManager.view.frame = self.containerView.bounds;
    self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if ([self.controlView respondsToSelector:@selector(videoPlayer:floatViewShow:)]) {
        [self.controlView videoPlayer:self floatViewShow:NO];
    }
    [self layoutPlayerSubViews];
}

//// Add video to the container view
- (void)addPlayerViewToContainerView:(UIView *)containerView {
    self.isSmallFloatViewShow = NO;
    self.smallFloatView.hidden = YES;
    self.containerView = containerView;
    [self.containerView addSubview:self.currentPlayerManager.view];
    self.currentPlayerManager.view.frame = self.containerView.bounds;
    self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.orientationObserver updateRotateView:self.currentPlayerManager.view containerView:self.containerView];
    if ([self.controlView respondsToSelector:@selector(videoPlayer:floatViewShow:)]) {
        [self.controlView videoPlayer:self floatViewShow:NO];
    }
}

- (void)addPlayerViewToSmallFloatView {
    self.isSmallFloatViewShow = YES;
    self.smallFloatView.hidden = NO;
    [self.smallFloatView addSubview:self.currentPlayerManager.view];
    self.currentPlayerManager.view.frame = self.smallFloatView.bounds;
    self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.orientationObserver updateRotateView:self.currentPlayerManager.view containerView:self.smallFloatView];
    if ([self.controlView respondsToSelector:@selector(videoPlayer:floatViewShow:)]) {
        [self.controlView videoPlayer:self floatViewShow:YES];
    }
}

- (void)stopCurrentPlayingView {
    if (self.containerView) {
        [self stop];
        self.isSmallFloatViewShow = NO;
        if (self.smallFloatView) self.smallFloatView.hidden = YES;
    }
}

- (void)stopCurrentPlayingCell {
    if (self.scrollView.zf_playingIndexPath) {
        [self stop];
        self.isSmallFloatViewShow = NO;
        self.playingIndexPath = nil;
        if (self.smallFloatView) self.smallFloatView.hidden = YES;
    }
}

#pragma mark - getter

- (BOOL)resumePlayRecord {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (NSURL *)assetURL {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSArray<NSURL *> *)assetURLs {
    return objc_getAssociatedObject(self, _cmd);
}

- (BOOL)isLastAssetURL {
    if (self.assetURLs.count > 0) {
        return [self.assetURL isEqual:self.assetURLs.lastObject];
    }
    return NO;
}

- (BOOL)isFirstAssetURL {
    if (self.assetURLs.count > 0) {
        return [self.assetURL isEqual:self.assetURLs.firstObject];
    }
    return NO;
}

- (BOOL)isPauseByEvent {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (float)brightness {
    return [UIScreen mainScreen].brightness;
}

- (float)volume {
    CGFloat volume = self.volumeViewSlider.value;
    if (volume == 0) {
        volume = [[AVAudioSession sharedInstance] outputVolume];
    }
    return volume;
}

- (BOOL)isMuted {
    return self.volume == 0;
}

- (float)lastVolumeValue {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (ZFPlayerPlaybackState)playState {
    return self.currentPlayerManager.playState;
}

- (BOOL)isPlaying {
    return self.currentPlayerManager.isPlaying;
}

- (BOOL)pauseWhenAppResignActive {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.pauseWhenAppResignActive = YES;
    return YES;
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSURL * _Nonnull))playerPrepareToPlay {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSURL * _Nonnull))playerReadyToPlay {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSTimeInterval, NSTimeInterval))playerPlayTimeChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSTimeInterval))playerBufferTimeChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, ZFPlayerPlaybackState))playerPlayStateChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, ZFPlayerLoadState))playerLoadStateChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull))playerDidToEnd {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, id _Nonnull))playerPlayFailed {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, CGSize ))presentationSizeChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSInteger)currentPlayIndex {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (BOOL)isViewControllerDisappear {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)customAudioSession {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

#pragma mark - setter

- (void)setResumePlayRecord:(BOOL)resumePlayRecord {
    objc_setAssociatedObject(self, @selector(resumePlayRecord), @(resumePlayRecord), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setAssetURL:(NSURL *)assetURL {
    objc_setAssociatedObject(self, @selector(assetURL), assetURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.currentPlayerManager.assetURL = assetURL;
}

- (void)setAssetURLs:(NSArray<NSURL *> * _Nullable)assetURLs {
    objc_setAssociatedObject(self, @selector(assetURLs), assetURLs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setVolume:(float)volume {
    volume = MIN(MAX(0, volume), 1);
    objc_setAssociatedObject(self, @selector(volume), @(volume), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.volumeViewSlider.value = volume;
}

- (void)setMuted:(BOOL)muted {
    if (muted) {
        if (self.volumeViewSlider.value > 0) {
            self.lastVolumeValue = self.volumeViewSlider.value;
        }
        self.volumeViewSlider.value = 0;
    } else {
        self.volumeViewSlider.value = self.lastVolumeValue;
    }
}

- (void)setLastVolumeValue:(float)lastVolumeValue {
    objc_setAssociatedObject(self, @selector(lastVolumeValue), @(lastVolumeValue), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setBrightness:(float)brightness {
    brightness = MIN(MAX(0, brightness), 1);
    objc_setAssociatedObject(self, @selector(brightness), @(brightness), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [UIScreen mainScreen].brightness = brightness;
}

- (void)setPauseByEvent:(BOOL)pauseByEvent {
    objc_setAssociatedObject(self, @selector(isPauseByEvent), @(pauseByEvent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (pauseByEvent) {
        [self.currentPlayerManager pause];
    } else {
        [self.currentPlayerManager play];
    }
}

- (void)setPauseWhenAppResignActive:(BOOL)pauseWhenAppResignActive {
    objc_setAssociatedObject(self, @selector(pauseWhenAppResignActive), @(pauseWhenAppResignActive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setPlayerPrepareToPlay:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSURL * _Nonnull))playerPrepareToPlay {
    objc_setAssociatedObject(self, @selector(playerPrepareToPlay), playerPrepareToPlay, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerReadyToPlay:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSURL * _Nonnull))playerReadyToPlay {
    objc_setAssociatedObject(self, @selector(playerReadyToPlay), playerReadyToPlay, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerPlayTimeChanged:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSTimeInterval, NSTimeInterval))playerPlayTimeChanged {
    objc_setAssociatedObject(self, @selector(playerPlayTimeChanged), playerPlayTimeChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerBufferTimeChanged:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSTimeInterval))playerBufferTimeChanged {
    objc_setAssociatedObject(self, @selector(playerBufferTimeChanged), playerBufferTimeChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerPlayStateChanged:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, ZFPlayerPlaybackState))playerPlayStateChanged {
    objc_setAssociatedObject(self, @selector(playerPlayStateChanged), playerPlayStateChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerLoadStateChanged:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, ZFPlayerLoadState))playerLoadStateChanged {
    objc_setAssociatedObject(self, @selector(playerLoadStateChanged), playerLoadStateChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerDidToEnd:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull))playerDidToEnd {
    objc_setAssociatedObject(self, @selector(playerDidToEnd), playerDidToEnd, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerPlayFailed:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, id _Nonnull))playerPlayFailed {
    objc_setAssociatedObject(self, @selector(playerPlayFailed), playerPlayFailed, OBJC_ASSOCIATION_COPY);
}

- (void)setPresentationSizeChanged:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, CGSize))presentationSizeChanged {
    objc_setAssociatedObject(self, @selector(presentationSizeChanged), presentationSizeChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setCurrentPlayIndex:(NSInteger)currentPlayIndex {
    objc_setAssociatedObject(self, @selector(currentPlayIndex), @(currentPlayIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setViewControllerDisappear:(BOOL)viewControllerDisappear {
    objc_setAssociatedObject(self, @selector(isViewControllerDisappear), @(viewControllerDisappear), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.scrollView) self.scrollView.zf_viewControllerDisappear = viewControllerDisappear;
    if (!self.currentPlayerManager.isPreparedToPlay) return;
    if (viewControllerDisappear) {
        [self removeDeviceOrientationObserver];
        if (self.currentPlayerManager.isPlaying) self.pauseByEvent = YES;
        if (self.isSmallFloatViewShow) self.smallFloatView.hidden = YES;
    } else {
        [self addDeviceOrientationObserver];
        if (self.isPauseByEvent) self.pauseByEvent = NO;
        if (self.isSmallFloatViewShow) self.smallFloatView.hidden = NO;
    }
}

- (void)setCustomAudioSession:(BOOL)customAudioSession {
    objc_setAssociatedObject(self, @selector(customAudioSession), @(customAudioSession), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation ZFPlayerController (ZFPlayerOrientationRotation)

- (void)addDeviceOrientationObserver {
    if (self.allowOrientationRotation) {
        [self.orientationObserver addDeviceOrientationObserver];
    }
}

- (void)removeDeviceOrientationObserver {
    [self.orientationObserver removeDeviceOrientationObserver];
}

/// Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModeLandscape.
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated {
    [self rotateToOrientation:orientation animated:animated completion:nil];
}

/// Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModeLandscape.
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void(^ __nullable)(void))completion {
    self.orientationObserver.fullScreenMode = ZFFullScreenModeLandscape;
    [self.orientationObserver rotateToOrientation:orientation animated:animated completion:completion];
}

- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion {
    self.orientationObserver.fullScreenMode = ZFFullScreenModePortrait;
    [self.orientationObserver enterPortraitFullScreen:fullScreen animated:animated completion:completion];
}

- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated {
    [self enterPortraitFullScreen:fullScreen animated:animated completion:nil];
}

- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion {
    if (self.orientationObserver.fullScreenMode == ZFFullScreenModePortrait) {
        [self.orientationObserver enterPortraitFullScreen:fullScreen animated:animated completion:completion];
    } else {
        UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
        orientation = fullScreen? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait;
        [self.orientationObserver rotateToOrientation:orientation animated:animated completion:completion];
    }
}

- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated {
    [self enterFullScreen:fullScreen animated:animated completion:nil];
}

#pragma mark - getter

- (ZFOrientationObserver *)orientationObserver {
    @zf_weakify(self)
    ZFOrientationObserver *orientationObserver = objc_getAssociatedObject(self, _cmd);
    if (!orientationObserver) {
        orientationObserver = [[ZFOrientationObserver alloc] init];
        orientationObserver.orientationWillChange = ^(ZFOrientationObserver * _Nonnull observer, BOOL isFullScreen) {
            @zf_strongify(self)
            if (self.orientationWillChange) self.orientationWillChange(self, isFullScreen);
            if ([self.controlView respondsToSelector:@selector(videoPlayer:orientationWillChange:)]) {
                [self.controlView videoPlayer:self orientationWillChange:observer];
            }
            [self.controlView setNeedsLayout];
            [self.controlView layoutIfNeeded];
        };
        orientationObserver.orientationDidChanged = ^(ZFOrientationObserver * _Nonnull observer, BOOL isFullScreen) {
            @zf_strongify(self)
            if (self.orientationDidChanged) self.orientationDidChanged(self, isFullScreen);
            if ([self.controlView respondsToSelector:@selector(videoPlayer:orientationDidChanged:)]) {
                [self.controlView videoPlayer:self orientationDidChanged:observer];
            }
        };
        objc_setAssociatedObject(self, _cmd, orientationObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return orientationObserver;
}

- (void (^)(ZFPlayerController * _Nonnull, BOOL))orientationWillChange {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(ZFPlayerController * _Nonnull, BOOL))orientationDidChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (BOOL)isFullScreen {
    return self.orientationObserver.isFullScreen;
}

- (BOOL)exitFullScreenWhenStop {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.exitFullScreenWhenStop = YES;
    return YES;
}

- (BOOL)isStatusBarHidden {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)isLockedScreen {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)allowOrientationRotation {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.allowOrientationRotation = YES;
    return YES;
}

- (UIStatusBarStyle)fullScreenStatusBarStyle {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.integerValue;
    self.fullScreenStatusBarStyle = UIStatusBarStyleLightContent;
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)fullScreenStatusBarAnimation {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.integerValue;
    self.fullScreenStatusBarAnimation = UIStatusBarAnimationSlide;
    return UIStatusBarAnimationSlide;
}

#pragma mark - setter

- (void)setOrientationWillChange:(void (^)(ZFPlayerController * _Nonnull, BOOL))orientationWillChange {
    objc_setAssociatedObject(self, @selector(orientationWillChange), orientationWillChange, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setOrientationDidChanged:(void (^)(ZFPlayerController * _Nonnull, BOOL))orientationDidChanged {
    objc_setAssociatedObject(self, @selector(orientationDidChanged), orientationDidChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    objc_setAssociatedObject(self, @selector(isStatusBarHidden), @(statusBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.fullScreenStatusBarHidden = statusBarHidden;
}

- (void)setLockedScreen:(BOOL)lockedScreen {
    objc_setAssociatedObject(self, @selector(isLockedScreen), @(lockedScreen), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.lockedScreen = lockedScreen;
    if ([self.controlView respondsToSelector:@selector(lockedVideoPlayer:lockedScreen:)]) {
        [self.controlView lockedVideoPlayer:self lockedScreen:lockedScreen];
    }
}

- (void)setAllowOrientationRotation:(BOOL)allowOrientationRotation {
    objc_setAssociatedObject(self, @selector(allowOrientationRotation), @(allowOrientationRotation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.allowOrientationRotation = allowOrientationRotation;
}

- (void)setExitFullScreenWhenStop:(BOOL)exitFullScreenWhenStop {
    objc_setAssociatedObject(self, @selector(exitFullScreenWhenStop), @(exitFullScreenWhenStop), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFullScreenStatusBarStyle:(UIStatusBarStyle)fullScreenStatusBarStyle {
    objc_setAssociatedObject(self, @selector(fullScreenStatusBarStyle), @(fullScreenStatusBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.fullScreenStatusBarStyle = fullScreenStatusBarStyle;
}

- (void)setFullScreenStatusBarAnimation:(UIStatusBarAnimation)fullScreenStatusBarAnimation {
    objc_setAssociatedObject(self, @selector(fullScreenStatusBarAnimation), @(fullScreenStatusBarAnimation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.fullScreenStatusBarAnimation = fullScreenStatusBarAnimation;
}

@end


@implementation ZFPlayerController (ZFPlayerViewGesture)

#pragma mark - getter

- (ZFPlayerGestureControl *)gestureControl {
    ZFPlayerGestureControl *gestureControl = objc_getAssociatedObject(self, _cmd);
    if (!gestureControl) {
        gestureControl = [[ZFPlayerGestureControl alloc] init];
        @zf_weakify(self)
        gestureControl.triggerCondition = ^BOOL(ZFPlayerGestureControl * _Nonnull control, ZFPlayerGestureType type, UIGestureRecognizer * _Nonnull gesture, UITouch *touch) {
            @zf_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureTriggerCondition:gestureType:gestureRecognizer:touch:)]) {
                return [self.controlView gestureTriggerCondition:control gestureType:type gestureRecognizer:gesture touch:touch];
            }
            return YES;
        };
        
        gestureControl.singleTapped = ^(ZFPlayerGestureControl * _Nonnull control) {
            @zf_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureSingleTapped:)]) {
                [self.controlView gestureSingleTapped:control];
            }
        };
        
        gestureControl.doubleTapped = ^(ZFPlayerGestureControl * _Nonnull control) {
            @zf_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureDoubleTapped:)]) {
                [self.controlView gestureDoubleTapped:control];
            }
        };
        
        gestureControl.beganPan = ^(ZFPlayerGestureControl * _Nonnull control, ZFPanDirection direction, ZFPanLocation location) {
            @zf_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureBeganPan:panDirection:panLocation:)]) {
                [self.controlView gestureBeganPan:control panDirection:direction panLocation:location];
            }
        };
        
        gestureControl.changedPan = ^(ZFPlayerGestureControl * _Nonnull control, ZFPanDirection direction, ZFPanLocation location, CGPoint velocity) {
            @zf_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureChangedPan:panDirection:panLocation:withVelocity:)]) {
                [self.controlView gestureChangedPan:control panDirection:direction panLocation:location withVelocity:velocity];
            }
        };
        
        gestureControl.endedPan = ^(ZFPlayerGestureControl * _Nonnull control, ZFPanDirection direction, ZFPanLocation location) {
            @zf_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureEndedPan:panDirection:panLocation:)]) {
                [self.controlView gestureEndedPan:control panDirection:direction panLocation:location];
            }
        };
        
        gestureControl.pinched = ^(ZFPlayerGestureControl * _Nonnull control, float scale) {
            @zf_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gesturePinched:scale:)]) {
                [self.controlView gesturePinched:control scale:scale];
            }
        };
        
        gestureControl.longPressed = ^(ZFPlayerGestureControl * _Nonnull control, ZFLongPressGestureRecognizerState state) {
            @zf_strongify(self)
            if ([self.controlView respondsToSelector:@selector(longPressed:state:)]) {
                [self.controlView longPressed:control state:state];
            }
        };
        objc_setAssociatedObject(self, _cmd, gestureControl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return gestureControl;
}

- (ZFPlayerDisableGestureTypes)disableGestureTypes {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (ZFPlayerDisablePanMovingDirection)disablePanMovingDirection {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

#pragma mark - setter

- (void)setDisableGestureTypes:(ZFPlayerDisableGestureTypes)disableGestureTypes {
    objc_setAssociatedObject(self, @selector(disableGestureTypes), @(disableGestureTypes), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.gestureControl.disableTypes = disableGestureTypes;
}

- (void)setDisablePanMovingDirection:(ZFPlayerDisablePanMovingDirection)disablePanMovingDirection {
    objc_setAssociatedObject(self, @selector(disablePanMovingDirection), @(disablePanMovingDirection), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.gestureControl.disablePanMovingDirection = disablePanMovingDirection;
}

@end

@implementation ZFPlayerController (ZFPlayerScrollView)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            NSSelectorFromString(@"dealloc")
        };
        
        for (NSInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
            SEL originalSelector = selectors[index];
            SEL swizzledSelector = NSSelectorFromString([@"zf_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
            Method originalMethod = class_getInstanceMethod(self, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
            if (class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    });
}

- (void)zf_dealloc {
    [self.smallFloatView removeFromSuperview];
    self.smallFloatView = nil;
    [self zf_dealloc];
}

#pragma mark - setter

- (void)setWWANAutoPlay:(BOOL)WWANAutoPlay {
    objc_setAssociatedObject(self, @selector(isWWANAutoPlay), @(WWANAutoPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.scrollView) self.scrollView.zf_WWANAutoPlay = self.isWWANAutoPlay;
}

- (void)setStopWhileNotVisible:(BOOL)stopWhileNotVisible {
    self.scrollView.zf_stopWhileNotVisible = stopWhileNotVisible;
    objc_setAssociatedObject(self, @selector(stopWhileNotVisible), @(stopWhileNotVisible), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setContainerViewTag:(NSInteger)containerViewTag {
    objc_setAssociatedObject(self, @selector(containerViewTag), @(containerViewTag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.scrollView.zf_containerViewTag = containerViewTag;
}

- (void)setPlayingIndexPath:(NSIndexPath *)playingIndexPath {
    objc_setAssociatedObject(self, @selector(playingIndexPath), playingIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (playingIndexPath) {
        self.isSmallFloatViewShow = NO;
        if (self.smallFloatView) self.smallFloatView.hidden = YES;
        
        UIView *cell = [self.scrollView zf_getCellForIndexPath:playingIndexPath];
        self.containerView = [cell viewWithTag:self.containerViewTag];
        [self addDeviceOrientationObserver];
        self.scrollView.zf_playingIndexPath = playingIndexPath;
        [self layoutPlayerSubViews];
    } else {
        self.scrollView.zf_playingIndexPath = playingIndexPath;
    }
}

- (void)setShouldAutoPlay:(BOOL)shouldAutoPlay {
    objc_setAssociatedObject(self, @selector(shouldAutoPlay), @(shouldAutoPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.scrollView.zf_shouldAutoPlay = shouldAutoPlay;
}

- (void)setSectionAssetURLs:(NSArray<NSArray<NSURL *> *> * _Nullable)sectionAssetURLs {
    objc_setAssociatedObject(self, @selector(sectionAssetURLs), sectionAssetURLs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setPlayerDisappearPercent:(CGFloat)playerDisappearPercent {
    playerDisappearPercent = MIN(MAX(0.0, playerDisappearPercent), 1.0);
    self.scrollView.zf_playerDisappearPercent = playerDisappearPercent;
    objc_setAssociatedObject(self, @selector(playerDisappearPercent), @(playerDisappearPercent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setPlayerAppearPercent:(CGFloat)playerAppearPercent {
    playerAppearPercent = MIN(MAX(0.0, playerAppearPercent), 1.0);
    self.scrollView.zf_playerAppearPercent = playerAppearPercent;
    objc_setAssociatedObject(self, @selector(playerAppearPercent), @(playerAppearPercent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_playerAppearingInScrollView:(void (^)(NSIndexPath * _Nonnull, CGFloat))zf_playerAppearingInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerAppearingInScrollView), zf_playerAppearingInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerDisappearingInScrollView:(void (^)(NSIndexPath * _Nonnull, CGFloat))zf_playerDisappearingInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerDisappearingInScrollView), zf_playerDisappearingInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerDidAppearInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerDidAppearInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerDidAppearInScrollView), zf_playerDidAppearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerWillDisappearInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerWillDisappearInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerWillDisappearInScrollView), zf_playerWillDisappearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerWillAppearInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerWillAppearInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerWillAppearInScrollView), zf_playerWillAppearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerDidDisappearInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerDidDisappearInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerDidDisappearInScrollView), zf_playerDidDisappearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerShouldPlayInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerShouldPlayInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerShouldPlayInScrollView), zf_playerShouldPlayInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_scrollViewDidEndScrollingCallback:(void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidEndScrollingCallback {
    objc_setAssociatedObject(self, @selector(zf_scrollViewDidEndScrollingCallback), zf_scrollViewDidEndScrollingCallback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - getter

- (BOOL)isWWANAutoPlay {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)stopWhileNotVisible {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.stopWhileNotVisible = YES;
    return YES;
}

- (NSInteger)containerViewTag {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (NSIndexPath *)playingIndexPath {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSIndexPath *)shouldPlayIndexPath {
    return self.scrollView.zf_shouldPlayIndexPath;
}

- (NSArray<NSArray<NSURL *> *> *)sectionAssetURLs {
    return objc_getAssociatedObject(self, _cmd);
}

- (BOOL)shouldAutoPlay {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (CGFloat)playerDisappearPercent {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.floatValue;
    self.playerDisappearPercent = 0.5;
    return 0.5;
}

- (CGFloat)playerAppearPercent {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.floatValue;
    self.playerAppearPercent = 0.0;
    return 0.0;
}

- (void (^)(NSIndexPath * _Nonnull, CGFloat))zf_playerAppearingInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull, CGFloat))zf_playerDisappearingInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerDidAppearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerWillDisappearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerWillAppearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerDidDisappearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerShouldPlayInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidEndScrollingCallback {
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - Public method

- (void)zf_filterShouldPlayCellWhileScrolled:(void (^ __nullable)(NSIndexPath *indexPath))handler {
    [self.scrollView zf_filterShouldPlayCellWhileScrolled:handler];
}

- (void)zf_filterShouldPlayCellWhileScrolling:(void (^ __nullable)(NSIndexPath *indexPath))handler {
    [self.scrollView zf_filterShouldPlayCellWhileScrolling:handler];
}

- (void)playTheIndexPath:(NSIndexPath *)indexPath {
    self.playingIndexPath = indexPath;
    NSURL *assetURL;
    if (self.sectionAssetURLs.count) {
        assetURL = self.sectionAssetURLs[indexPath.section][indexPath.row];
    } else if (self.assetURLs.count) {
        assetURL = self.assetURLs[indexPath.row];
        self.currentPlayIndex = indexPath.row;
    }
    self.assetURL = assetURL;
}


- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition animated:(BOOL)animated {
    [self playTheIndexPath:indexPath scrollPosition:scrollPosition animated:animated completionHandler:nil];
}

- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition animated:(BOOL)animated completionHandler:(void (^ __nullable)(void))completionHandler {
    NSURL *assetURL;
    if (self.sectionAssetURLs.count) {
        assetURL = self.sectionAssetURLs[indexPath.section][indexPath.row];
    } else if (self.assetURLs.count) {
        assetURL = self.assetURLs[indexPath.row];
        self.currentPlayIndex = indexPath.row;
    }
    @zf_weakify(self)
    [self.scrollView zf_scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated completionHandler:^{
        @zf_strongify(self)
        if (completionHandler) completionHandler();
        self.playingIndexPath = indexPath;
        self.assetURL = assetURL;
    }];
}


- (void)playTheIndexPath:(NSIndexPath *)indexPath assetURL:(NSURL *)assetURL {
    self.playingIndexPath = indexPath;
    self.assetURL = assetURL;
}


- (void)playTheIndexPath:(NSIndexPath *)indexPath
                assetURL:(NSURL *)assetURL
          scrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated {
    [self playTheIndexPath:indexPath assetURL:assetURL scrollPosition:scrollPosition animated:animated completionHandler:nil];
}


- (void)playTheIndexPath:(NSIndexPath *)indexPath
                assetURL:(NSURL *)assetURL
          scrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated
       completionHandler:(void (^ __nullable)(void))completionHandler {
    @zf_weakify(self)
    [self.scrollView zf_scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated completionHandler:^{
        @zf_strongify(self)
        if (completionHandler) completionHandler();
        self.playingIndexPath = indexPath;
        self.assetURL = assetURL;
    }];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation ZFPlayerController (ZFPlayerDeprecated)

- (void)updateScrollViewPlayerToCell {
    if (self.currentPlayerManager.view && self.playingIndexPath && self.containerViewTag) {
        UIView *cell = [self.scrollView zf_getCellForIndexPath:self.playingIndexPath];
        self.containerView = [cell viewWithTag:self.containerViewTag];
        [self layoutPlayerSubViews];
    }
}

- (void)updateNormalPlayerWithContainerView:(UIView *)containerView {
    if (self.currentPlayerManager.view && self.containerView) {
        self.containerView = containerView;
        [self.orientationObserver updateRotateView:self.currentPlayerManager.view containerView:self.containerView];
        [self layoutPlayerSubViews];
    }
}

- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop completionHandler:(void (^ _Nullable)(void))completionHandler {
    NSURL *assetURL;
    if (self.sectionAssetURLs.count) {
        assetURL = self.sectionAssetURLs[indexPath.section][indexPath.row];
    } else if (self.assetURLs.count) {
        assetURL = self.assetURLs[indexPath.row];
        self.currentPlayIndex = indexPath.row;
    }
    if (scrollToTop) {
        @zf_weakify(self)
        [self.scrollView zf_scrollToRowAtIndexPath:indexPath completionHandler:^{
            @zf_strongify(self)
            if (completionHandler) completionHandler();
            self.playingIndexPath = indexPath;
            self.assetURL = assetURL;
        }];
    } else {
        if (completionHandler) completionHandler();
        self.playingIndexPath = indexPath;
        self.assetURL = assetURL;
    }
}

- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop {
    if ([indexPath compare:self.playingIndexPath] == NSOrderedSame) return;
    if (scrollToTop) {
        @zf_weakify(self)
        [self.scrollView zf_scrollToRowAtIndexPath:indexPath completionHandler:^{
            @zf_strongify(self)
            [self playTheIndexPath:indexPath];
        }];
    } else {
        [self playTheIndexPath:indexPath];
    }
}

- (void)playTheIndexPath:(NSIndexPath *)indexPath assetURL:(NSURL *)assetURL scrollToTop:(BOOL)scrollToTop {
    self.playingIndexPath = indexPath;
    self.assetURL = assetURL;
    if (scrollToTop) {
        [self.scrollView zf_scrollToRowAtIndexPath:indexPath completionHandler:nil];
    }
}

- (void)enterLandscapeFullScreen:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion {
    self.orientationObserver.fullScreenMode = ZFFullScreenModeLandscape;
    [self.orientationObserver rotateToOrientation:orientation animated:animated completion:completion];
}

- (void)enterLandscapeFullScreen:(UIInterfaceOrientation)orientation animated:(BOOL)animated {
    [self enterLandscapeFullScreen:orientation animated:animated completion:nil];
}

/// Add to the keyWindow
- (void)addPlayerViewToKeyWindow {
    [self addPlayerViewToSmallFloatView];
}

@end

#pragma clang diagnostic pop
