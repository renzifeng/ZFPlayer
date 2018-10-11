//
//  ZFPortraitControlView.h
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
#import <ZFPlayer/ZFPlayerController.h>
#import "ZFSliderView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZFPortraitControlView : UIView 
/// 底部工具栏
@property (nonatomic, strong, readonly) UIView *bottomToolView;
/// 顶部工具栏
@property (nonatomic, strong, readonly) UIView *topToolView;
/// 标题
@property (nonatomic, strong, readonly) UILabel *titleLabel;
/// 播放或暂停按钮
@property (nonatomic, strong, readonly) UIButton *playOrPauseBtn;
/// 播放的当前时间 
@property (nonatomic, strong, readonly) UILabel *currentTimeLabel;
/// 滑杆
@property (nonatomic, strong, readonly) ZFSliderView *slider;
/// 视频总时间
@property (nonatomic, strong, readonly) UILabel *totalTimeLabel;
/// 全屏按钮
@property (nonatomic, strong, readonly) UIButton *fullScreenBtn;
/// 播放器
@property (nonatomic, weak) ZFPlayerController *player;
/// slider滑动中
@property (nonatomic, copy, nullable) void(^sliderValueChanging)(CGFloat value,BOOL forward);
/// slider滑动结束
@property (nonatomic, copy, nullable) void(^sliderValueChanged)(CGFloat value);

/// 重置控制层
- (void)resetControlView;
/// 显示控制层
- (void)showControlView;
/// 隐藏控制层
- (void)hideControlView;
/// 设置播放时间
- (void)videoPlayer:(ZFPlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime;
/// 设置缓冲时间
- (void)videoPlayer:(ZFPlayerController *)videoPlayer bufferTime:(NSTimeInterval)bufferTime;
/// 是否响应该手势
- (BOOL)shouldResponseGestureWithPoint:(CGPoint)point withGestureType:(ZFPlayerGestureType)type touch:(nonnull UITouch *)touch;
/// 标题和全屏模式
- (void)showTitle:(NSString *_Nullable)title fullScreenMode:(ZFFullScreenMode)fullScreenMode;
/// 根据当前播放状态取反
- (void)playOrPause;
/// 播放按钮状态
- (void)playBtnSelectedState:(BOOL)selected;
/// 调节播放进度slider和当前时间更新
- (void)sliderValueChanged:(CGFloat)value currentTimeString:(NSString *)timeString;
/// 滑杆结束滑动
- (void)sliderChangeEnded;

@end

NS_ASSUME_NONNULL_END
