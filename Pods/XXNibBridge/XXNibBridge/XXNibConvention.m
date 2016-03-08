// XXNibConvention.m
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

#import "XXNibConvention.h"

@implementation UIView (XXNibConvention)

#pragma mark - XXNibConvention

+ (NSString *)nibid {
    NSString *className = NSStringFromClass(self);
    if ([className rangeOfString:@"."].location != NSNotFound) {
        // Swift class name contains module name
        return [className componentsSeparatedByString:@"."].lastObject;
    }
    return className;
}

+ (UINib *)nib {
    return [UINib nibWithNibName:self.nibid bundle:nil];
}

#pragma mark - XXDeprecatedNibConvention

+ (NSString *)xx_nibID {
    return self.nibid;
}

+ (UINib *)xx_nib {
    return self.nib;
}

#pragma mark - Public

+ (id)xx_instantiateFromNib {
    return [self xx_instantiateFromNibInBundle:nil owner:nil];
}

+ (id)xx_instantiateFromNibInBundle:(NSBundle *)bundle owner:(id)owner {
    NSArray *views = [self.xx_nib instantiateWithOwner:owner options:nil];
    for (UIView *view in views) {
        if ([view isMemberOfClass:self.class]) {
            return view;
        }
    }
    NSAssert(NO, @"Expect file: %@", [NSString stringWithFormat:@"%@.xib", self.nibid]);
    return nil;
}

@end

@implementation UIViewController (XXNibConvention)

#pragma mark - XXNibConvention

+ (NSString *)nibid {
    return NSStringFromClass(self);
}

+ (UINib *)nib {
    return [UINib nibWithNibName:self.nibid bundle:nil];
}

#pragma mark - XXDeprecatedNibConvention

+ (NSString *)xx_nibID {
    return self.nibid;
}

+ (UINib *)xx_nib {
    return self.nib;
}

#pragma mark - Public

+ (id)xx_instantiateFromStoryboardNamed:(NSString *)name {
    NSParameterAssert(name.length > 0);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:name bundle:nil];
    NSAssert(storyboard != nil, @"Expect file: %@", [NSString stringWithFormat:@"%@.storyboard", name]);
    return [storyboard instantiateViewControllerWithIdentifier:self.nibid];
}

@end
