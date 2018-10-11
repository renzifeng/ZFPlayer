//
//  ZFSliderView.m
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

#import "ZFSliderView.h"
#import "UIView+ZFFrame.h"

/** 滑块的大小 */
static const CGFloat kSliderBtnWH = 19.0;
/** 间距 */
static const CGFloat kProgressMargin = 2.0;
/** 进度的高度 */
static const CGFloat kProgressH = 2.0;
/** 拖动slider动画的时间*/
static const CGFloat kAnimate = 0.3;

@implementation ZFSliderButton

// 重写此方法将按钮的点击范围扩大
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect bounds = self.bounds;
    // 扩大点击区域
    bounds = CGRectInset(bounds, -20, -20);
    // 若点击的点在新的bounds里面。就返回yes
    return CGRectContainsPoint(bounds, point);
}

@end

@interface ZFSliderView ()

/** 进度背景 */
@property (nonatomic, strong) UIImageView *bgProgressView;
/** 缓存进度 */
@property (nonatomic, strong) UIImageView *bufferProgressView;
/** 滑动进度 */
@property (nonatomic, strong) UIImageView *sliderProgressView;
/** 滑块 */
@property (nonatomic, strong) ZFSliderButton *sliderBtn;

@property (nonatomic, assign) CGPoint lastPoint;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@end

@implementation ZFSliderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.allowTapped = YES;
        self.animate = YES;
        [self addSubViews];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.allowTapped = YES;
    self.animate = YES;
    [self addSubViews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 初始化frame
    if (self.sliderBtn.hidden) {
        self.bgProgressView.width   = self.width;
    } else {
        self.bgProgressView.width   = self.width - kProgressMargin * 2;
    }
    
    self.bgProgressView.centerY     = self.height * 0.5;
    self.bufferProgressView.centerY = self.height * 0.5;
    self.sliderProgressView.centerY = self.height * 0.5;
    self.sliderBtn.centerY          = self.height * 0.5;
    
    /// 修复slider  bufferProgress错位问题
    CGFloat finishValue = self.bgProgressView.width * self.bufferValue;
    self.bufferProgressView.width = finishValue;
    self.sliderProgressView.left = kProgressMargin;
    self.bufferProgressView.left = kProgressMargin;
    
    CGFloat progressValue  = self.bgProgressView.width * self.value;
    self.sliderProgressView.width = progressValue;
    self.sliderBtn.left = (self.width - self.sliderBtn.width) * self.value;
}

/**
 添加子视图
 */
- (void)addSubViews {
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.bgProgressView];
    [self addSubview:self.bufferProgressView];
    [self addSubview:self.sliderProgressView];
    [self addSubview:self.sliderBtn];
    // 初始化frame
    self.bgProgressView.frame     = CGRectMake(kProgressMargin, 0, 0, kProgressH);
    self.bufferProgressView.frame = self.bgProgressView.frame;
    self.sliderProgressView.frame = self.bgProgressView.frame;
    self.sliderBtn.frame          = CGRectMake(0, 0, kSliderBtnWH, kSliderBtnWH);
    
    // 添加点击手势
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self addGestureRecognizer:self.tapGesture];
    
    // 添加滑动手势
    UIPanGestureRecognizer *sliderGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(sliderGesture:)];
    [self addGestureRecognizer:sliderGesture];
}

#pragma mark - Setter

- (void)setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor {
    _maximumTrackTintColor = maximumTrackTintColor;
    self.bgProgressView.backgroundColor = maximumTrackTintColor;
}

- (void)setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor {
    _minimumTrackTintColor = minimumTrackTintColor;
    self.sliderProgressView.backgroundColor = minimumTrackTintColor;
}

- (void)setBufferTrackTintColor:(UIColor *)bufferTrackTintColor {
    _bufferTrackTintColor = bufferTrackTintColor;
    self.bufferProgressView.backgroundColor = bufferTrackTintColor;
}

- (void)setMaximumTrackImage:(UIImage *)maximumTrackImage {
    _maximumTrackImage = maximumTrackImage;
    self.bgProgressView.image = maximumTrackImage;
    self.maximumTrackTintColor = [UIColor clearColor];
}

- (void)setMinimumTrackImage:(UIImage *)minimumTrackImage {
    _minimumTrackImage = minimumTrackImage;
    self.sliderProgressView.image = minimumTrackImage;
    self.minimumTrackTintColor = [UIColor clearColor];
}

- (void)setBufferTrackImage:(UIImage *)bufferTrackImage {
    _bufferTrackImage = bufferTrackImage;
    self.bufferProgressView.image = bufferTrackImage;
    self.bufferTrackTintColor = [UIColor clearColor];
}

- (void)setValue:(float)value {
    if (isnan(value)) return;
    _value = value;
    CGFloat finishValue = self.bgProgressView.width * value;
    self.sliderProgressView.width = finishValue;
    self.sliderBtn.left = (self.width - self.sliderBtn.width) * value;
    self.lastPoint = self.sliderBtn.center;
}

- (void)setBufferValue:(float)bufferValue {
    if (isnan(bufferValue)) return;
    _bufferValue = bufferValue;
    CGFloat finishValue = self.bgProgressView.width * bufferValue;
    self.bufferProgressView.width = finishValue;
}

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state {
    [self.sliderBtn setBackgroundImage:image forState:state];
    [self.sliderBtn sizeToFit];
}

- (void)setThumbImage:(UIImage *)image forState:(UIControlState)state {
    [self.sliderBtn setImage:image forState:state];
    [self.sliderBtn sizeToFit];
}

- (void)setAllowTapped:(BOOL)allowTapped {
    _allowTapped = allowTapped;
    if (!allowTapped) {
        [self removeGestureRecognizer:self.tapGesture];
    }
}

- (void)setSliderHeight:(CGFloat)sliderHeight {
    if (isnan(sliderHeight)) return;
    _sliderHeight = sliderHeight;
    self.bgProgressView.height     = sliderHeight;
    self.bufferProgressView.height = sliderHeight;
    self.sliderProgressView.height = sliderHeight;
}

- (void)setIsHideSliderBlock:(BOOL)isHideSliderBlock {
    _isHideSliderBlock = isHideSliderBlock;
    // 隐藏滑块，滑杆不可点击
    if (isHideSliderBlock) {
        self.sliderBtn.hidden = YES;
        self.bgProgressView.left     = 0;
        self.bufferProgressView.left = 0;
        self.sliderProgressView.left = 0;
        self.allowTapped = NO;
    }
}

#pragma mark - User Action

- (void)sliderGesture:(UIGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            [self sliderBtnTouchBegin:self.sliderBtn];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            [self sliderBtnDragMoving:self.sliderBtn point:[gesture locationInView:self]];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            [self sliderBtnTouchEnded:self.sliderBtn];
        }
            break;
        default:
            break;
    }
}

- (void)sliderBtnTouchBegin:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(sliderTouchBegan:)]) {
        [self.delegate sliderTouchBegan:self.value];
    }
    if (self.animate) {
        [UIView animateWithDuration:kAnimate animations:^{
            btn.transform = CGAffineTransformMakeScale(1.2, 1.2);
        }];
    }
}

- (void)sliderBtnTouchEnded:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(sliderTouchEnded:)]) {
        [self.delegate sliderTouchEnded:self.value];
    }
    if (self.animate) {
        [UIView animateWithDuration:kAnimate animations:^{
            btn.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)sliderBtnDragMoving:(UIButton *)btn point:(CGPoint)touchPoint {
    // 点击的位置
    CGPoint point = touchPoint;
    // 获取进度值 由于btn是从 0-(self.width - btn.width)
    float value = (point.x - btn.width * 0.5) / (self.width - btn.width);
    // value的值需在0-1之间
    value = value >= 1.0 ? 1.0 : value <= 0.0 ? 0.0 : value;
    if (self.value == value) return;
    self.isForward = self.value < value;
    [self setValue:value];
    if ([self.delegate respondsToSelector:@selector(sliderValueChanged:)]) {
        [self.delegate sliderValueChanged:value];
    }
}

- (void)tapped:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self];
    // 获取进度
    float value = (point.x - self.bgProgressView.left) * 1.0 / self.bgProgressView.width;
    value = value >= 1.0 ? 1.0 : value <= 0 ? 0 : value;
    [self setValue:value];
    if ([self.delegate respondsToSelector:@selector(sliderTapped:)]) {
        [self.delegate sliderTapped:value];
    }
}

#pragma mark - getter

- (UIView *)bgProgressView {
    if (!_bgProgressView) {
        _bgProgressView = [UIImageView new];
        _bgProgressView.backgroundColor = [UIColor grayColor];
        _bgProgressView.contentMode = UIViewContentModeScaleAspectFill;
        _bgProgressView.clipsToBounds = YES;
    }
    return _bgProgressView;
}

- (UIView *)bufferProgressView {
    if (!_bufferProgressView) {
        _bufferProgressView = [UIImageView new];
        _bufferProgressView.backgroundColor = [UIColor whiteColor];
        _bufferProgressView.contentMode = UIViewContentModeScaleAspectFill;
        _bufferProgressView.clipsToBounds = YES;
    }
    return _bufferProgressView;
}

- (UIView *)sliderProgressView {
    if (!_sliderProgressView) {
        _sliderProgressView = [UIImageView new];
        _sliderProgressView.backgroundColor = [UIColor redColor];
        _sliderProgressView.contentMode = UIViewContentModeScaleAspectFill;
        _sliderProgressView.clipsToBounds = YES;
    }
    return _sliderProgressView;
}

- (ZFSliderButton *)sliderBtn {
    if (!_sliderBtn) {
        _sliderBtn = [ZFSliderButton buttonWithType:UIButtonTypeCustom];
        [_sliderBtn setAdjustsImageWhenHighlighted:NO];
    }
    return _sliderBtn;
}

@end
