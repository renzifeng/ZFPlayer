//
//  ZFPlayerNotification.h
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

typedef NS_ENUM(NSUInteger, ZFPlayerBackgroundState) {
    ZFPlayerBackgroundStateForeground,  // Enter the foreground from the background.
    ZFPlayerBackgroundStateBackground,  // From the foreground to the background.
};

@interface ZFPlayerNotification : NSObject

@property (nonatomic, readonly) ZFPlayerBackgroundState backgroundState;

@property (nonatomic, copy, nullable) void(^willResignActive)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^didBecomeActive)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^newDeviceAvailable)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^oldDeviceUnavailable)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^categoryChange)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^volumeChanged)(float volume);

- (void)addNotification;

- (void)removeNotification;

@end

NS_ASSUME_NONNULL_END
