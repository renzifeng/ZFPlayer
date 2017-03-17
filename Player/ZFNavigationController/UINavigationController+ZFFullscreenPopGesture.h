//
//  UINavigationController+ZFFullscreenPopGesture.h
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

#import <UIKit/UIKit.h>

@interface UIViewController (ZFFullscreenPopGesture)

/// 隐藏NavigationBar（默认NO）
@property (nonatomic, assign) BOOL zf_prefersNavigationBarHidden;
/// 关闭某个控制器的pop手势（默认NO）
@property (nonatomic, assign) BOOL zf_interactivePopDisabled;
/// 自定义的滑动返回手势是否与其他手势共存，一般使用默认值(默认返回NO：不与任何手势共存)
@property (nonatomic, assign) BOOL zf_recognizeSimultaneouslyEnable;

@end

typedef NS_ENUM(NSInteger,ZFFullscreenPopGestureStyle) {
    ZFFullscreenPopGestureGradientStyle,   // 根据滑动偏移量背景颜色渐变
    ZFFullscreenPopGestureShadowStyle      // 侧边阴影效果，类似系统的滑动样式
};

@interface UINavigationController (ZFFullscreenPopGesture)<UIGestureRecognizerDelegate>
/** 默认ZFFullscreenPopGestureGradientStyle */
@property (nonatomic, assign) ZFFullscreenPopGestureStyle popGestureStyle;

@end

