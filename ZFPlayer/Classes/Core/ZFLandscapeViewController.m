//
//  ZFFullScreenViewController.m
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

#import "ZFLandscapeViewController.h"

@interface ZFLandscapeViewController ()

@property (nonatomic, assign) UIInterfaceOrientation currentOrientation;
@property (nonatomic, getter=isRotating) BOOL rotating;

@end

@implementation ZFLandscapeViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentOrientation = UIInterfaceOrientationPortrait;
        _statusBarStyle = UIStatusBarStyleLightContent;
        _statusBarAnimation = UIStatusBarAnimationSlide;
    }
    return self;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    self.rotating = YES;
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (!UIDeviceOrientationIsValidInterfaceOrientation([UIDevice currentDevice].orientation)) {
        return;
    }
    UIInterfaceOrientation newOrientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    UIInterfaceOrientation oldOrientation = _currentOrientation;
    if (UIInterfaceOrientationIsLandscape(newOrientation)) {
        if (self.contentView.superview != self.view) {
            [self.view addSubview:self.contentView];
        }
    }
    
    if (oldOrientation == UIInterfaceOrientationPortrait) {
        self.contentView.frame = [self.delegate ls_targetRect];
        [self.contentView layoutIfNeeded];
    }
    self.currentOrientation = newOrientation;
    
    [self.delegate ls_willRotateToOrientation:self.currentOrientation];
    BOOL isFullscreen = size.width > size.height;
    [CATransaction begin];
//    [CATransaction setDisableActions:YES];
    [CATransaction setDisableActions:self.disableAnimations];
    [coordinator animateAlongsideTransition:^(id _Nonnull context) {
        if (isFullscreen) {
            self.contentView.frame = CGRectMake(0, 0, size.width, size.height);
            } else {
            self.contentView.frame = [self.delegate ls_targetRect];
            }
            [self.contentView layoutIfNeeded];
//        if (@available(iOS 15.0, *)) {
            CGFloat duration = [coordinator transitionDuration];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [CATransaction commit];
            });
//        }
        } completion:^(id _Nonnull context) {
//            if (@available(iOS 15.0, *)) {
//            } else {
//                [CATransaction commit];
//            }
        self.disableAnimations = NO;
        [self.delegate ls_didRotateFromOrientation:self.currentOrientation];
        self.rotating = NO;
    }];
}

- (BOOL)isFullscreen {
    return UIInterfaceOrientationIsLandscape(_currentOrientation);
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return [self.delegate ls_shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIInterfaceOrientation currentOrientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    if (UIInterfaceOrientationIsLandscape(currentOrientation)) {
        return UIInterfaceOrientationMaskLandscape;
    }
    return UIInterfaceOrientationMaskAll;
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

- (void)setRotating:(BOOL)rotating {
    _rotating = rotating;
    if (!rotating && self.rotatingCompleted) {
        self.rotatingCompleted();
    }
}

@end


