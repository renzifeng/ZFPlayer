//
//  UIViewController+ZFPlayerRotation.m
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

#import "UIViewController+ZFPlayerRotation.h"
#import <objc/runtime.h>

@implementation UIViewController (ZFPlayerRotation)

/**
 * 默认所有都不支持转屏,如需个别页面支持除竖屏外的其他方向，请在viewController重新下边这三个方法
 */

// 是否支持自动转屏
- (BOOL)shouldAutorotate {
    // 这么做是为了 调用系统的 试图播放器的时候 无法横屏的 问题
    NSString *classStr = NSStringFromClass([UIApplication.sharedApplication.keyWindow.rootViewController class]);
    
    if (![classStr isEqualToString:@"SJKTabbarViewController"]&&![classStr isEqualToString:@"SJKLoginViewController"]&&classStr) {
        return true;
    }
    if ([self isKindOfClass:NSClassFromString(@"AVFullScreenViewController")]||[self isKindOfClass:NSClassFromString(@"AVPlayerViewController")]) {
        return true;
    }
    return NO;
}

// 支持哪些屏幕方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // 这么做是为了 调用系统的 试图播放器的时候 无法横屏的 问题
    // 这么做是为了 调用系统的 试图播放器的时候 无法横屏的 问题
    NSString *classStr = NSStringFromClass([UIApplication.sharedApplication.keyWindow.rootViewController class]);
    
    if (![classStr isEqualToString:@"SJKTabbarViewController"]&&![classStr isEqualToString:@"SJKLoginViewController"]&&classStr) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    if ([self isKindOfClass:NSClassFromString(@"AVFullScreenViewController")]||[self isKindOfClass:NSClassFromString(@"AVPlayerViewController")]) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskPortrait;
}

// 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    // 这么做是为了 调用系统的 试图播放器的时候 无法横屏的 问题
    NSString *classStr = NSStringFromClass([UIApplication.sharedApplication.keyWindow.rootViewController class]);
    
    if (![classStr isEqualToString:@"SJKTabbarViewController"]&&![classStr isEqualToString:@"SJKLoginViewController"]&&classStr) {
        return UIInterfaceOrientationLandscapeLeft;
    }
    if ([self isKindOfClass:NSClassFromString(@"AVFullScreenViewController")]||[self isKindOfClass:NSClassFromString(@"AVPlayerViewController")]) {
        return UIInterfaceOrientationLandscapeLeft;
        
    }
    return UIInterfaceOrientationPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault; // your own style
}

- (BOOL)prefersStatusBarHidden {
    return NO; // your own visibility code
}

@end

@implementation UITabBarController (ZFPlayerRotation)

+ (void)load {
    SEL selectors[] = {
        @selector(selectedIndex)
    };
    
    for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
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
}

- (NSInteger)zf_selectedIndex {
    NSInteger index = [self zf_selectedIndex];
    if (index > self.viewControllers.count) { return 0; }
    return index;
}

/**
 * 如果window的根视图是UITabBarController，则会先调用这个Category，然后调用UIViewController+ZFPlayerRotation
 * 只需要在支持除竖屏以外方向的页面重新下边三个方法
 */

// 是否支持自动转屏
- (BOOL)shouldAutorotate {
    UIViewController *vc = self.viewControllers[self.selectedIndex];
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return [nav.topViewController shouldAutorotate];
    } else {
        return [vc shouldAutorotate];
    }
}

// 支持哪些屏幕方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIViewController *vc = self.viewControllers[self.selectedIndex];
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return [nav.topViewController supportedInterfaceOrientations];
    } else {
        return [vc supportedInterfaceOrientations];
    }
}

// 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    UIViewController *vc = self.viewControllers[self.selectedIndex];
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return [nav.topViewController preferredInterfaceOrientationForPresentation];
    } else {
        return [vc preferredInterfaceOrientationForPresentation];
    }
}

@end

@implementation UINavigationController (ZFPlayerRotation)

/**
 * 如果window的根视图是UINavigationController，则会先调用这个Category，然后调用UIViewController+ZFPlayerRotation
 * 只需要在支持除竖屏以外方向的页面重新下边三个方法
 */

// 是否支持自动转屏
- (BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

// 支持哪些屏幕方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

// 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

@end

@implementation UIAlertController (ZFPlayerRotation)

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations; {
    return UIInterfaceOrientationMaskAll;
}
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}
#endif

@end
