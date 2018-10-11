//
//  ZFPlayerGestureControl.h
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZFPlayerGestureType) {
    ZFPlayerGestureTypeUnknown,
    ZFPlayerGestureTypeSingleTap,
    ZFPlayerGestureTypeDoubleTap,
    ZFPlayerGestureTypePan,
    ZFPlayerGestureTypePinch
};

typedef NS_ENUM(NSUInteger, ZFPanDirection) {
    ZFPanDirectionUnknown,
    ZFPanDirectionV,
    ZFPanDirectionH,
};

typedef NS_ENUM(NSUInteger, ZFPanLocation) {
    ZFPanLocationUnknown,
    ZFPanLocationLeft,
    ZFPanLocationRight,
};

typedef NS_ENUM(NSUInteger, ZFPanMovingDirection) {
    ZFPanMovingDirectionUnkown,
    ZFPanMovingDirectionTop,
    ZFPanMovingDirectionLeft,
    ZFPanMovingDirectionBottom,
    ZFPanMovingDirectionRight,
};

/// This enumeration lists some of the gesture types that the player has by default.
typedef NS_OPTIONS(NSUInteger, ZFPlayerDisableGestureTypes) {
    ZFPlayerDisableGestureTypesNone         = 0,
    ZFPlayerDisableGestureTypesSingleTap    = 1 << 0,
    ZFPlayerDisableGestureTypesDoubleTap    = 1 << 1,
    ZFPlayerDisableGestureTypesPan          = 1 << 2,
    ZFPlayerDisableGestureTypesPinch        = 1 << 3,
    ZFPlayerDisableGestureTypesAll          = 1 << 4
};

@interface ZFPlayerGestureControl : NSObject

@property (nonatomic, copy, nullable) BOOL(^triggerCondition)(ZFPlayerGestureControl *control, ZFPlayerGestureType type, UIGestureRecognizer *gesture, UITouch *touch);
@property (nonatomic, copy, nullable) void(^singleTapped)(ZFPlayerGestureControl *control);
@property (nonatomic, copy, nullable) void(^doubleTapped)(ZFPlayerGestureControl *control);
@property (nonatomic, copy, nullable) void(^beganPan)(ZFPlayerGestureControl *control, ZFPanDirection direction, ZFPanLocation location);
@property (nonatomic, copy, nullable) void(^changedPan)(ZFPlayerGestureControl *control, ZFPanDirection direction, ZFPanLocation location, CGPoint velocity);
@property (nonatomic, copy, nullable) void(^endedPan)(ZFPlayerGestureControl *control, ZFPanDirection direction, ZFPanLocation location);
@property (nonatomic, copy, nullable) void(^pinched)(ZFPlayerGestureControl *control, float scale);

@property (nonatomic, readonly) ZFPanDirection panDirection;
@property (nonatomic, readonly) ZFPanLocation panLocation;
@property (nonatomic, readonly) ZFPanMovingDirection panMovingDirection;
@property (nonatomic) ZFPlayerDisableGestureTypes disableTypes;

- (void)addGestureToView:(UIView *)view;
- (void)removeGestureToView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
