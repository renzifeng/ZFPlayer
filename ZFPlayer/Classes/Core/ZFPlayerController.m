//
//  ZFPlayer.m
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
#import "ZFPlayerNotification.h"
#import "UIScrollView+ZFPlayer.h"
#import "ZFReachabilityManager.h"
#import "ZFPlayer.h"

@interface ZFPlayerController ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) ZFPlayerNotification *notification;
@property (nonatomic, strong) id<ZFPlayerMediaPlayback> currentPlayerManager;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) UISlider *volumeViewSlider;
@property (nonatomic, assign) NSInteger containerViewTag;

@end

@implementation ZFPlayerController

- (instancetype)init {
    self = [super init];
    if (self) {
        @weakify(self)
        [[ZFReachabilityManager sharedManager] startMonitoring];
        [[ZFReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(ZFReachabilityStatus status) {
            @strongify(self)
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
    // Apps using this category don't mute when the phone's mute button is turned on, but play sound when the phone is silent
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
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

- (instancetype)initWithPlayerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(nonnull UIView *)containerView {
    ZFPlayerController *player = [self init];
    player.currentPlayerManager = playerManager;
    player.containerView = containerView;
    return player;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag {
    ZFPlayerController *player = [self init];
    player.scrollView = scrollView;
    player.currentPlayerManager = playerManager;
    player.containerViewTag = containerViewTag;
    return player;
}

- (void)playerManagerCallbcak {
    @weakify(self)
    self.currentPlayerManager.playerPrepareToPlay = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, id<ZFPlayerSource> _Nonnull playerSource) {
        @strongify(self)
        [self layoutPlayerSubViews];
        self.currentPlayerManager.view.hidden = NO;
        [self.notification addNotification];
        [self addDeviceOrientationObserver];
        if (self.playerPrepareToPlay) self.playerPrepareToPlay(asset,playerSource);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:prepareToPlay:)]) {
            [self.controlView videoPlayer:self prepareToPlay:playerSource];
        }
    };
    
    self.currentPlayerManager.playerPlayTimeChanged = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSTimeInterval currentTime, NSTimeInterval duration) {
        @strongify(self)
        if (self.playerPlayTimeChanged) self.playerPlayTimeChanged(asset,currentTime,duration);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:currentTime:totalTime:)]) {
            [self.controlView videoPlayer:self currentTime:currentTime totalTime:duration];
        }
    };
    
    self.currentPlayerManager.playerBufferTimeChanged = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSTimeInterval bufferTime) {
        @strongify(self)
        if ([self.controlView respondsToSelector:@selector(videoPlayer:bufferTime:)]) {
            [self.controlView videoPlayer:self bufferTime:bufferTime];
        }
        if (self.playerBufferTimeChanged) self.playerBufferTimeChanged(asset,bufferTime);
    };
    
    self.currentPlayerManager.playerPlayStatChanged = ^(id  _Nonnull asset, ZFPlayerPlaybackState playState) {
        @strongify(self)
        if (self.playerPlayStatChanged) self.playerPlayStatChanged(asset, playState);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:playStateChanged:)]) {
            [self.controlView videoPlayer:self playStateChanged:playState];
        }
    };
    
    self.currentPlayerManager.playerLoadStatChanged = ^(id  _Nonnull asset, ZFPlayerLoadState loadState) {
        @strongify(self)
        if (self.playerLoadStatChanged) self.playerLoadStatChanged(asset, loadState);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:loadStateChanged:)]) {
            [self.controlView videoPlayer:self loadStateChanged:loadState];
        }
    };
    
    self.currentPlayerManager.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        if (self.playerDidToEnd) self.playerDidToEnd(asset);
        if ([self.controlView respondsToSelector:@selector(videoPlayerPlayEnd:)]) {
            [self.controlView videoPlayerPlayEnd:self];
        }
    };
    
    self.currentPlayerManager.playerPlayFailed = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, id  _Nonnull error) {
        @strongify(self)
        if (self.playerPlayFailed) self.playerPlayFailed(asset, error);
        if ([self.controlView respondsToSelector:@selector(videoPlayerPlayFailed:error:)]) {
            [self.controlView videoPlayerPlayFailed:self error:error];
        }
    };
}

- (void)layoutPlayerSubViews {
    if (self.containerView && self.currentPlayerManager.view) {
        UIView *superview = nil;
        if (self.isFullScreen) {
            superview = self.orientationObserver.fullScreenContainerView;
        } else {
            superview = self.containerView;
        }
        [superview addSubview:self.currentPlayerManager.view];
        [self.currentPlayerManager.view addSubview:self.controlView];
        
        self.currentPlayerManager.view.frame = superview.bounds;
        self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.controlView.frame = self.currentPlayerManager.view.bounds;
        self.controlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

#pragma mark - getter

- (ZFPlayerNotification *)notification {
    if (!_notification) {
        _notification = [[ZFPlayerNotification alloc] init];
        @weakify(self)
        _notification.willResignActive = ^(ZFPlayerNotification * _Nonnull registrar) {
            @strongify(self)
            if (self.isViewControllerDisappear) return;
            if (self.pauseWhenAppResignActive && self.currentPlayerManager.isPlaying) {
                self.pauseByEvent = YES;
            }
            if (self.isFullScreen && !self.isLockedScreen) self.orientationObserver.lockedScreen = YES;
            [[UIApplication sharedApplication].keyWindow endEditing:YES];
        };
        _notification.didBecomeActive = ^(ZFPlayerNotification * _Nonnull registrar) {
            @strongify(self)
            if (self.isViewControllerDisappear) return;
            if (self.isPauseByEvent) self.pauseByEvent = NO;
            if (self.isFullScreen && !self.isLockedScreen) self.orientationObserver.lockedScreen = NO;
        };
        _notification.oldDeviceUnavailable = ^(ZFPlayerNotification * _Nonnull registrar) {
            @strongify(self)
            if (self.currentPlayerManager.isPlaying) {
                [self.currentPlayerManager play];
            }
        };
    }
    return _notification;
}

#pragma mark - setter

- (void)setCurrentPlayerManager:(id<ZFPlayerMediaPlayback>)currentPlayerManager {
    if (!currentPlayerManager) return;
    _currentPlayerManager = currentPlayerManager;
    _currentPlayerManager.view.hidden = YES;
    self.gestureControl.disableTypes = self.disableGestureTypes;
    [self.gestureControl addGestureToView:currentPlayerManager.view];
    [self playerManagerCallbcak];
}

- (void)setContainerView:(UIView *)containerView {
    if (!containerView) return;
    _containerView = containerView;
    containerView.userInteractionEnabled = YES;
}

- (void)setControlView:(UIView<ZFPlayerMediaControl> *)controlView {
    if (!controlView) return;
    _controlView = controlView;
    controlView.player = self;
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

- (void)stop {
    [self.notification removeNotification];
    [self.orientationObserver removeDeviceOrientationObserver];
    if (self.isFullScreen) {
        [self.orientationObserver exitFullScreenWithAnimated:NO];
    }
    [self.currentPlayerManager stop];
    [self.currentPlayerManager.view removeFromSuperview];
    self.currentPlayerManager.view.hidden = YES;
}

- (void)replaceCurrentPlayerManager:(id<ZFPlayerMediaPlayback>)manager {
    if (self.currentPlayerManager.isPreparedToPlay) {
        [self.notification removeNotification];
        [self.orientationObserver removeDeviceOrientationObserver];
        [self stop];
    }
    [self.gestureControl removeGestureToView:self.currentPlayerManager.view];
    self.currentPlayerManager = manager;
    [self layoutPlayerSubViews];
}

- (void)playTheNext {
    if (self.playerSources.count > 0) {
        NSInteger index = self.currentPlayIndex + 1;
        if (index >= self.playerSources.count) return;
        id<ZFPlayerSource> playerSource = [self.playerSources objectAtIndex:index];
        self.playerSource = playerSource;
        self.currentPlayIndex = [self.playerSources indexOfObject:playerSource];
    }
}

- (void)playThePrevious {
    if (self.playerSources.count > 0) {
        NSInteger index = self.currentPlayIndex - 1;
        if (index < 0) return;
        id<ZFPlayerSource>playerSource = [self.playerSources objectAtIndex:index];
        self.playerSource = playerSource;
        self.currentPlayIndex = [self.playerSources indexOfObject:playerSource];
    }
}

- (void)playTheIndex:(NSInteger)index {
    if (self.playerSources.count > 0) {
        if (index >= self.playerSources.count) return;
        id<ZFPlayerSource>playerSource = [self.playerSources objectAtIndex:index];
        self.playerSource = playerSource;
        self.currentPlayIndex = index;
    }
}

#pragma mark - getter

- (id<ZFPlayerSource>)playerSource {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSArray<id<ZFPlayerSource>> *)playerSources {
    return objc_getAssociatedObject(self, _cmd);
}

- (BOOL)isLastPlayerSource {
    if (self.playerSources.count > 0) {
        return self.playerSource == self.playerSources.lastObject;
    }
    return NO;
}

- (BOOL)isFirstPlayerSource {
    if (self.playerSources.count > 0) {
        return self.playerSource == self.playerSources.firstObject;
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

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, id<ZFPlayerSource> _Nonnull))playerPrepareToPlay {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSTimeInterval, NSTimeInterval))playerPlayTimeChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSTimeInterval))playerBufferTimeChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, ZFPlayerPlaybackState))playerPlayStatChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, ZFPlayerLoadState))playerLoadStatChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull))playerDidToEnd {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<ZFPlayerMediaPlayback> _Nonnull, id _Nonnull))playerPlayFailed {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSInteger)currentPlayIndex {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (BOOL)isViewControllerDisappear {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

#pragma mark - setter

- (void)setPlayerSource:(id<ZFPlayerSource>)playerSource {
    objc_setAssociatedObject(self, @selector(playerSource), playerSource, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.currentPlayerManager.playerSource = playerSource;
}

- (void)setPlayerSources:(NSArray<id<ZFPlayerSource>> * _Nullable)playerSources {
    objc_setAssociatedObject(self, @selector(playerSources), playerSources, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setVolume:(float)volume {
    volume = MIN(MAX(0, volume), 1);
    objc_setAssociatedObject(self, @selector(volume), @(volume), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.volumeViewSlider.value = volume;
}

- (void)setMuted:(BOOL)muted {
    if (muted) {
        self.lastVolumeValue = self.volumeViewSlider.value;
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

- (void)setPlayerPrepareToPlay:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, id<ZFPlayerSource> _Nonnull))playerPrepareToPlay {
    objc_setAssociatedObject(self, @selector(playerPrepareToPlay), playerPrepareToPlay, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerPlayTimeChanged:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSTimeInterval, NSTimeInterval))playerPlayTimeChanged {
    objc_setAssociatedObject(self, @selector(playerPlayTimeChanged), playerPlayTimeChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerBufferTimeChanged:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, NSTimeInterval))playerBufferTimeChanged {
    objc_setAssociatedObject(self, @selector(playerBufferTimeChanged), playerBufferTimeChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerPlayStatChanged:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, ZFPlayerPlaybackState))playerPlayStatChanged {
    objc_setAssociatedObject(self, @selector(playerPlayStatChanged), playerPlayStatChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerLoadStatChanged:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, ZFPlayerLoadState))playerLoadStatChanged {
    objc_setAssociatedObject(self, @selector(playerLoadStatChanged), playerLoadStatChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerDidToEnd:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull))playerDidToEnd {
    objc_setAssociatedObject(self, @selector(playerDidToEnd), playerDidToEnd, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerPlayFailed:(void (^)(id<ZFPlayerMediaPlayback> _Nonnull, id _Nonnull))playerPlayFailed {
    objc_setAssociatedObject(self, @selector(playerPlayFailed), playerPlayFailed, OBJC_ASSOCIATION_COPY);
}

- (void)setCurrentPlayIndex:(NSInteger)currentPlayIndex {
    objc_setAssociatedObject(self, @selector(currentPlayIndex), @(currentPlayIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setViewControllerDisappear:(BOOL)viewControllerDisappear {
    objc_setAssociatedObject(self, @selector(isViewControllerDisappear), @(viewControllerDisappear), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!self.currentPlayerManager.isPreparedToPlay) return;
    if (viewControllerDisappear) {
        [self removeDeviceOrientationObserver];
        if (self.currentPlayerManager.isPlaying) self.pauseByEvent = YES;
    } else {
        if (self.isPauseByEvent) self.pauseByEvent = NO;
        [self addDeviceOrientationObserver];
    }
}

@end

@implementation ZFPlayerController (ZFPlayerOrientationRotation)

- (void)addDeviceOrientationObserver {
    [self.orientationObserver addDeviceOrientationObserver];
}

- (void)removeDeviceOrientationObserver {
    [self.orientationObserver removeDeviceOrientationObserver];
}

- (void)enterLandscapeFullScreen:(UIInterfaceOrientation)orientation animated:(BOOL)animated {
    self.orientationObserver.fullScreenMode = ZFFullScreenModeLandscape;
    [self.orientationObserver enterLandscapeFullScreen:orientation animated:animated];
}

- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated {
    self.orientationObserver.fullScreenMode = ZFFullScreenModePortrait;
    [self.orientationObserver enterPortraitFullScreen:fullScreen animated:YES];
}

- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated {
    if (self.orientationObserver.fullScreenMode == ZFFullScreenModePortrait) {
        [self.orientationObserver enterPortraitFullScreen:fullScreen animated:YES];
    } else {
        UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
        orientation = fullScreen? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait;
        [self.orientationObserver enterLandscapeFullScreen:orientation animated:animated];
    }
}

- (BOOL)isNeedAdaptiveiOS8Rotation {
    NSArray<NSString *> *versionStrArr = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    int firstVer = [[versionStrArr objectAtIndex:0] intValue];
    int secondVer = [[versionStrArr objectAtIndex:1] intValue];
    if (firstVer == 8) {
        if (secondVer >= 1 && secondVer <= 3) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - getter

- (ZFOrientationObserver *)orientationObserver {
    if (!self.currentPlayerManager.view && !self.containerView) return nil;
    @weakify(self)
    ZFOrientationObserver *orientationObserver = objc_getAssociatedObject(self, _cmd);
    if (!orientationObserver) {
        orientationObserver = [[ZFOrientationObserver alloc] initWithRotateView:self.currentPlayerManager.view containerView:self.containerView];
        orientationObserver.orientationWillChange = ^(ZFOrientationObserver * _Nonnull observer, BOOL isFullScreen) {
            @strongify(self)
            if (self.orientationWillChange) self.orientationWillChange(self, isFullScreen);
            if ([self.controlView respondsToSelector:@selector(videoPlayer:orientationWillChange:)]) {
                [self.controlView videoPlayer:self orientationWillChange:observer];
            }
            [self.controlView setNeedsLayout];
            [self.controlView layoutIfNeeded];
        };
        orientationObserver.orientationDidChanged = ^(ZFOrientationObserver * _Nonnull observer, BOOL isFullScreen) {
            @strongify(self)
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

- (UIInterfaceOrientation)currentOrientation {
    return self.orientationObserver.currentOrientation;
}

- (BOOL)isStatusBarHidden {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)isLockedScreen {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)shouldAutorotate {
    return [self isNeedAdaptiveiOS8Rotation];
}

- (BOOL)allowOrentitaionRotation {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.allowOrentitaionRotation = YES;
    return YES;
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
    self.orientationObserver.statusBarHidden = statusBarHidden;
}

- (void)setLockedScreen:(BOOL)lockedScreen {
    objc_setAssociatedObject(self, @selector(isLockedScreen), @(lockedScreen), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.lockedScreen = lockedScreen;
    if ([self.controlView respondsToSelector:@selector(lockedVideoPlayer:lockedScreen:)]) {
        [self.controlView lockedVideoPlayer:self lockedScreen:lockedScreen];
    }
}

- (void)setAllowOrentitaionRotation:(BOOL)allowOrentitaionRotation {
    objc_setAssociatedObject(self, @selector(allowOrentitaionRotation), @(allowOrentitaionRotation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.allowOrentitaionRotation = allowOrentitaionRotation;
}

@end


@implementation ZFPlayerController (ZFPlayerViewGesture)

#pragma mark - getter

- (ZFPlayerGestureControl *)gestureControl {
    ZFPlayerGestureControl *gestureControl = objc_getAssociatedObject(self, _cmd);
    if (!gestureControl) {
        gestureControl = [[ZFPlayerGestureControl alloc] init];
        @weakify(self)
        gestureControl.triggerCondition = ^BOOL(ZFPlayerGestureControl * _Nonnull control, ZFPlayerGestureType type, UIGestureRecognizer * _Nonnull gesture, UITouch *touch) {
            @strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureTriggerCondition:gestureType:gestureRecognizer:touch:)]) {
                return [self.controlView gestureTriggerCondition:control gestureType:type gestureRecognizer:gesture touch:touch];
            }
            return YES;
        };
        
        gestureControl.singleTapped = ^(ZFPlayerGestureControl * _Nonnull control) {
            @strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureSingleTapped:)]) {
                [self.controlView gestureSingleTapped:control];
            }
        };
        
        gestureControl.doubleTapped = ^(ZFPlayerGestureControl * _Nonnull control) {
            @strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureDoubleTapped:)]) {
                [self.controlView gestureDoubleTapped:control];
            }
        };
        
        gestureControl.beganPan = ^(ZFPlayerGestureControl * _Nonnull control, ZFPanDirection direction, ZFPanLocation location) {
            @strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureBeganPan:panDirection:panLocation:)]) {
                [self.controlView gestureBeganPan:control panDirection:direction panLocation:location];
            }
        };
        
        gestureControl.changedPan = ^(ZFPlayerGestureControl * _Nonnull control, ZFPanDirection direction, ZFPanLocation location, CGPoint velocity) {
            @strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureChangedPan:panDirection:panLocation:withVelocity:)]) {
                [self.controlView gestureChangedPan:control panDirection:direction panLocation:location withVelocity:velocity];
            }
        };
        
        gestureControl.endedPan = ^(ZFPlayerGestureControl * _Nonnull control, ZFPanDirection direction, ZFPanLocation location) {
            @strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureEndedPan:panDirection:panLocation:)]) {
                [self.controlView gestureEndedPan:control panDirection:direction panLocation:location];
            }
        };
        
        gestureControl.pinched = ^(ZFPlayerGestureControl * _Nonnull control, float scale) {
            @strongify(self)
            if ([self.controlView respondsToSelector:@selector(gesturePinched:scale:)]) {
                [self.controlView gesturePinched:control scale:scale];
            }
        };
        objc_setAssociatedObject(self, _cmd, gestureControl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return gestureControl;
}

- (ZFPlayerDisableGestureTypes)disableGestureTypes {
    return [objc_getAssociatedObject(self, _cmd) unsignedIntegerValue];
}

#pragma mark - setter

- (void)setDisableGestureTypes:(ZFPlayerDisableGestureTypes)disableGestureTypes {
    objc_setAssociatedObject(self, @selector(disableGestureTypes), @(disableGestureTypes), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.gestureControl.disableTypes = disableGestureTypes;
}

@end

@implementation ZFPlayerController (ZFPlayerScrollView)

+ (void)load {
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

//// Add video to the cell
- (void)addPlayerViewToCell {
    self.isSmallFloatViewShow = NO;
    self.smallFloatView.hidden = YES;
    UIView *cell = [self.scrollView zf_getCellForIndexPath:self.playingIndexPath];
    self.containerView = [cell viewWithTag:self.containerViewTag];
    [self.containerView addSubview:self.currentPlayerManager.view];
    self.currentPlayerManager.view.frame = self.containerView.bounds;
    self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.orientationObserver cellModelRotateView:self.currentPlayerManager.view rotateViewAtCell:cell playerViewTag:self.containerViewTag];
}

/// Add to the keyWindow
- (void)addPlayerViewToKeyWindow {
    self.isSmallFloatViewShow = YES;
    self.smallFloatView.hidden = NO;
    [self.smallFloatView addSubview:self.currentPlayerManager.view];
    self.currentPlayerManager.view.frame = self.smallFloatView.bounds;
    self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.orientationObserver cellSmallModelRotateView:self.currentPlayerManager.view containerView:self.smallFloatView];
}

#pragma mark - setter

- (void)setScrollView:(UIScrollView *)scrollView {
    objc_setAssociatedObject(self, @selector(scrollView), scrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.scrollView.zf_WWANAutoPlay = self.isWWANAutoPlay;
    @weakify(self)
    scrollView.zf_enableScrollHook = YES;
    
    scrollView.zf_playerWillAppearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerWillAppearInScrollView) self.zf_playerWillAppearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerDidAppearInScrollView:)]) {
            [self.controlView playerDidAppearInScrollView:self];
        }
    };
    
    scrollView.zf_playerDidAppearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerDidAppearInScrollView) self.zf_playerDidAppearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerDidAppearInScrollView:)]) {
            [self.controlView playerDidAppearInScrollView:self];
        }
    };
    
    scrollView.zf_playerWillDisappearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerWillDisappearInScrollView) self.zf_playerWillDisappearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerWillDisappearInScrollView:)]) {
            [self.controlView playerWillDisappearInScrollView:self];
        }
    };
    
    scrollView.zf_playerDidDisappearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerDidDisappearInScrollView) self.zf_playerDidDisappearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerDidDisappearInScrollView:)]) {
            [self.controlView playerDidDisappearInScrollView:self];
        }
    };
    
    scrollView.zf_playerAppearingInScrollView = ^(NSIndexPath * _Nonnull indexPath, CGFloat playerApperaPercent) {
        @strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerAppearingInScrollView) self.zf_playerAppearingInScrollView(indexPath, playerApperaPercent);
        if ([self.controlView respondsToSelector:@selector(playerAppearingInScrollView:playerApperaPercent:)]) {
            [self.controlView playerAppearingInScrollView:self playerApperaPercent:playerApperaPercent];
        }
        if (!self.stopWhileNotVisible && playerApperaPercent >= self.playerApperaPercent) [self addPlayerViewToCell];
    };
    
    scrollView.zf_playerDisappearingInScrollView = ^(NSIndexPath * _Nonnull indexPath, CGFloat playerDisapperaPercent) {
        @strongify(self)
        if (self.isFullScreen) return;
        if (self.zf_playerDisappearingInScrollView) self.zf_playerDisappearingInScrollView(indexPath, playerDisapperaPercent);
        if ([self.controlView respondsToSelector:@selector(playerDisappearingInScrollView:playerDisapperaPercent:)]) {
            [self.controlView playerDisappearingInScrollView:self playerDisapperaPercent:playerDisapperaPercent];
        }
        /// stop playing
        if (self.stopWhileNotVisible && playerDisapperaPercent >= self.playerDisapperaPercent) [self stopCurrentPlayingCell];
        /// add to window
        if (!self.stopWhileNotVisible && playerDisapperaPercent >= self.playerDisapperaPercent) [self addPlayerViewToKeyWindow];
    };
}

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
        [self stopCurrentPlayingCell];
        UIView *cell = [self.scrollView zf_getCellForIndexPath:playingIndexPath];
        self.containerView = [cell viewWithTag:self.containerViewTag];
        [self.orientationObserver cellModelRotateView:self.currentPlayerManager.view rotateViewAtCell:cell playerViewTag:self.containerViewTag];
        [self addDeviceOrientationObserver];
        self.scrollView.zf_playingIndexPath = playingIndexPath;
    }
}

- (void)setShouldAutoPlay:(BOOL)shouldAutoPlay {
    self.scrollView.zf_shouldAutoPlay = shouldAutoPlay;
}

- (void)setSectionPlayerSources:(NSArray<NSArray<id<ZFPlayerSource>> *> * _Nullable)sectionPlayerSources {
    objc_setAssociatedObject(self, @selector(sectionPlayerSources), sectionPlayerSources, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setSmallFloatView:(ZFFloatView * _Nullable)smallFloatView {
    objc_setAssociatedObject(self, @selector(smallFloatView), smallFloatView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setIsSmallFloatViewShow:(BOOL)isSmallFloatViewShow {
    objc_setAssociatedObject(self, @selector(isSmallFloatViewShow), @(isSmallFloatViewShow), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setPlayerDisapperaPercent:(CGFloat)playerDisapperaPercent {
    objc_setAssociatedObject(self, @selector(playerDisapperaPercent), @(playerDisapperaPercent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setPlayerApperaPercent:(CGFloat)playerApperaPercent {
    objc_setAssociatedObject(self, @selector(playerApperaPercent), @(playerApperaPercent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

- (void)setZf_scrollViewDidStopScrollCallback:(void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidStopScrollCallback {
    objc_setAssociatedObject(self, @selector(zf_scrollViewDidStopScrollCallback), zf_scrollViewDidStopScrollCallback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - getter

- (UIScrollView *)scrollView {
    UIScrollView *scrollView = objc_getAssociatedObject(self, _cmd);
    return scrollView;
}

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

- (ZFFloatView *)smallFloatView {
    ZFFloatView *smallFloatView = objc_getAssociatedObject(self, _cmd);
    if (!smallFloatView) {
        smallFloatView = [[ZFFloatView alloc] init];
        smallFloatView.parentView = [UIApplication sharedApplication].keyWindow;
        smallFloatView.hidden = YES;
        self.smallFloatView = smallFloatView;
    }
    return smallFloatView;
}

- (BOOL)isSmallFloatViewShow {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (NSIndexPath *)playingIndexPath {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSArray<NSArray<id<ZFPlayerSource>> *> *)sectionPlayerSources {
    return objc_getAssociatedObject(self, _cmd);
}

- (BOOL)shouldAutoPlay {
    return self.scrollView.zf_shouldAutoPlay;
}

- (CGFloat)playerDisapperaPercent {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.floatValue;
    self.playerDisapperaPercent = 0.5;
    return 0.5;
}

- (CGFloat)playerApperaPercent {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.floatValue;
    self.playerApperaPercent = 0.0;
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

- (void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidStopScrollCallback {
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - Public method

- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop completionHandler:(void (^ _Nullable)(void))completionHandler {
    id<ZFPlayerSource>playerSource;
    if (self.sectionPlayerSources.count) {
        playerSource = self.sectionPlayerSources[indexPath.section][indexPath.row];
    } else if (self.playerSources.count) {
        playerSource = self.playerSources[indexPath.row];
        self.currentPlayIndex = indexPath.row;
    }
    if (scrollToTop) {
        @weakify(self)
        [self.scrollView zf_scrollToRowAtIndexPath:indexPath completionHandler:^{
            @strongify(self)
            if (completionHandler) completionHandler();
            self.playingIndexPath = indexPath;
            self.playerSource = playerSource;
            [self.scrollView zf_scrollViewDidStopScroll];
        }];
    } else {
        if (completionHandler) completionHandler();
        self.playingIndexPath = indexPath;
        self.playerSource = playerSource;
    }
}

- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop {
    self.playingIndexPath = indexPath;
    id<ZFPlayerSource>playerSource;
    if (self.sectionPlayerSources.count) {
        playerSource = self.sectionPlayerSources[indexPath.section][indexPath.row];
    } else if (self.playerSources.count) {
        playerSource = self.playerSources[indexPath.row];
        self.currentPlayIndex = indexPath.row;
    }
    self.playerSource = playerSource;
    if (scrollToTop) {
        [self.scrollView zf_scrollToRowAtIndexPath:indexPath completionHandler:nil];
    }
}

- (void)playTheIndexPath:(NSIndexPath *)indexPath playerSource:(id<ZFPlayerSource>)playerSource scrollToTop:(BOOL)scrollToTop {
    self.playingIndexPath = indexPath;
    self.playerSource = playerSource;
    if (scrollToTop) {
        [self.scrollView zf_scrollToRowAtIndexPath:indexPath completionHandler:nil];
    }
}

- (void)stopCurrentPlayingCell {
    if (self.scrollView.zf_playingIndexPath) {
        [self stop];
        self.isSmallFloatViewShow = NO;
        self.scrollView.zf_playingIndexPath = nil;
        if (self.smallFloatView) self.smallFloatView.hidden = YES;
    }
}

@end
