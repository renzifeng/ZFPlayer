//
//  ZFPlayerConst.h
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

typedef NS_ENUM(NSUInteger, ZFPlayerPlaybackState) {
    ZFPlayerPlayStateUnknown,
    ZFPlayerPlayStatePlaying,
    ZFPlayerPlayStatePaused,
    ZFPlayerPlayStatePlayFailed,
    ZFPlayerPlayStatePlayStopped
};

typedef NS_OPTIONS(NSUInteger, ZFPlayerLoadState) {
    ZFPlayerLoadStateUnknown        = 0,
    ZFPlayerLoadStatePrepare        = 1 << 0,
    ZFPlayerLoadStatePlayable       = 1 << 1,
    ZFPlayerLoadStatePlaythroughOK  = 1 << 2, // Playback will be automatically started.
    ZFPlayerLoadStateStalled        = 1 << 3, // Playback will be automatically paused in this state, if started.
};

typedef NS_ENUM(NSInteger, ZFPlayerScalingMode) {
    ZFPlayerScalingModeNone,       // No scaling.
    ZFPlayerScalingModeAspectFit,  // Uniform scale until one dimension fits.
    ZFPlayerScalingModeAspectFill, // Uniform scale until the movie fills the visible bounds. One dimension may have clipped contents.
    ZFPlayerScalingModeFill        // Non-uniform scale. Both render dimensions will exactly match the visible bounds.
};

/**
 Synthsize a weak or strong reference.
 
 Example:
 @zf_weakify(self)
 [self doSomething^{
 @zf_strongify(self)
 if (!self) return;
 ...
 }];
 
 */
#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define zf_weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define zf_weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define zf_weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define zf_weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define zf_strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define zf_strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define zf_strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define zf_strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

// Screen width
#define ZFPlayerScreenWidth     [[UIScreen mainScreen] bounds].size.width
// Screen height
#define ZFPlayerScreenHeight    [[UIScreen mainScreen] bounds].size.height
