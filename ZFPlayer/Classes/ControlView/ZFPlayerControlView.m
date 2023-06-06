//
//  ZFPlayerControlView.m
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

#import "ZFPlayerControlView.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "UIView+ZFFrame.h"
#import "ZFSliderView.h"
#import "ZFUtilities.h"
#import "UIImageView+ZFCache.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ZFVolumeBrightnessView.h"
#if __has_include(<ZFPlayer/ZFPlayer.h>)
#import <ZFPlayer/ZFPlayerConst.h>
#else
#import "ZFPlayerConst.h"
#endif


@interface ZFPlayerControlView () <ZFSliderViewDelegate>
/// 竖屏控制层的View
@property (nonatomic, strong) ZFPortraitControlView *portraitControlView;
/// 横屏控制层的View
@property (nonatomic, strong) ZFLandScapeControlView *landScapeControlView;
/// 加载loading
@property (nonatomic, strong) ZFSpeedLoadingView *activity;
/// 快进快退View
@property (nonatomic, strong) UIView *fastView;
/// 快进快退进度progress
@property (nonatomic, strong) ZFSliderView *fastProgressView;
/// 快进快退时间
@property (nonatomic, strong) UILabel *fastTimeLabel;
/// 快进快退ImageView
@property (nonatomic, strong) UIImageView *fastImageView;
/// 加载失败按钮
@property (nonatomic, strong) UIButton *failBtn;
/// 底部播放进度
@property (nonatomic, strong) ZFSliderView *bottomProgress;
/// 是否显示了控制层
@property (nonatomic, assign, getter=isShowing) BOOL showing;
/// 是否播放结束
@property (nonatomic, assign, getter=isPlayEnd) BOOL playEnd;

@property (nonatomic, assign) BOOL controlViewAppeared;

@property (nonatomic, assign) NSTimeInterval sumTime;

@property (nonatomic, strong) dispatch_block_t afterBlock;

@property (nonatomic, strong) ZFSmallFloatControlView *floatControlView;

@property (nonatomic, strong) ZFVolumeBrightnessView *volumeBrightnessView;

@property (nonatomic, strong) UIImageView *bgImgView;

@property (nonatomic, strong) UIView *effectView;

@end

@implementation ZFPlayerControlView
@synthesize player = _player;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addAllSubViews];
        self.landScapeControlView.hidden = YES;
        self.floatControlView.hidden = YES;
        self.seekToPlay = YES;
        self.effectViewShow = YES;
        self.horizontalPanShowControlView = YES;
        self.autoFadeTimeInterval = 0.25;
        self.autoHiddenTimeInterval = 2.5;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(volumeChanged:)
                                                     name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                                   object:nil];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat min_x = 0;
    CGFloat min_y = 0;
    CGFloat min_w = 0;
    CGFloat min_h = 0;
    CGFloat min_view_w = self.zf_width;
    CGFloat min_view_h = self.zf_height;

    self.portraitControlView.frame = self.bounds;
    self.landScapeControlView.frame = self.bounds;
    self.floatControlView.frame = self.bounds;
    self.coverImageView.frame = self.bounds;
    self.bgImgView.frame = self.bounds;
    self.effectView.frame = self.bounds;
    
    min_w = 80;
    min_h = 80;
    self.activity.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.activity.zf_centerX = self.zf_centerX;
    self.activity.zf_centerY = self.zf_centerY + 10;
    
    min_w = 150;
    min_h = 30;
    self.failBtn.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.failBtn.center = self.center;
    
    min_w = 140;
    min_h = 80;
    self.fastView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.fastView.center = self.center;
    
    min_w = 32;
    min_x = (self.fastView.zf_width - min_w) / 2;
    min_y = 5;
    min_h = 32;
    self.fastImageView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = 0;
    min_y = self.fastImageView.zf_bottom + 2;
    min_w = self.fastView.zf_width;
    min_h = 20;
    self.fastTimeLabel.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = 12;
    min_y = self.fastTimeLabel.zf_bottom + 5;
    min_w = self.fastView.zf_width - 2 * min_x;
    min_h = 10;
    self.fastProgressView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = 0;
    min_y = min_view_h - 1;
    min_w = min_view_w;
    min_h = 1;
    self.bottomProgress.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = 0;
    min_y = iPhoneX ? 54 : 30;
    min_w = 170;
    min_h = 35;
    self.volumeBrightnessView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.volumeBrightnessView.zf_centerX = self.zf_centerX;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    [self cancelAutoFadeOutControlView];
}

/// 添加所有子控件
- (void)addAllSubViews {
    [self addSubview:self.portraitControlView];
    [self addSubview:self.landScapeControlView];
    [self addSubview:self.floatControlView];
    [self addSubview:self.activity];
    [self addSubview:self.failBtn];
    [self addSubview:self.fastView];
    [self.fastView addSubview:self.fastImageView];
    [self.fastView addSubview:self.fastTimeLabel];
    [self.fastView addSubview:self.fastProgressView];
    [self addSubview:self.bottomProgress];
    [self addSubview:self.volumeBrightnessView];
}

- (void)autoFadeOutControlView {
    self.controlViewAppeared = YES;
    [self cancelAutoFadeOutControlView];
    @zf_weakify(self)
    self.afterBlock = dispatch_block_create(0, ^{
        @zf_strongify(self)
        [self hideControlViewWithAnimated:YES];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.autoHiddenTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(),self.afterBlock);
}

/// 取消延时隐藏controlView的方法
- (void)cancelAutoFadeOutControlView {
    if (self.afterBlock) {
        dispatch_block_cancel(self.afterBlock);
        self.afterBlock = nil;
    }
}

/// 隐藏控制层
- (void)hideControlViewWithAnimated:(BOOL)animated {
    self.controlViewAppeared = NO;
    if (self.controlViewAppearedCallback) {
        self.controlViewAppearedCallback(NO);
    }
    [UIView animateWithDuration:animated ? self.autoFadeTimeInterval : 0 animations:^{
        if (self.player.isFullScreen) {
            [self.landScapeControlView hideControlView];
        } else {
            if (!self.player.isSmallFloatViewShow) {
                [self.portraitControlView hideControlView];
            }
        }
    } completion:^(BOOL finished) {
        self.bottomProgress.hidden = NO;
    }];
}

/// 显示控制层
- (void)showControlViewWithAnimated:(BOOL)animated {
    self.controlViewAppeared = YES;
    if (self.controlViewAppearedCallback) {
        self.controlViewAppearedCallback(YES);
    }
    [self autoFadeOutControlView];
    [UIView animateWithDuration:animated ? self.autoFadeTimeInterval : 0 animations:^{
        if (self.player.isFullScreen) {
            [self.landScapeControlView showControlView];
        } else {
            if (!self.player.isSmallFloatViewShow) {
                [self.portraitControlView showControlView];
            }
        }
    } completion:^(BOOL finished) {
        self.bottomProgress.hidden = YES;
    }];
}

/// 音量改变的通知
- (void)volumeChanged:(NSNotification *)notification {    
    NSDictionary *userInfo = notification.userInfo;
    NSString *reasonstr = userInfo[@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"];
    if ([reasonstr isEqualToString:@"ExplicitVolumeChange"]) {
        float volume = [ userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
        if (self.player.isFullScreen) {
            [self.volumeBrightnessView updateProgress:volume withVolumeBrightnessType:ZFVolumeBrightnessTypeVolume];
        } else {
            [self.volumeBrightnessView addSystemVolumeView];
        }
    }
}

#pragma mark - Public Method

/// 重置控制层
- (void)resetControlView {
    [self.portraitControlView resetControlView];
    [self.landScapeControlView resetControlView];
    [self cancelAutoFadeOutControlView];
    self.bottomProgress.value = 0;
    self.bottomProgress.bufferValue = 0;
    self.floatControlView.hidden = YES;
    self.failBtn.hidden = YES;
    self.volumeBrightnessView.hidden = YES;
    self.portraitControlView.hidden = self.player.isFullScreen;
    self.landScapeControlView.hidden = !self.player.isFullScreen;
    if (self.controlViewAppeared) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
}

/// 设置标题、封面、全屏模式
- (void)showTitle:(NSString *)title coverURLString:(NSString *)coverUrl fullScreenMode:(ZFFullScreenMode)fullScreenMode {
    UIImage *placeholder = [ZFUtilities imageWithColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1] size:self.bgImgView.bounds.size];
    [self showTitle:title coverURLString:coverUrl placeholderImage:placeholder fullScreenMode:fullScreenMode];
}

/// 设置标题、封面、默认占位图、全屏模式
- (void)showTitle:(NSString *)title coverURLString:(NSString *)coverUrl placeholderImage:(UIImage *)placeholder fullScreenMode:(ZFFullScreenMode)fullScreenMode {
    [self resetControlView];
    [self layoutIfNeeded];
    [self setNeedsDisplay];
    [self.portraitControlView showTitle:title fullScreenMode:fullScreenMode];
    [self.landScapeControlView showTitle:title fullScreenMode:fullScreenMode];
    /// 这里直接设置播放器视图里的coverImageView
    [self.player.currentPlayerManager.view.coverImageView setImageWithURLString:coverUrl placeholder:placeholder];
    [self.bgImgView setImageWithURLString:coverUrl placeholder:placeholder];
    if (self.prepareShowControlView) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
}

/// 设置标题、UIImage封面、全屏模式
- (void)showTitle:(NSString *)title coverImage:(UIImage *)image fullScreenMode:(ZFFullScreenMode)fullScreenMode {
    [self resetControlView];
    [self layoutIfNeeded];
    [self setNeedsDisplay];
    [self.portraitControlView showTitle:title fullScreenMode:fullScreenMode];
    [self.landScapeControlView showTitle:title fullScreenMode:fullScreenMode];
    self.coverImageView.image = image;
    self.bgImgView.image = image;
    if (self.prepareShowControlView) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
}

#pragma mark - ZFPlayerControlViewDelegate

/// 手势筛选，返回NO不响应该手势
- (BOOL)gestureTriggerCondition:(ZFPlayerGestureControl *)gestureControl gestureType:(ZFPlayerGestureType)gestureType gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer touch:(nonnull UITouch *)touch {
    CGPoint point = [touch locationInView:self];
    if (self.player.isSmallFloatViewShow && !self.player.isFullScreen && gestureType != ZFPlayerGestureTypeSingleTap) {
        return NO;
    }
    if (self.player.isFullScreen) {
        if (!self.customDisablePanMovingDirection) {
            /// 不禁用滑动方向
            self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionNone;
        }
        return [self.landScapeControlView shouldResponseGestureWithPoint:point withGestureType:gestureType touch:touch];
    } else {
        if (!self.customDisablePanMovingDirection) {
            if (self.player.scrollView) {  /// 列表时候禁止上下滑动（防止和列表滑动冲突）
                self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionVertical;
            } else { /// 不禁用滑动方向
                self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionNone;
            }
        }
        return [self.portraitControlView shouldResponseGestureWithPoint:point withGestureType:gestureType touch:touch];
    }
}

/// 单击手势事件
- (void)gestureSingleTapped:(ZFPlayerGestureControl *)gestureControl {
    if (!self.player) return;
    if (self.player.isSmallFloatViewShow && !self.player.isFullScreen) {
        [self.player enterFullScreen:YES animated:YES];
    } else {
        if (self.controlViewAppeared) {
            [self hideControlViewWithAnimated:YES];
        } else {
            [self showControlViewWithAnimated:YES];
        }
    }
}

/// 双击手势事件
- (void)gestureDoubleTapped:(ZFPlayerGestureControl *)gestureControl {
    if (self.player.isFullScreen) {
        [self.landScapeControlView playOrPause];
    } else {
        [self.portraitControlView playOrPause];
    }
}

/// 开始滑动手势事件
- (void)gestureBeganPan:(ZFPlayerGestureControl *)gestureControl panDirection:(ZFPanDirection)direction panLocation:(ZFPanLocation)location {
    if (direction == ZFPanDirectionH) {
        self.sumTime = self.player.currentTime;
    }
}

/// 滑动中手势事件
- (void)gestureChangedPan:(ZFPlayerGestureControl *)gestureControl panDirection:(ZFPanDirection)direction panLocation:(ZFPanLocation)location withVelocity:(CGPoint)velocity {
    if (direction == ZFPanDirectionH) {
        // 每次滑动需要叠加时间
        self.sumTime += velocity.x / 200;
        // 需要限定sumTime的范围
        NSTimeInterval totalMovieDuration = self.player.totalTime;
        if (totalMovieDuration == 0) return;
        if (self.sumTime > totalMovieDuration) self.sumTime = totalMovieDuration;
        if (self.sumTime < 0) self.sumTime = 0;
        BOOL style = NO;
        if (velocity.x > 0) style = YES;
        if (velocity.x < 0) style = NO;
        if (velocity.x == 0) return;
        [self sliderValueChangingValue:self.sumTime/totalMovieDuration isForward:style];
    } else if (direction == ZFPanDirectionV) {
        if (location == ZFPanLocationLeft) { /// 调节亮度
            self.player.brightness -= (velocity.y) / 10000;
            [self.volumeBrightnessView updateProgress:self.player.brightness withVolumeBrightnessType:ZFVolumeBrightnessTypeBrightness];
        } else if (location == ZFPanLocationRight) { /// 调节声音
            self.player.volume -= (velocity.y) / 10000;
            if (self.player.isFullScreen) {
                [self.volumeBrightnessView updateProgress:self.player.volume withVolumeBrightnessType:ZFVolumeBrightnessTypeVolume];
            }
        }
    }
}

/// 滑动结束手势事件
- (void)gestureEndedPan:(ZFPlayerGestureControl *)gestureControl panDirection:(ZFPanDirection)direction panLocation:(ZFPanLocation)location {
    @zf_weakify(self)
    if (direction == ZFPanDirectionH && self.sumTime >= 0 && self.player.totalTime > 0) {
        [self.player seekToTime:self.sumTime completionHandler:^(BOOL finished) {
            if (finished) {
                @zf_strongify(self)
                /// 左右滑动调节播放进度
                [self.portraitControlView sliderChangeEnded];
                [self.landScapeControlView sliderChangeEnded];
                self.bottomProgress.isdragging = NO;
                if (self.controlViewAppeared) {
                    [self autoFadeOutControlView];
                }
            }
        }];
        if (self.seekToPlay) {
            [self.player.currentPlayerManager play];
        }
        self.sumTime = 0;
    }
}

/// 捏合手势事件，这里改变了视频的填充模式
- (void)gesturePinched:(ZFPlayerGestureControl *)gestureControl scale:(float)scale {
    if (scale > 1) {
        self.player.currentPlayerManager.scalingMode = ZFPlayerScalingModeAspectFill;
    } else {
        self.player.currentPlayerManager.scalingMode = ZFPlayerScalingModeAspectFit;
    }
}

- (void)longPressed:(ZFPlayerGestureControl *)gestureControl state:(ZFLongPressGestureRecognizerState)state {
    
}

/// 准备播放
- (void)videoPlayer:(ZFPlayerController *)videoPlayer prepareToPlay:(NSURL *)assetURL {
    [self hideControlViewWithAnimated:NO];
}

/// 播放状态改变
- (void)videoPlayer:(ZFPlayerController *)videoPlayer playStateChanged:(ZFPlayerPlaybackState)state {
    if (state == ZFPlayerPlayStatePlaying) {
        [self.portraitControlView playBtnSelectedState:YES];
        [self.landScapeControlView playBtnSelectedState:YES];
        self.failBtn.hidden = YES;
        /// 开始播放时候判断是否显示loading
        if (videoPlayer.currentPlayerManager.loadState == ZFPlayerLoadStateStalled && !self.prepareShowLoading) {
            [self.activity startAnimating];
        } else if ((videoPlayer.currentPlayerManager.loadState == ZFPlayerLoadStateStalled || videoPlayer.currentPlayerManager.loadState == ZFPlayerLoadStatePrepare) && self.prepareShowLoading) {
            [self.activity startAnimating];
        }
    } else if (state == ZFPlayerPlayStatePaused) {
        [self.portraitControlView playBtnSelectedState:NO];
        [self.landScapeControlView playBtnSelectedState:NO];
        /// 暂停的时候隐藏loading
        [self.activity stopAnimating];
        self.failBtn.hidden = YES;
    } else if (state == ZFPlayerPlayStatePlayFailed) {
        self.failBtn.hidden = NO;
        [self.activity stopAnimating];
    }
}

/// 加载状态改变
- (void)videoPlayer:(ZFPlayerController *)videoPlayer loadStateChanged:(ZFPlayerLoadState)state {
    if (state == ZFPlayerLoadStatePrepare) {
        self.coverImageView.hidden = NO;
        [self.portraitControlView playBtnSelectedState:videoPlayer.currentPlayerManager.shouldAutoPlay];
        [self.landScapeControlView playBtnSelectedState:videoPlayer.currentPlayerManager.shouldAutoPlay];
    } else if (state == ZFPlayerLoadStatePlaythroughOK || state == ZFPlayerLoadStatePlayable) {
        self.coverImageView.hidden = YES;
        if (self.effectViewShow) {
            self.effectView.hidden = NO;
        } else {
            self.effectView.hidden = YES;
            self.player.currentPlayerManager.view.backgroundColor = [UIColor blackColor];
        }
    }
    if (state == ZFPlayerLoadStateStalled && videoPlayer.currentPlayerManager.isPlaying && !self.prepareShowLoading) {
        [self.activity startAnimating];
    } else if ((state == ZFPlayerLoadStateStalled || state == ZFPlayerLoadStatePrepare) && videoPlayer.currentPlayerManager.isPlaying && self.prepareShowLoading) {
        [self.activity startAnimating];
    } else {
        [self.activity stopAnimating];
    }
}

/// 播放进度改变回调
- (void)videoPlayer:(ZFPlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    [self.portraitControlView videoPlayer:videoPlayer currentTime:currentTime totalTime:totalTime];
    [self.landScapeControlView videoPlayer:videoPlayer currentTime:currentTime totalTime:totalTime];
    if (!self.bottomProgress.isdragging) {
        self.bottomProgress.value = videoPlayer.progress;
    }
}

/// 缓冲改变回调
- (void)videoPlayer:(ZFPlayerController *)videoPlayer bufferTime:(NSTimeInterval)bufferTime {
    [self.portraitControlView videoPlayer:videoPlayer bufferTime:bufferTime];
    [self.landScapeControlView videoPlayer:videoPlayer bufferTime:bufferTime];
    self.bottomProgress.bufferValue = videoPlayer.bufferProgress;
}

- (void)videoPlayer:(ZFPlayerController *)videoPlayer presentationSizeChanged:(CGSize)size {
    [self.landScapeControlView videoPlayer:videoPlayer presentationSizeChanged:size];
}

/// 视频view即将旋转
- (void)videoPlayer:(ZFPlayerController *)videoPlayer orientationWillChange:(ZFOrientationObserver *)observer {
    self.portraitControlView.hidden = observer.isFullScreen;
    self.landScapeControlView.hidden = !observer.isFullScreen;
    if (videoPlayer.isSmallFloatViewShow) {
        self.floatControlView.hidden = observer.isFullScreen;
        self.portraitControlView.hidden = YES;
        if (observer.isFullScreen) {
            self.controlViewAppeared = NO;
            [self cancelAutoFadeOutControlView];
        }
    }
    if (self.controlViewAppeared) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
    
    if (observer.isFullScreen) {
        [self.volumeBrightnessView removeSystemVolumeView];
    } else {
        [self.volumeBrightnessView addSystemVolumeView];
    }
    [self.landScapeControlView videoPlayer:videoPlayer orientationWillChange:observer];
}

/// 锁定旋转方向
- (void)lockedVideoPlayer:(ZFPlayerController *)videoPlayer lockedScreen:(BOOL)locked {
    [self showControlViewWithAnimated:YES];
}

/// 列表滑动时视频view已经显示
- (void)playerDidAppearInScrollView:(ZFPlayerController *)videoPlayer {
    if (!self.player.stopWhileNotVisible && !videoPlayer.isFullScreen) {
        self.floatControlView.hidden = YES;
        self.portraitControlView.hidden = NO;
    }
}

/// 列表滑动时视频view已经消失
- (void)playerDidDisappearInScrollView:(ZFPlayerController *)videoPlayer {
    if (!self.player.stopWhileNotVisible && !videoPlayer.isFullScreen) {
        self.floatControlView.hidden = NO;
        self.portraitControlView.hidden = YES;
    }
}

- (void)videoPlayer:(ZFPlayerController *)videoPlayer floatViewShow:(BOOL)show {
    self.floatControlView.hidden = !show;
    self.portraitControlView.hidden = show;
}

#pragma mark - Private Method

- (void)sliderValueChangingValue:(CGFloat)value isForward:(BOOL)forward {
    if (self.horizontalPanShowControlView) {
        /// 显示控制层
        [self showControlViewWithAnimated:NO];
        [self cancelAutoFadeOutControlView];
    }
    
    self.fastProgressView.value = value;
    self.fastView.hidden = NO;
    self.fastView.alpha = 1;
    if (forward) {
        self.fastImageView.image = ZFPlayer_Image(@"ZFPlayer_fast_forward");
    } else {
        self.fastImageView.image = ZFPlayer_Image(@"ZFPlayer_fast_backward");
    }
    NSString *draggedTime = [ZFUtilities convertTimeSecond:self.player.totalTime*value];
    NSString *totalTime = [ZFUtilities convertTimeSecond:self.player.totalTime];
    self.fastTimeLabel.text = [NSString stringWithFormat:@"%@ / %@",draggedTime,totalTime];
    /// 更新滑杆
    [self.portraitControlView sliderValueChanged:value currentTimeString:draggedTime];
    [self.landScapeControlView sliderValueChanged:value currentTimeString:draggedTime];
    self.bottomProgress.isdragging = YES;
    self.bottomProgress.value = value;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideFastView) object:nil];
    [self performSelector:@selector(hideFastView) withObject:nil afterDelay:0.1];
    
    if (self.fastViewAnimated) {
        [UIView animateWithDuration:0.4 animations:^{
            self.fastView.transform = CGAffineTransformMakeTranslation(forward?8:-8, 0);
        }];
    }
}

/// 隐藏快进视图
- (void)hideFastView {
    [UIView animateWithDuration:0.4 animations:^{
        self.fastView.transform = CGAffineTransformIdentity;
        self.fastView.alpha = 0;
    } completion:^(BOOL finished) {
        self.fastView.hidden = YES;
    }];
}

/// 加载失败
- (void)failBtnClick:(UIButton *)sender {
    [self.player.currentPlayerManager reloadPlayer];
}

#pragma mark - setter

- (void)setPlayer:(ZFPlayerController *)player {
    _player = player;
    self.landScapeControlView.player = player;
    self.portraitControlView.player = player;
    /// 解决播放时候黑屏闪一下问题
    [player.currentPlayerManager.view insertSubview:self.bgImgView atIndex:0];
    [self.bgImgView addSubview:self.effectView];
    self.bgImgView.frame = player.currentPlayerManager.view.bounds;
    self.bgImgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.effectView.frame = self.bgImgView.bounds;
}

- (void)setSeekToPlay:(BOOL)seekToPlay {
    _seekToPlay = seekToPlay;
    self.portraitControlView.seekToPlay = seekToPlay;
    self.landScapeControlView.seekToPlay = seekToPlay;
}

- (void)setEffectViewShow:(BOOL)effectViewShow {
    _effectViewShow = effectViewShow;
    if (effectViewShow) {
        self.bgImgView.hidden = NO;
    } else {
        self.bgImgView.hidden = YES;
    }
}

- (void)setFullScreenMode:(ZFFullScreenMode)fullScreenMode {
    _fullScreenMode = fullScreenMode;
    self.portraitControlView.fullScreenMode = fullScreenMode;
    self.landScapeControlView.fullScreenMode = fullScreenMode;
    self.player.orientationObserver.fullScreenMode = fullScreenMode;
}

- (void)setShowCustomStatusBar:(BOOL)showCustomStatusBar {
    _showCustomStatusBar = showCustomStatusBar;
    self.landScapeControlView.showCustomStatusBar = showCustomStatusBar;
}

#pragma mark - getter

- (UIImageView *)bgImgView {
    if (!_bgImgView) {
        _bgImgView = [[UIImageView alloc] init];
        _bgImgView.userInteractionEnabled = YES;
    }
    return _bgImgView;
}

- (UIView *)effectView {
    if (!_effectView) {
        if (@available(iOS 8.0, *)) {
            UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        } else {
            UIToolbar *effectView = [[UIToolbar alloc] init];
            effectView.barStyle = UIBarStyleBlackTranslucent;
            _effectView = effectView;
        }
    }
    return _effectView;
}

- (ZFPortraitControlView *)portraitControlView {
    if (!_portraitControlView) {
        @zf_weakify(self)
        _portraitControlView = [[ZFPortraitControlView alloc] init];
        _portraitControlView.sliderValueChanging = ^(CGFloat value, BOOL forward) {
            @zf_strongify(self)
            NSString *draggedTime = [ZFUtilities convertTimeSecond:self.player.totalTime*value];
            /// 更新滑杆和时间
            [self.landScapeControlView sliderValueChanged:value currentTimeString:draggedTime];
            self.fastProgressView.value = value;
            self.bottomProgress.isdragging = YES;
            self.bottomProgress.value = value;
            [self cancelAutoFadeOutControlView];
        };
        _portraitControlView.sliderValueChanged = ^(CGFloat value) {
            @zf_strongify(self)
            [self.landScapeControlView sliderChangeEnded];
            self.fastProgressView.value = value;
            self.bottomProgress.isdragging = NO;
            self.bottomProgress.value = value;
            [self autoFadeOutControlView];
        };
    }
    return _portraitControlView;
}

- (ZFLandScapeControlView *)landScapeControlView {
    if (!_landScapeControlView) {
        @zf_weakify(self)
        _landScapeControlView = [[ZFLandScapeControlView alloc] init];
        _landScapeControlView.sliderValueChanging = ^(CGFloat value, BOOL forward) {
            @zf_strongify(self)
            NSString *draggedTime = [ZFUtilities convertTimeSecond:self.player.totalTime*value];
            /// 更新滑杆和时间
            [self.portraitControlView sliderValueChanged:value currentTimeString:draggedTime];
            self.fastProgressView.value = value;
            self.bottomProgress.isdragging = YES;
            self.bottomProgress.value = value;
            [self cancelAutoFadeOutControlView];
        };
        _landScapeControlView.sliderValueChanged = ^(CGFloat value) {
            @zf_strongify(self)
            [self.portraitControlView sliderChangeEnded];
            self.fastProgressView.value = value;
            self.bottomProgress.isdragging = NO;
            self.bottomProgress.value = value;
            [self autoFadeOutControlView];
        };
    }
    return _landScapeControlView;
}

- (ZFSpeedLoadingView *)activity {
    if (!_activity) {
        _activity = [[ZFSpeedLoadingView alloc] init];
    }
    return _activity;
}

- (UIView *)fastView {
    if (!_fastView) {
        _fastView = [[UIView alloc] init];
        _fastView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        _fastView.layer.cornerRadius = 4;
        _fastView.layer.masksToBounds = YES;
        _fastView.hidden = YES;
    }
    return _fastView;
}

- (UIImageView *)fastImageView {
    if (!_fastImageView) {
        _fastImageView = [[UIImageView alloc] init];
    }
    return _fastImageView;
}

- (UILabel *)fastTimeLabel {
    if (!_fastTimeLabel) {
        _fastTimeLabel = [[UILabel alloc] init];
        _fastTimeLabel.textColor = [UIColor whiteColor];
        _fastTimeLabel.textAlignment = NSTextAlignmentCenter;
        _fastTimeLabel.font = [UIFont systemFontOfSize:14.0];
        _fastTimeLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _fastTimeLabel;
}

- (ZFSliderView *)fastProgressView {
    if (!_fastProgressView) {
        _fastProgressView = [[ZFSliderView alloc] init];
        _fastProgressView.maximumTrackTintColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
        _fastProgressView.minimumTrackTintColor = [UIColor whiteColor];
        _fastProgressView.sliderHeight = 2;
        _fastProgressView.isHideSliderBlock = NO;
    }
    return _fastProgressView;
}

- (UIButton *)failBtn {
    if (!_failBtn) {
        _failBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_failBtn setTitle:@"加载失败,点击重试" forState:UIControlStateNormal];
        [_failBtn addTarget:self action:@selector(failBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_failBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _failBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
        _failBtn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        _failBtn.hidden = YES;
    }
    return _failBtn;
}

- (ZFSliderView *)bottomProgress {
    if (!_bottomProgress) {
        _bottomProgress = [[ZFSliderView alloc] init];
        _bottomProgress.maximumTrackTintColor = [UIColor clearColor];
        _bottomProgress.minimumTrackTintColor = [UIColor whiteColor];
        _bottomProgress.bufferTrackTintColor  = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _bottomProgress.sliderHeight = 1;
        _bottomProgress.isHideSliderBlock = NO;
    }
    return _bottomProgress;
}

- (ZFSmallFloatControlView *)floatControlView {
    if (!_floatControlView) {
        _floatControlView = [[ZFSmallFloatControlView alloc] init];
        @zf_weakify(self)
        _floatControlView.closeClickCallback = ^{
            @zf_strongify(self)
            if (self.player.containerType == ZFPlayerContainerTypeCell) {
                [self.player stopCurrentPlayingCell];
            } else if (self.player.containerType == ZFPlayerContainerTypeView) {
                [self.player stopCurrentPlayingView];
            }
            [self resetControlView];
        };
    }
    return _floatControlView;
}

- (ZFVolumeBrightnessView *)volumeBrightnessView {
    if (!_volumeBrightnessView) {
        _volumeBrightnessView = [[ZFVolumeBrightnessView alloc] init];
        _volumeBrightnessView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        _volumeBrightnessView.hidden = YES;
    }
    return _volumeBrightnessView;
}

- (void)setBackBtnClickCallback:(void (^)(void))backBtnClickCallback {
    _backBtnClickCallback = [backBtnClickCallback copy];
    self.landScapeControlView.backBtnClickCallback = _backBtnClickCallback;
}

@end
