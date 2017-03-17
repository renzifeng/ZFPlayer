//
//  UINavigationController+ZFFullscreenPopGesture.m
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

#import "UINavigationController+ZFFullscreenPopGesture.h"
#import <objc/runtime.h>

#define APP_WINDOW                  [UIApplication sharedApplication].delegate.window
#define SCREEN_WIDTH                [UIScreen mainScreen].bounds.size.width
#define SCREEN_BOUNDS               [UIScreen mainScreen].bounds

/** 滑动偏移量临界值 `<150` 会取消返回 `>=150` 会pop*/
#define MAX_PAN_DISTANCE            150
/** 在某范围内允许滑动手势，默认全屏 */
#define PAN_ENABLE_DISTANCE         SCREEN_WIDTH

@interface ZFScreenShotView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView      *maskView;

@end

@implementation ZFScreenShotView

- (instancetype)init {
    self = [super init];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:SCREEN_BOUNDS];
        [self addSubview:_imageView];
        
        _maskView = [[UIView alloc] initWithFrame:SCREEN_BOUNDS];
        _maskView.backgroundColor = [UIColor clearColor];
        [self addSubview:_maskView];
    }
    return self;
}

@end

@implementation UIViewController (ZFFullscreenPopGesture)

- (BOOL)zf_prefersNavigationBarHidden {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setZf_prefersNavigationBarHidden:(BOOL)hidden {
    objc_setAssociatedObject(self, @selector(zf_prefersNavigationBarHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_interactivePopDisabled:(BOOL)zf_interactivePopDisabled {
    objc_setAssociatedObject(self, @selector(zf_interactivePopDisabled), @(zf_interactivePopDisabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)zf_interactivePopDisabled {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setZf_recognizeSimultaneouslyEnable:(BOOL)zf_recognizeSimultaneouslyEnable {
    objc_setAssociatedObject(self, @selector(zf_recognizeSimultaneouslyEnable), @(zf_recognizeSimultaneouslyEnable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)zf_recognizeSimultaneouslyEnable {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end

typedef void (^_ZFViewControllerWillAppearInjectBlock)(UIViewController *viewController, BOOL animated);

@interface UIViewController (ZFFullscreenPopGesturePrivate)
@property (nonatomic, copy) _ZFViewControllerWillAppearInjectBlock zf_willAppearInjectBlock;

@end

@implementation UIViewController (ZFFullscreenPopGesturePrivate)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(zf_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)zf_viewWillAppear:(BOOL)animated {
    // Forward to primary implementation.
    [self zf_viewWillAppear:animated];
    
    if (self.zf_willAppearInjectBlock) {
        self.zf_willAppearInjectBlock(self, animated);
    }
}

- (_ZFViewControllerWillAppearInjectBlock)zf_willAppearInjectBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setZf_willAppearInjectBlock:(_ZFViewControllerWillAppearInjectBlock)block {
    objc_setAssociatedObject(self, @selector(zf_willAppearInjectBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation UINavigationController (ZFFullscreenPopGesture)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            @selector(viewDidLoad),
            @selector(pushViewController:animated:),
            @selector(popToViewController:animated:),
            @selector(popToRootViewControllerAnimated:),
            @selector(popViewControllerAnimated:)
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
    });
}

- (void)zf_viewDidLoad {
    [self zf_viewDidLoad];
    self.interactivePopGestureRecognizer.enabled = NO;
    self.zf_viewControllerBasedNavigationBarAppearanceEnabled = YES;
    self.showViewOffsetScale = 1 / 3.0;
    self.showViewOffset = self.showViewOffsetScale * SCREEN_WIDTH;
    self.screenShotView.hidden = YES;
    // 默认渐变
    self.popGestureStyle = ZFFullscreenPopGestureGradientStyle;
    UIPanGestureRecognizer *popRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragging:)];
    popRecognizer.delegate = self;
    [self.view addGestureRecognizer:popRecognizer];         //自定义的滑动返回手势
}

- (void)zf_setupViewControllerBasedNavigationBarAppearanceIfNeeded:(UIViewController *)appearingViewController {
    if (!self.zf_viewControllerBasedNavigationBarAppearanceEnabled) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    _ZFViewControllerWillAppearInjectBlock block = ^(UIViewController *viewController, BOOL animated) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf setNavigationBarHidden:viewController.zf_prefersNavigationBarHidden animated:animated];
        }
    };
    appearingViewController.zf_willAppearInjectBlock = block;
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (disappearingViewController && !disappearingViewController.zf_willAppearInjectBlock) {
        disappearingViewController.zf_willAppearInjectBlock = block;
    }
}

#pragma mark - 重写父类方法

- (void)zf_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.childViewControllers.count > 0) {
        [self createScreenShot];
    }
    [self zf_setupViewControllerBasedNavigationBarAppearanceIfNeeded:viewController];
    if (![self.viewControllers containsObject:viewController]) {
        [self zf_pushViewController:viewController animated:animated];
    }
}

- (UIViewController *)zf_popViewControllerAnimated:(BOOL)animated {
    [self.childVCImages removeLastObject];
    return [self zf_popViewControllerAnimated:animated];
}

- (NSArray<UIViewController *> *)zf_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray *viewControllers = [self zf_popToViewController:viewController animated:animated];
    if (self.childVCImages.count >= viewControllers.count){
        for (int i = 0; i < viewControllers.count; i++) {
            [self.childVCImages removeLastObject];
        }
    }
    return viewControllers;
}

- (NSArray<UIViewController *> *)zf_popToRootViewControllerAnimated:(BOOL)animated {
    [self.childVCImages removeAllObjects];
    return [self zf_popToRootViewControllerAnimated:animated];
}

- (void)dragging:(UIPanGestureRecognizer *)recognizer{
    // 如果只有1个子控制器,停止拖拽
    if (self.viewControllers.count <= 1) return;
    // 在x方向上移动的距离
    CGFloat tx = [recognizer translationInView:self.view].x;
    // 在x方向上移动的距离除以屏幕的宽度
    CGFloat width_scale;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // 添加截图到最后面
        width_scale = 0;
        self.screenShotView.hidden = NO;
        self.screenShotView.imageView.image = [self.childVCImages lastObject];
        self.screenShotView.imageView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -self.showViewOffset, 0);
        self.screenShotView.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (tx < 0 ) { return; }
        // 移动view
        width_scale = tx / SCREEN_WIDTH;
        self.view.transform = CGAffineTransformTranslate(CGAffineTransformIdentity,tx, 0);
        self.screenShotView.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4 - width_scale * 0.5];
        self.screenShotView.imageView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -self.showViewOffset + tx * self.showViewOffsetScale, 0);
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:self.view];
        BOOL reset = velocity.x < 0;
        // 决定pop还是还原
        if (tx >= MAX_PAN_DISTANCE && !reset) { // pop回去
            [UIView animateWithDuration:0.25 animations:^{
                self.screenShotView.maskView.backgroundColor = [UIColor clearColor];
                self.screenShotView.imageView.transform = reset ? CGAffineTransformTranslate(CGAffineTransformIdentity, -self.showViewOffset, 0) : CGAffineTransformIdentity;
                self.view.transform = reset ? CGAffineTransformIdentity : CGAffineTransformTranslate(CGAffineTransformIdentity, SCREEN_WIDTH, 0);
            } completion:^(BOOL finished) {
                [self popViewControllerAnimated:NO];
                self.screenShotView.hidden = YES;
                self.view.transform = CGAffineTransformIdentity;
                self.screenShotView.imageView.transform = CGAffineTransformIdentity;
            }];
        } else { // 还原回去
            [UIView animateWithDuration:0.25 animations:^{
                self.screenShotView.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4 + width_scale * 0.5];
                self.view.transform = CGAffineTransformIdentity;
                self.screenShotView.imageView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -self.showViewOffset, 0);
            } completion:^(BOOL finished) {
                self.screenShotView.imageView.transform = CGAffineTransformIdentity;
            }];
        }
    }
}

// 截屏
- (void)createScreenShot {
    if (self.childViewControllers.count == self.childVCImages.count+1) {
        UIGraphicsBeginImageContextWithOptions(APP_WINDOW.bounds.size, YES, 0);
        [APP_WINDOW.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.childVCImages addObject:image];
    }
}

#pragma mark - UIGestureRecognizerDelegate

// 手势代理
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.visibleViewController.zf_interactivePopDisabled)     return NO;
    if (self.viewControllers.count <= 1)                          return NO;
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint point = [touch locationInView:gestureRecognizer.view];
        if (point.x < PAN_ENABLE_DISTANCE) {//设置手势触发区
            return YES;
        }
    }
    return NO;
}

// 是否与其他手势共存，一般使用默认值(默认返回NO：不与任何手势共存)
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.visibleViewController.zf_recognizeSimultaneouslyEnable) {
        if ([otherGestureRecognizer isKindOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")] || [otherGestureRecognizer isKindOfClass:NSClassFromString(@"UIPanGestureRecognizer")] ) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Getter and Setter

- (NSMutableArray<UIImage *> *)childVCImages {
    NSMutableArray *images = objc_getAssociatedObject(self, _cmd);
    if (!images) {
        images = @[].mutableCopy;
        objc_setAssociatedObject(self, _cmd, images, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return images;
}

- (ZFScreenShotView *)screenShotView {
    ZFScreenShotView *shotView = objc_getAssociatedObject(self, _cmd);
    if (!shotView) {
        shotView = [[ZFScreenShotView alloc] init];
        shotView.hidden = YES;
        [APP_WINDOW insertSubview:shotView atIndex:0];
        objc_setAssociatedObject(self, _cmd, shotView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return shotView;
}

- (void)setZf_viewControllerBasedNavigationBarAppearanceEnabled:(BOOL)zf_viewControllerBasedNavigationBarAppearanceEnabled {
    objc_setAssociatedObject(self, @selector(zf_viewControllerBasedNavigationBarAppearanceEnabled), @(zf_viewControllerBasedNavigationBarAppearanceEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (BOOL)zf_viewControllerBasedNavigationBarAppearanceEnabled {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setShowViewOffset:(CGFloat)showViewOffset {
    objc_setAssociatedObject(self, @selector(showViewOffset), @(showViewOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (CGFloat)showViewOffset {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (void)setShowViewOffsetScale:(CGFloat)showViewOffsetScale {
    objc_setAssociatedObject(self, @selector(showViewOffsetScale), @(showViewOffsetScale), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (CGFloat)showViewOffsetScale {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (ZFFullscreenPopGestureStyle)popGestureStyle {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setPopGestureStyle:(ZFFullscreenPopGestureStyle)popGestureStyle {
    objc_setAssociatedObject(self, @selector(popGestureStyle), @(popGestureStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (popGestureStyle == ZFFullscreenPopGestureShadowStyle) {
        self.screenShotView.maskView.hidden = YES;
        // 设置阴影
        self.view.layer.shadowColor = [[UIColor grayColor] CGColor];
        self.view.layer.shadowOpacity = 0.7;
        self.view.layer.shadowOffset = CGSizeMake(-3, 0);
        self.view.layer.shadowRadius = 10;
    } else if (popGestureStyle == ZFFullscreenPopGestureGradientStyle) {
        self.screenShotView.maskView.hidden = NO;
    }
}

@end
