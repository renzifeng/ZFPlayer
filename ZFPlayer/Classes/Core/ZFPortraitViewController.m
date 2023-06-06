//
//  ZFPortraitViewController.m
//  ZFPlayer
//
// Copyright (c) 2020年 任子丰 ( http://github.com/renzifeng )
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

#import "ZFPortraitViewController.h"
#import "ZFPersentInteractiveTransition.h"
#import "ZFPresentTransition.h"

@interface ZFPortraitViewController ()<UIViewControllerTransitioningDelegate,ZFPortraitOrientationDelegate>

@property (nonatomic, strong) ZFPresentTransition *transition;
@property (nonatomic, strong) ZFPersentInteractiveTransition *interactiveTransition;
@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

@end

@implementation ZFPortraitViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalPresentationCapturesStatusBarAppearance = YES;
        _statusBarStyle = UIStatusBarStyleLightContent;
        _statusBarAnimation = UIStatusBarAnimationSlide;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.fullScreenAnimation) {
        if (self.orientationWillChange) {
            self.orientationWillChange(YES);
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.fullScreenAnimation) {
        self.view.alpha = 1;
        [self.view addSubview:self.contentView];
        self.contentView.frame = [self contentFullScreenRect];
        if (self.orientationDidChanged) {
            self.orientationDidChanged(YES);
        }
    }
    self.fullScreen = YES;
    [self.interactiveTransition updateContentView:self.contentView
                                    containerView:self.containerView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.fullScreenAnimation) {
        if (self.orientationWillChange) {
            self.orientationWillChange(NO);
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.fullScreen = NO;
    if (!self.fullScreenAnimation) {
        [self.containerView addSubview:self.contentView];
        self.contentView.frame = self.containerView.bounds;
        if (self.orientationDidChanged) {
            self.orientationDidChanged(NO);
        }
    }
}

#pragma mark - transition delegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    [self.transition transitionWithTransitionType:ZFPresentTransitionTypePresent contentView:self.contentView containerView:self.containerView];
    return self.transition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    [self.transition transitionWithTransitionType:ZFPresentTransitionTypeDismiss contentView:self.contentView containerView:self.containerView];
    return self.transition;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.interactiveTransition.interation ? self.interactiveTransition : nil;
}


- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return self.statusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.statusBarStyle;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return self.statusBarAnimation;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - ZFPortraitOrientationDelegate

- (void)zf_orientationWillChange:(BOOL)isFullScreen {
    if (self.orientationWillChange) {
        self.orientationWillChange(isFullScreen);
    }
}

- (void)zf_orientationDidChanged:(BOOL)isFullScreen {
    if (self.orientationDidChanged) {
        self.orientationDidChanged(isFullScreen);
    }
}

- (void)zf_interationState:(BOOL)isDragging {
    self.transition.interation = isDragging;
}

#pragma mark - getter

- (ZFPresentTransition *)transition {
    if (!_transition) {
        _transition = [[ZFPresentTransition alloc] init];
        _transition.contentFullScreenRect = [self contentFullScreenRect];
        _transition.delegate = self;
    }
    return _transition;
}

- (ZFPersentInteractiveTransition *)interactiveTransition {
    if (!_interactiveTransition) {
        _interactiveTransition = [[ZFPersentInteractiveTransition alloc] init];
        _interactiveTransition.contentFullScreenRect = [self contentFullScreenRect];
        _interactiveTransition.viewController = self;
        _interactiveTransition.delegate = self;
    }
    return _interactiveTransition;;
}

- (void)setDisablePortraitGestureTypes:(ZFDisablePortraitGestureTypes)disablePortraitGestureTypes {
    _disablePortraitGestureTypes = disablePortraitGestureTypes;
    self.interactiveTransition.disablePortraitGestureTypes = disablePortraitGestureTypes;
}

- (void)setPresentationSize:(CGSize)presentationSize {
    _presentationSize = presentationSize;
    self.transition.contentFullScreenRect = [self contentFullScreenRect];
    self.interactiveTransition.contentFullScreenRect = [self contentFullScreenRect];
    if (!self.fullScreenAnimation && self.isFullScreen) {
        self.contentView.frame = [self contentFullScreenRect];
    }
}

- (void)setFullScreen:(BOOL)fullScreen {
    _fullScreen = fullScreen;
    self.transition.fullScreen = fullScreen;
}

- (void)setFullScreenAnimation:(BOOL)fullScreenAnimation {
    _fullScreenAnimation = fullScreenAnimation;
    self.interactiveTransition.fullScreenAnimation = fullScreenAnimation;
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    self.transition.duration = duration;
}

- (CGRect)contentFullScreenRect {
    CGFloat videoWidth = self.presentationSize.width;
    CGFloat videoHeight = self.presentationSize.height;
    if (videoHeight == 0) {
        return CGRectZero;
    }
    CGSize fullScreenScaleSize = CGSizeZero;
    CGFloat screenScale = ZFPlayerScreenWidth/ZFPlayerScreenHeight;
    CGFloat videoScale = videoWidth/videoHeight;
    if (screenScale > videoScale) {
        CGFloat height = ZFPlayerScreenHeight;
        CGFloat width = height * videoScale;
        fullScreenScaleSize = CGSizeMake(width, height);
    } else {
        CGFloat width = ZFPlayerScreenWidth;
        CGFloat height = (CGFloat)(width / videoScale);
        fullScreenScaleSize = CGSizeMake(width, height);
    }
    
    videoWidth = fullScreenScaleSize.width;
    videoHeight = fullScreenScaleSize.height;
    CGRect rect = CGRectMake((ZFPlayerScreenWidth - videoWidth) / 2.0, (ZFPlayerScreenHeight - videoHeight) / 2.0, videoWidth, videoHeight);
    return rect;
}

@end
