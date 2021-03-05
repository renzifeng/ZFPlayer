//
//  UIViewController+ZFPlayerFixSafeArea.m
//  ZFPlayer
//
//  Created by fzy on 2021/3/5.
//  from https://github.com/changsanjiang/SJVideoPlayer
//  fix: https://github.com/renzifeng/ZFPlayer/issues/1132

#import <objc/message.h>
#import "ZFLandscapeViewController.h"
#import "ZFPlayerController.h"

static NSInteger ZFPlayerViewFixSafeAreaTag = 0xFFFFFFF0;

API_AVAILABLE(ios(13.0)) @protocol _UIViewControllerPrivateMethodsProtocol <NSObject>
- (void)_setContentOverlayInsets:(UIEdgeInsets)insets andLeftMargin:(CGFloat)leftMargin rightMargin:(CGFloat)rightMargin;
@end

@implementation UIViewController (ZFPlayerFixSafeArea)
- (BOOL)zf_containsPlayerView {
    return [self.view viewWithTag:ZFPlayerViewFixSafeAreaTag] != nil;
}

- (void)zf_setContentOverlayInsets:(UIEdgeInsets)insets andLeftMargin:(CGFloat)leftMargin rightMargin:(CGFloat)rightMargin {
    insets.left = 0;
    insets.right = 0;
    BOOL isFullscreen = self.view.bounds.size.width > self.view.bounds.size.height;
    if ( isFullscreen && (insets.top != 0 || [self zf_containsPlayerView] == NO)) {
        [self zf_setContentOverlayInsets:insets andLeftMargin:leftMargin rightMargin:rightMargin];
    }
}
@end

API_AVAILABLE(ios(13.0)) @implementation ZFPlayerController (ZFPlayerFixSafeArea)
+ (void)initialize {
    if ( @available(iOS 13.0, *) ) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class cls = UIViewController.class;
            SEL originalSelector = @selector(_setContentOverlayInsets:andLeftMargin:rightMargin:);
            SEL swizzledSelector = @selector(zf_setContentOverlayInsets:andLeftMargin:rightMargin:);
            
            Method originalMethod = class_getInstanceMethod(cls, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
            method_exchangeImplementations(originalMethod, swizzledMethod);
            
            Class lc_class = ZFPlayerController.class;
            SEL lc_originalSelector = @selector(setContainerView:);
            SEL lc_swizzledSelector = @selector(zf_setContainerView:);
            Method lc_originalMethod = class_getInstanceMethod(lc_class, lc_originalSelector);
            Method lc_swizzledMethod = class_getInstanceMethod(lc_class, lc_swizzledSelector);
            method_exchangeImplementations(lc_originalMethod, lc_swizzledMethod);
        });
    }
}

- (void)zf_setContainerView:(UIView *)containerView {
    [self zf_setContainerView:containerView];
    containerView.tag = ZFPlayerViewFixSafeAreaTag;
}
@end

API_AVAILABLE(ios(13.0)) @implementation UINavigationController (ZFPlayerFixSafeArea)
- (BOOL)sj_containsPlayerView {
    return [self.topViewController zf_containsPlayerView];
}
@end

API_AVAILABLE(ios(13.0)) @implementation UITabBarController (ZFPlayerFixSafeArea)
- (BOOL)sj_containsPlayerView {
    UIViewController *vc = self.selectedIndex != NSNotFound ? self.selectedViewController : self.viewControllers.firstObject;
    return [vc zf_containsPlayerView];
}
@end

