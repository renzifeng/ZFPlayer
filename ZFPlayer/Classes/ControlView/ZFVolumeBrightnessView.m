//
//  ZFVolumeBrightnessView.m
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

#import "ZFVolumeBrightnessView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ZFUtilities.h"

@interface ZFVolumeBrightnessView ()

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, assign) ZFVolumeBrightnessType volumeBrightnessType;
@property (nonatomic, strong) MPVolumeView *volumeView;

@end

@implementation ZFVolumeBrightnessView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.iconImageView];
        [self addSubview:self.progressView];
        [self hideTipView];
    }
    return self;
}

- (void)dealloc {
    [self addSystemVolumeView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat min_x = 0;
    CGFloat min_y = 0;
    CGFloat min_w = 0;
    CGFloat min_h = 0;
    CGFloat min_view_w = self.frame.size.width;
    CGFloat min_view_h = self.frame.size.height;
    CGFloat margin = 10;
    
    min_x = margin;
    min_w = 20;
    min_h = min_w;
    min_y = (min_view_h-min_h)/2;
    self.iconImageView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = CGRectGetMaxX(self.iconImageView.frame) + margin;
    min_h = 2;
    min_y = (min_view_h-min_h)/2;
    min_w = min_view_w - min_x - margin;
    self.progressView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    self.layer.cornerRadius = min_view_h/2;
    self.layer.masksToBounds = YES;
}

- (void)hideTipView {
    [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

/// 添加系统音量view
- (void)addSystemVolumeView {
    [self.volumeView removeFromSuperview];
}

/// 移除系统音量view
- (void)removeSystemVolumeView {
    [[UIApplication sharedApplication].keyWindow addSubview:self.volumeView];
}

- (void)updateProgress:(CGFloat)progress withVolumeBrightnessType:(ZFVolumeBrightnessType)volumeBrightnessType {
    if (progress >= 1) {
        progress = 1;
    } else if (progress <= 0) {
        progress = 0;
    }
    self.progressView.progress = progress;
    self.volumeBrightnessType = volumeBrightnessType;
    UIImage *playerImage = nil;
    if (volumeBrightnessType == ZFVolumeBrightnessTypeVolume) {
        if (progress == 0) {
            playerImage = ZFPlayer_Image(@"ZFPlayer_muted");
        } else if (progress > 0 && progress < 0.5) {
            playerImage = ZFPlayer_Image(@"ZFPlayer_volume_low");
        } else {
            playerImage = ZFPlayer_Image(@"ZFPlayer_volume_high");
        }
    } else if (volumeBrightnessType == ZFVolumeBrightnessTypeBrightness) {
        if (progress >= 0 && progress < 0.5) {
            playerImage = ZFPlayer_Image(@"ZFPlayer_brightness_low");
        } else {
            playerImage = ZFPlayer_Image(@"ZFPlayer_brightness_high");
        }
    }
    self.iconImageView.image = playerImage;
    self.hidden = NO;
    self.alpha = 1;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideTipView) object:nil];
    [self performSelector:@selector(hideTipView) withObject:nil afterDelay:1.5];
}

- (void)setVolumeBrightnessType:(ZFVolumeBrightnessType)volumeBrightnessType {
    _volumeBrightnessType = volumeBrightnessType;
    if (volumeBrightnessType == ZFVolumeBrightnessTypeVolume) {
        self.iconImageView.image = ZFPlayer_Image(@"ZFPlayer_volume");
    } else {
        self.iconImageView.image = ZFPlayer_Image(@"ZFPlayer_brightness");
    }
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.trackTintColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];;
    }
    return _progressView;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
    }
    return _iconImageView;
}

- (MPVolumeView *)volumeView {
    if (!_volumeView) {
        _volumeView = [[MPVolumeView alloc] init];
        _volumeView.frame = CGRectMake(-1000, -1000, 100, 100);
    }
    return _volumeView;
}

@end
