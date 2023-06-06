//
//  ZFPresentTransition.m
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

#import "ZFPresentTransition.h"
#import "ZFPlayerConst.h"

@interface ZFPresentTransition ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) ZFPresentTransitionType type;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign, getter=isTransiting) BOOL transiting;

@end

@implementation ZFPresentTransition

- (void)transitionWithTransitionType:(ZFPresentTransitionType)type
                         contentView:(UIView *)contentView
                       containerView:(UIView *)containerView {
    
    self.type = type;
    self.contentView = contentView;
    self.containerView = containerView;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.duration == 0 ? 0.25f : self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    switch (self.type) {
        case ZFPresentTransitionTypePresent: {
            [self presentAnimation:transitionContext];
        }
            break;
        case ZFPresentTransitionTypeDismiss: {
            [self dismissAnimation:transitionContext];
        }
            break;
    }
}

- (void)presentAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    if ([fromVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)fromVC;
        fromVC = nav.viewControllers.lastObject;
    } else if ([fromVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBar = (UITabBarController *)fromVC;
        if ([tabBar.selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)tabBar.selectedViewController;
            fromVC = nav.viewControllers.lastObject;
        } else {
            fromVC = tabBar.selectedViewController;
        }
    }
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:toVC.view];
    [containerView addSubview:self.contentView];
    CGRect originRect = [self.containerView convertRect:self.contentView.frame toView:toVC.view];
    self.contentView.frame = originRect;

    UIColor *tempColor = toVC.view.backgroundColor;
    toVC.view.backgroundColor = [tempColor colorWithAlphaComponent:0];
    toVC.view.alpha = 1;
    [self.delegate zf_orientationWillChange:YES];
    
    CGRect toRect = self.contentFullScreenRect;
    self.transiting = YES;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        self.contentView.frame = toRect;
        [self.contentView layoutIfNeeded];
        toVC.view.backgroundColor = [tempColor colorWithAlphaComponent:1.f];
    } completion:^(BOOL finished) {
        self.transiting = NO;
        [toVC.view addSubview:self.contentView];
        [transitionContext completeTransition:YES];
        [self.delegate zf_orientationDidChanged:YES];
        if (!CGRectEqualToRect(toRect, self.contentFullScreenRect)) {
            self.contentView.frame = self.contentFullScreenRect;
            [self.contentView layoutIfNeeded];
        }
    }];
}

- (void)dismissAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if ([toVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)toVC;
        toVC = nav.viewControllers.lastObject;
    } else if ([toVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBar = (UITabBarController *)toVC;
        if ([tabBar.selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)tabBar.selectedViewController;
            toVC = nav.viewControllers.lastObject;
        } else {
            toVC = tabBar.selectedViewController;
        }
    }
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    fromVC.view.frame = containerView.bounds;
    [containerView addSubview:fromVC.view];
    [containerView addSubview:self.contentView];
    
    CGRect originRect = [fromVC.view convertRect:self.contentView.frame toView:toVC.view];
    self.contentView.frame = originRect;
    CGRect toRect = [self.containerView convertRect:self.containerView.bounds toView:toVC.view];
    [fromVC.view convertRect:self.contentView.bounds toView:self.containerView.window];
    [self.delegate zf_orientationWillChange:NO];
    self.transiting = YES;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromVC.view.alpha = 0;
        self.contentView.frame = toRect;
        [self.contentView layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.containerView addSubview:self.contentView];
        self.contentView.frame = self.containerView.bounds;
        [transitionContext completeTransition:YES];
        [self.delegate zf_orientationDidChanged:NO];
        self.transiting = NO;
    }];
}

- (void)setContentFullScreenRect:(CGRect)contentFullScreenRect {
    _contentFullScreenRect = contentFullScreenRect;
    if (!self.transiting && self.isFullScreen && !self.interation) {
        self.contentView.frame = contentFullScreenRect;
    }
}

@end
