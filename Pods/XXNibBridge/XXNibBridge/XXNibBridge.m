// XXNibBridge.m
// Version 2.2
//
// Copyright (c) 2015 sunnyxx ( http://github.com/sunnyxx )
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

#import "XXNibBridge.h"
#import <objc/runtime.h>

@interface XXNibBridgeImplementation : NSObject
/// `NS_REPLACES_RECEIVER` attribute is a must for right ownership for `self` under ARC.
- (id)hackedAwakeAfterUsingCoder:(NSCoder *)decoder NS_REPLACES_RECEIVER;
@end

@implementation XXNibBridgeImplementation

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(awakeAfterUsingCoder:);
        SEL swizzledSelector = @selector(hackedAwakeAfterUsingCoder:);
        Method originalMethod = class_getInstanceMethod(UIView.class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        if (class_addMethod(UIView.class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
            class_replaceMethod(UIView.class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (id)hackedAwakeAfterUsingCoder:(NSCoder *)decoder {
    if ([self.class conformsToProtocol:@protocol(XXNibBridge)] && ((UIView *)self).subviews.count == 0) {
        // "self" is placeholder view for this moment, replace it.
        return [XXNibBridgeImplementation instantiateRealViewFromPlaceholder:(UIView *)self];
    }
    return self;
}

+ (UIView *)instantiateRealViewFromPlaceholder:(UIView *)placeholderView {
    
    // Required to conform `XXNibConvension`.
    UIView *realView = [[placeholderView class] xx_instantiateFromNib];

    realView.tag = placeholderView.tag;
    realView.frame = placeholderView.frame;
    realView.bounds = placeholderView.bounds;
    realView.hidden = placeholderView.hidden;
    realView.clipsToBounds = placeholderView.clipsToBounds;
    realView.autoresizingMask = placeholderView.autoresizingMask;
    realView.userInteractionEnabled = placeholderView.userInteractionEnabled;
    realView.translatesAutoresizingMaskIntoConstraints = placeholderView.translatesAutoresizingMaskIntoConstraints;
    
    // Copy autolayout constrains.
    for (NSLayoutConstraint *constraint in placeholderView.constraints) {
        if (!constraint.secondItem) {
            // Height or width constraint.
            [constraint setValue:realView forKey:@"firstItem"];
            [realView addConstraint:constraint];
        } else if ([constraint.firstItem isEqual:constraint.secondItem]) {
            // Aspect ratio constraint.
            [constraint setValue:realView forKey:@"firstItem"];
            [constraint setValue:realView forKey:@"secondItem"];
            [realView addConstraint:constraint];
        }
    }
    return realView;
}

@end
