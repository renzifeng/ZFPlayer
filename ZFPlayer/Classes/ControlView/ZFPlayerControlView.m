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
#import "ZFSmallFloatControlView.h"
#if __has_include(<ZFPlayer/ZFPlayer.h>)
#import <ZFPlayer/ZFPlayer.h>
#else
#import "ZFPlayer.h"
#endif

static const CGFloat ZFPlayerAnimationTimeInterval              = 2.5f;
static const CGFloat ZFPlayerControlViewAutoFadeOutTimeInterval = 0.25f;

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
@property (nonatomic, strong) ZFSliderView *bottomPgrogress;
/// 封面图
@property (nonatomic, strong) UIImageView *coverImageView;
/// 是否显示了控制层
@property (nonatomic, assign, getter=isShowing) BOOL showing;
/// 是否播放结束
@property (nonatomic, assign, getter=isPlayEnd) BOOL playeEnd;

@property (nonatomic, assign) BOOL controlViewAppeared;

@property (nonatomic, assign) NSTimeInterval sumTime;

@property (nonatomic, strong) dispatch_block_t afterBlock;

@property (nonatomic, strong) ZFSmallFloatControlView *floatControlView;

@property (nonatomic, strong) ZFVolumeBrightnessView *volumeBrightnessView;

@end

@implementation ZFPlayerControlView
@synthesize player = _player;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addAllSubViews];
        self.landScapeControlView.hidden = YES;
        self.floatControlView.hidden = YES;
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
    CGFloat min_view_w = self.width;
    CGFloat min_view_h = self.height;
    
    min_w = min_view_w;
    min_h = min_view_h;
    self.portraitControlView.frame = self.bounds;
    self.landScapeControlView.frame = self.bounds;
    self.floatControlView.frame = self.bounds;
    self.coverImageView.frame = self.player.currentPlayerManager.view.bounds;
    
    min_w = 80;
    min_h = 80;
    self.activity.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.activity.centerX = self.centerX;
    self.activity.centerY = self.centerY + 10;
    
    min_w = 150;
    min_h = 30;
    self.failBtn.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.failBtn.center = self.center;
    
    min_w = 140;
    min_h = 80;
    self.fastView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.fastView.center = self.center;
    
    min_w = 32;
    min_x = (self.fastView.width - min_w) / 2;
    min_y = 5;
    min_h = 32;
    self.fastImageView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = 0;
    min_y = self.fastImageView.bottom + 2;
    min_w = self.fastView.width;
    min_h = 20;
    self.fastTimeLabel.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = 12;
    min_y = self.fastTimeLabel.bottom + 5;
    min_w = self.fastView.width - 2 * min_x;
    min_h = 10;
    self.fastProgressView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = 0;
    min_y = min_view_h - 1;
    min_w = min_view_w;
    min_h = 1;
    self.bottomPgrogress.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = 0;
    min_y = 0;
    min_w = 160;
    min_h = 40;
    self.volumeBrightnessView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.volumeBrightnessView.center = self.center;
    
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
    [self addSubview:self.bottomPgrogress];
    [self addSubview:self.volumeBrightnessView];
}

- (void)autoFadeOutControlView {
    self.controlViewAppeared = YES;
    [self cancelAutoFadeOutControlView];
    @weakify(self)
    self.afterBlock = dispatch_block_create(0, ^{
        @strongify(self)
        [self hideControlViewWithAnimated:YES];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ZFPlayerAnimationTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(),self.afterBlock);
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
    [UIView animateWithDuration:animated?ZFPlayerControlViewAutoFadeOutTimeInterval:0 animations:^{
        if (self.player.isFullScreen) {
            [self.landScapeControlView hideControlView];
        } else {
            if (!self.player.isSmallFloatViewShow) {
                [self.portraitControlView hideControlView];
            }
        }
        self.controlViewAppeared = NO;
    } completion:^(BOOL finished) {
        self.bottomPgrogress.hidden = NO;
    }];
}

/// 显示控制层
- (void)showControlViewWithAnimated:(BOOL)animated  {
    [UIView animateWithDuration:animated?ZFPlayerControlViewAutoFadeOutTimeInterval:0 animations:^{
        if (self.player.isFullScreen) {
            [self.landScapeControlView showControlView];
        } else {
            if (!self.player.isSmallFloatViewShow) {
                [self.portraitControlView showControlView];
            }
        }
        self.bottomPgrogress.hidden = YES;
    } completion:^(BOOL finished) {
        [self autoFadeOutControlView];
    }];
}

/// 音量改变的通知
- (void)volumeChanged:(NSNotification *)notification {
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    if (self.player.isFullScreen) {
        [self.volumeBrightnessView updateProgress:volume withVolumeBrightnessType:ZFVolumeBrightnessTypeVolume];
    } else {
        [self.volumeBrightnessView addSystemVolumeView];
    }
}

#pragma mark - Public Method

/// 重置控制层
- (void)resetControlView {
    [self.portraitControlView resetControlView];
    [self.landScapeControlView resetControlView];
    self.bottomPgrogress.value = 0;
    self.bottomPgrogress.bufferValue = 0;
    self.floatControlView.hidden = YES;
    self.failBtn.hidden = YES;
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
    [self resetControlView];
    [self layoutIfNeeded];
    [self setNeedsDisplay];
    [self.portraitControlView showTitle:title fullScreenMode:fullScreenMode];
    [self.landScapeControlView showTitle:title fullScreenMode:fullScreenMode];
    [self.coverImageView setImageWithURLString:coverUrl placeholder:self.placeholderImage];
}

#pragma mark - ZFPlayerControlViewDelegate

/// 手势筛选，返回NO不响应该手势
- (BOOL)gestureTriggerCondition:(ZFPlayerGestureControl *)gestureControl gestureType:(ZFPlayerGestureType)gestureType gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer touch:(nonnull UITouch *)touch {
    CGPoint point = [touch locationInView:self];
    if (self.player.isSmallFloatViewShow && !self.player.isFullScreen && gestureType != ZFPlayerGestureTypeSingleTap) {
        return NO;
    }
    if (self.player.isFullScreen) {
        return [self.landScapeControlView shouldResponseGestureWithPoint:point withGestureType:gestureType touch:touch];
    } else {
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
        if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
        if (self.sumTime < 0) { self.sumTime = 0; }
        BOOL style = false;
        if (velocity.x > 0) { style = YES; }
        if (velocity.x < 0) { style = NO; }
        if (velocity.x == 0) { return; }
        [self sliderValueChangingValue:self.sumTime/totalMovieDuration isForward:style];
    } else if (direction == ZFPanDirectionV) {
        if (location == ZFPanLocationLeft) { /// 调节亮度
            self.player.brightness -= (velocity.y) / 10000;
            [self.volumeBrightnessView updateProgress:self.player.brightness withVolumeBrightnessType:ZFVolumeBrightnessTypeumeBrightness];
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
    if (direction == ZFPanDirectionH && self.sumTime >= 0 && self.player.totalTime > 0) {
        [self.player seekToTime:self.sumTime completionHandler:nil];
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

/// 准备播放
- (void)videoPlayer:(ZFPlayerController *)videoPlayer prepareToPlay:(NSURL *)playerSource {
    [self hideControlViewWithAnimated:NO];
}

/// 播放状态改变
- (void)videoPlayer:(ZFPlayerController *)videoPlayer playStateChanged:(ZFPlayerPlaybackState)state {
    if (state == ZFPlayerPlayStatePlaying) {
        [self.portraitControlView playBtnSelectedState:YES];
        [self.landScapeControlView playBtnSelectedState:YES];
        self.failBtn.hidden = YES;
    } else if (state == ZFPlayerPlayStatePaused) {
        [self.portraitControlView playBtnSelectedState:NO];
        [self.landScapeControlView playBtnSelectedState:NO];
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
    } else if (state == ZFPlayerLoadStatePlaythroughOK) {
        self.coverImageView.hidden = YES;
    }
    if (state == ZFPlayerLoadStateStalled || state == ZFPlayerLoadStatePrepare) {
        [self.activity startAnimating];
    } else {
        [self.activity stopAnimating];
    }
}

/// 播放进度改变回调
- (void)videoPlayer:(ZFPlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    [self.portraitControlView videoPlayer:videoPlayer currentTime:currentTime totalTime:totalTime];
    [self.landScapeControlView videoPlayer:videoPlayer currentTime:currentTime totalTime:totalTime];
    self.bottomPgrogress.value = videoPlayer.progress;
}

/// 缓冲改变回调
- (void)videoPlayer:(ZFPlayerController *)videoPlayer bufferTime:(NSTimeInterval)bufferTime {
    [self.portraitControlView videoPlayer:videoPlayer bufferTime:bufferTime];
    [self.landScapeControlView videoPlayer:videoPlayer bufferTime:bufferTime];
    self.bottomPgrogress.bufferValue = videoPlayer.bufferProgress;
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
}

/// 视频view已经旋转
- (void)videoPlayer:(ZFPlayerController *)videoPlayer orientationDidChanged:(ZFOrientationObserver *)observer {
    if (self.controlViewAppeared) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
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

#pragma mark - Private Method

- (void)sliderValueChangingValue:(CGFloat)value isForward:(BOOL)forward {
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
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideFastView) object:nil];
    [self performSelector:@selector(hideFastView) withObject:nil afterDelay:0.1];
    
    if (self.fastViewAnimated) {
        [UIView animateWithDuration:0.4 animations:^{
            self.fastView.transform = CGAffineTransformMakeTranslation(forward?10:-10, 0);
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
    /// 封面图加到播放视图底部了，解决播放时候黑屏闪一下问题
    [player.currentPlayerManager.view insertSubview:self.coverImageView atIndex:0];
    self.coverImageView.frame = player.currentPlayerManager.view.bounds;
    self.coverImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

#pragma mark - getter

- (ZFPortraitControlView *)portraitControlView {
    if (!_portraitControlView) {
        @weakify(self)
        _portraitControlView = [[ZFPortraitControlView alloc] init];
        _portraitControlView.sliderValueChanging = ^(CGFloat value, BOOL forward) {
            @strongify(self)
            [self cancelAutoFadeOutControlView];
        };
        _portraitControlView.sliderValueChanged = ^(CGFloat value) {
            @strongify(self)
            [self autoFadeOutControlView];
        };
    }
    return _portraitControlView;
}

- (ZFLandScapeControlView *)landScapeControlView {
    if (!_landScapeControlView) {
        @weakify(self)
        _landScapeControlView = [[ZFLandScapeControlView alloc] init];
        _landScapeControlView.sliderValueChanging = ^(CGFloat value, BOOL forward) {
            @strongify(self)
            [self cancelAutoFadeOutControlView];
        };
        _landScapeControlView.sliderValueChanged = ^(CGFloat value) {
            @strongify(self)
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

- (ZFSliderView *)bottomPgrogress {
    if (!_bottomPgrogress) {
        _bottomPgrogress = [[ZFSliderView alloc] init];
        _bottomPgrogress.maximumTrackTintColor = [UIColor clearColor];
        _bottomPgrogress.minimumTrackTintColor = [UIColor whiteColor];
        _bottomPgrogress.bufferTrackTintColor  = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _bottomPgrogress.sliderHeight = 1;
        _bottomPgrogress.isHideSliderBlock = NO;
    }
    return _bottomPgrogress;
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.userInteractionEnabled = YES;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
    }
    return _coverImageView;
}

- (ZFSmallFloatControlView *)floatControlView {
    if (!_floatControlView) {
        _floatControlView = [[ZFSmallFloatControlView alloc] init];
        @weakify(self)
        _floatControlView.closeClickCallback = ^{
            @strongify(self)
            [self.player stopCurrentPlayingCell];
            [self resetControlView];
        };
    }
    return _floatControlView;
}

- (ZFVolumeBrightnessView *)volumeBrightnessView {
    if (!_volumeBrightnessView) {
        _volumeBrightnessView = [[ZFVolumeBrightnessView alloc] init];
    }
    return _volumeBrightnessView;
}

- (UIImage *)placeholderImage {
    if (!_placeholderImage) {
        _placeholderImage = [ZFUtilities imageWithColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1] size:CGSizeMake(1, 1)];
    }
    return _placeholderImage;
}

@end
