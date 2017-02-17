//
//  UIView+CustomControlView.m
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

#import "UIView+CustomControlView.h"
#import <objc/runtime.h>

@implementation UIView (CustomControlView)

- (void)setDelegate:(id<ZFPlayerControlViewDelagate>)delegate
{
    objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<ZFPlayerControlViewDelagate>)delegate
{
   return objc_getAssociatedObject(self, _cmd);
}

/** 
 * 设置播放模型 
 */
- (void)zf_playerModel:(ZFPlayerModel *)playerModel{}

/**
 * 显示top、bottom、lockBtn
 */
- (void)zf_playerShowControlView{}
/**
 * 隐藏top、bottom、lockBtn*/
- (void)zf_playerHideControlView{}

/**
 * 重置ControlView
 */
- (void)zf_playerResetControlView{}

/**
 * 切换分辨率时候调用此方法
 */
- (void)zf_playerResetControlViewForResolution{}

/**
 * 取消自动隐藏控制层view
 */
- (void)zf_playerCancelAutoFadeOutControlView{}

/**
 * 开始播放（隐藏placeholderImageView）
 */
- (void)zf_playerItemPlaying{}

/**
 * 播放完了
 */
- (void)zf_playerPlayEnd{}

/**
 * 是否有下载功能
 */
- (void)zf_playerHasDownloadFunction:(BOOL)sender{}

/**
 * 下载按钮状态
 */
- (void)zf_playerDownloadBtnState:(BOOL)state{}

/**
 * 是否有切换分辨率功能
 * @param resolutionArray 分辨率名称的数组
 */
- (void)zf_playerResolutionArray:(NSArray *)resolutionArray{}

/**
 * 播放按钮状态 (播放、暂停状态)
 */
- (void)zf_playerPlayBtnState:(BOOL)state{}

/**
 * 锁定屏幕方向按钮状态
 */
- (void)zf_playerLockBtnState:(BOOL)state{}

/**
 * 加载的菊花
 */
- (void)zf_playerActivity:(BOOL)animated{}

/**
 * 设置预览图
 
 * @param draggedTime 拖拽的时长
 * @param image       预览图
 */
- (void)zf_playerDraggedTime:(NSInteger)draggedTime sliderImage:(UIImage *)image{}

/**
 * 拖拽快进 快退
 
 * @param draggedTime 拖拽的时长
 * @param totalTime   视频总时长
 * @param forawrd     是否是快进
 * @param preview     是否有预览图
 */
- (void)zf_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview{}

/**
 * 滑动调整进度结束结束
 */
- (void)zf_playerDraggedEnd{}

/**
 * 正常播放
 
 * @param currentTime 当前播放时长
 * @param totalTime   视频总时长
 * @param value       slider的value(0.0~1.0)
 */
- (void)zf_playerCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value{}

/**
 * progress显示缓冲进度
 */
- (void)zf_playerSetProgress:(CGFloat)progress{}

/**
 * 视频加载失败
 */
- (void)zf_playerItemStatusFailed:(NSError *)error{}

/**
 * 小屏播放
 */
- (void)zf_playerBottomShrinkPlay{}

/**
 * 在cell播放
 */
- (void)zf_playerCellPlay{}

@end
