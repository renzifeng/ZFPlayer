//
//  UIViewController+ZFPlayerFixSafeArea.m
//  ZFPlayer
//
//  Created by fzy on 2021/3/5.
//  fix: https://github.com/renzifeng/ZFPlayer/issues/1132

#import <objc/message.h>
#import "ZFPlayerController.h"

BOOL zf_isFullScreenOfFixSafeArea = NO;
API_AVAILABLE(ios(13.0)) @protocol _UIViewControllerPrivateMethodsProtocol <NSObject>
- (void)_setContentOverlayInsets:(UIEdgeInsets)insets andLeftMargin:(CGFloat)leftMargin rightMargin:(CGFloat)rightMargin;
@end

API_AVAILABLE(ios(13.0)) @implementation UIViewController (ZFPlayerFixSafeArea)
- (void)zf_setContentOverlayInsets:(UIEdgeInsets)insets andLeftMargin:(CGFloat)leftMargin rightMargin:(CGFloat)rightMargin {
    if (zf_isFullScreenOfFixSafeArea == NO) {
        [self zf_setContentOverlayInsets:insets andLeftMargin:leftMargin rightMargin:rightMargin];
    }
}
@end

API_AVAILABLE(ios(13.0)) @implementation ZFOrientationObserver (ZFPlayerFixSafeArea)
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
            
            Class oo_class = ZFOrientationObserver.class;
            SEL oo_originalSelector = @selector(rotateToOrientation:animated:completion:);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            SEL oo_swizzledSelector = @selector(zf_rotateToOrientation:animated:completion:);
#pragma clang diagnostic pop
            Method oo_originalMethod = class_getInstanceMethod(oo_class, oo_originalSelector);
            Method oo_swizzledMethod = class_getInstanceMethod(oo_class, oo_swizzledSelector);
            method_exchangeImplementations(oo_originalMethod, oo_swizzledMethod);
        });
    }
}

- (void)zf_rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void(^ __nullable)(void))completion {
    zf_isFullScreenOfFixSafeArea = orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight;
    [self zf_rotateToOrientation:orientation animated:animated completion:completion];
}
@end
