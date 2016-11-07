//
//  ASValueTrackingSlider.m
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

#import "ASValueTrackingSlider.h"

@interface ASValueTrackingSlider() <ASValuePopUpViewDelegate>
@property (strong, nonatomic) ASValuePopUpView *popUpView;
@property (nonatomic) BOOL popUpViewAlwaysOn; // default is NO
@end

@implementation ASValueTrackingSlider
{
    NSNumberFormatter *_numberFormatter;
    UIColor *_popUpViewColor;
    NSArray *_keyTimes;
    CGFloat _valueRange;
}

#pragma mark - initialization

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - public

- (void)setAutoAdjustTrackColor:(BOOL)autoAdjust
{
    if (_autoAdjustTrackColor == autoAdjust) return;
    
    _autoAdjustTrackColor = autoAdjust;
    
    // setMinimumTrackTintColor has been overridden to also set autoAdjustTrackColor to NO
    // therefore super's implementation must be called to set minimumTrackTintColor
    if (autoAdjust == NO) {
        super.minimumTrackTintColor = nil; // sets track to default blue color
    } else {
        super.minimumTrackTintColor = [self.popUpView opaqueColor];
    }
}

- (void)setText:(NSString *)text
{
    [self.popUpView setText:text];
}
- (void)setImage:(UIImage *)image
{
    [self.popUpView setImage:image];
}

// return the currently displayed color if possible, otherwise return _popUpViewColor
// if animated colors are set, the color will change each time the slider value changes
- (UIColor *)popUpViewColor
{
    return self.popUpView.color ?: _popUpViewColor;
}

- (void)setPopUpViewColor:(UIColor *)color
{
    _popUpViewColor = color;
    _popUpViewAnimatedColors = nil; // animated colors should be discarded
    [self.popUpView setColor:color];

    if (_autoAdjustTrackColor) {
        super.minimumTrackTintColor = [self.popUpView opaqueColor];
    }
}

- (void)setPopUpViewAnimatedColors:(NSArray *)colors
{
    [self setPopUpViewAnimatedColors:colors withPositions:nil];
}

// if 2 or more colors are present, set animated colors
// if only 1 color is present then call 'setPopUpViewColor:'
// if arg is nil then restore previous _popUpViewColor
- (void)setPopUpViewAnimatedColors:(NSArray *)colors withPositions:(NSArray *)positions
{
    if (positions) {
        NSAssert([colors count] == [positions count], @"popUpViewAnimatedColors and locations should contain the same number of items");
    }
    
    _popUpViewAnimatedColors = colors;
    _keyTimes = [self keyTimesFromSliderPositions:positions];
    
    if ([colors count] >= 2) {
        [self.popUpView setAnimatedColors:colors withKeyTimes:_keyTimes];
    } else {
        [self setPopUpViewColor:[colors lastObject] ?: _popUpViewColor];
    }
}

- (void)setPopUpViewCornerRadius:(CGFloat)radius
{
    self.popUpView.cornerRadius = radius;
}

- (CGFloat)popUpViewCornerRadius
{
    return self.popUpView.cornerRadius;
}

- (void)setPopUpViewArrowLength:(CGFloat)length
{
    self.popUpView.arrowLength = length;
}

- (CGFloat)popUpViewArrowLength
{
    return self.popUpView.arrowLength;
}

- (void)setPopUpViewWidthPaddingFactor:(CGFloat)factor
{
    self.popUpView.widthPaddingFactor = factor;
}

- (CGFloat)popUpViewWidthPaddingFactor
{
    return self.popUpView.widthPaddingFactor;
}

- (void)setPopUpViewHeightPaddingFactor:(CGFloat)factor
{
    self.popUpView.heightPaddingFactor = factor;
}

- (CGFloat)popUpViewHeightPaddingFactor
{
    return self.popUpView.heightPaddingFactor;
}

// when either the min/max value or number formatter changes, recalculate the popUpView width
- (void)setMaximumValue:(float)maximumValue
{
    [super setMaximumValue:maximumValue];
    _valueRange = self.maximumValue - self.minimumValue;
}

- (void)setMinimumValue:(float)minimumValue
{
    [super setMinimumValue:minimumValue];
    _valueRange = self.maximumValue - self.minimumValue;
}

- (void)showPopUpViewAnimated:(BOOL)animated
{
    self.popUpViewAlwaysOn = YES;
    [self _showPopUpViewAnimated:animated];
}

- (void)hidePopUpViewAnimated:(BOOL)animated
{
    self.popUpViewAlwaysOn = NO;
    [self _hidePopUpViewAnimated:animated];
}

#pragma mark - ASValuePopUpViewDelegate

- (void)colorDidUpdate:(UIColor *)opaqueColor
{
    super.minimumTrackTintColor = opaqueColor;
}

// returns the current offset of UISlider value in the range 0.0 – 1.0
- (CGFloat)currentValueOffset
{
    return (self.value - self.minimumValue) / _valueRange;
}

#pragma mark - private

- (void)setup
{
    _autoAdjustTrackColor = YES;
    _valueRange = self.maximumValue - self.minimumValue;
    _popUpViewAlwaysOn = NO;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    [formatter setMaximumFractionDigits:2];
    [formatter setMinimumFractionDigits:2];
    _numberFormatter = formatter;

    self.popUpView = [[ASValuePopUpView alloc] initWithFrame:CGRectZero];
    self.popUpViewColor = [UIColor colorWithHue:0.6 saturation:0.6 brightness:0.5 alpha:0.8];

    self.popUpView.alpha = 0.0;
    self.popUpView.delegate = self;
    [self addSubview:self.popUpView];

}

// ensure animation restarts if app is closed then becomes active again
- (void)didBecomeActiveNotification:(NSNotification *)note
{
    if (self.popUpViewAnimatedColors) {
        [self.popUpView setAnimatedColors:_popUpViewAnimatedColors withKeyTimes:_keyTimes];
    }
}

- (void)updatePopUpView
{
    CGSize popUpViewSize = CGSizeMake(100, 56 + self.popUpViewArrowLength + 18);
    
    // calculate the popUpView frame
    CGRect thumbRect = [self thumbRect];
    CGFloat thumbW = thumbRect.size.width;
    CGFloat thumbH = thumbRect.size.height;
    
    CGRect popUpRect = CGRectInset(thumbRect, (thumbW - popUpViewSize.width)/2, (thumbH - popUpViewSize.height)/2);
    popUpRect.origin.y = thumbRect.origin.y - popUpViewSize.height;
    
    // determine if popUpRect extends beyond the frame of the progress view
    // if so adjust frame and set the center offset of the PopUpView's arrow
    CGFloat minOffsetX = CGRectGetMinX(popUpRect);
    CGFloat maxOffsetX = CGRectGetMaxX(popUpRect) - CGRectGetWidth(self.bounds);
    
    CGFloat offset = minOffsetX < 0.0 ? minOffsetX : (maxOffsetX > 0.0 ? maxOffsetX : 0.0);
    popUpRect.origin.x -= offset;
    
    [self.popUpView setFrame:popUpRect arrowOffset:offset];
    
}

// takes an array of NSNumbers in the range self.minimumValue - self.maximumValue
// returns an array of NSNumbers in the range 0.0 - 1.0
- (NSArray *)keyTimesFromSliderPositions:(NSArray *)positions
{
    if (!positions) return nil;
    
    NSMutableArray *keyTimes = [NSMutableArray array];
    for (NSNumber *num in [positions sortedArrayUsingSelector:@selector(compare:)]) {
        [keyTimes addObject:@((num.floatValue - self.minimumValue) / _valueRange)];
    }
    return keyTimes;
}

- (CGRect)thumbRect
{
    return [self thumbRectForBounds:self.bounds
                          trackRect:[self trackRectForBounds:self.bounds]
                              value:self.value];
}

- (void)_showPopUpViewAnimated:(BOOL)animated
{
    if (self.delegate) [self.delegate sliderWillDisplayPopUpView:self];
    [self.popUpView showAnimated:animated];
}

- (void)_hidePopUpViewAnimated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(sliderWillHidePopUpView:)]) {
        [self.delegate sliderWillHidePopUpView:self];
    }
    [self.popUpView hideAnimated:animated completionBlock:^{
        if ([self.delegate respondsToSelector:@selector(sliderDidHidePopUpView:)]) {
            [self.delegate sliderDidHidePopUpView:self];
        }
    }];
}

#pragma mark - subclassed

-(void)layoutSubviews
{
    [super layoutSubviews];
    [self updatePopUpView];
}

- (void)didMoveToWindow
{
    if (!self.window) { // removed from window - cancel notifications
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    else { // added to window - register notifications
        
        if (self.popUpViewAnimatedColors) { // restart color animation if needed
            [self.popUpView setAnimatedColors:_popUpViewAnimatedColors withKeyTimes:_keyTimes];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActiveNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
}

- (void)setValue:(float)value
{
    [super setValue:value];
    [self.popUpView setAnimationOffset:[self currentValueOffset] returnColor:^(UIColor *opaqueReturnColor) {
        super.minimumTrackTintColor = opaqueReturnColor;
    }];
}

- (void)setValue:(float)value animated:(BOOL)animated
{
    if (animated) {
        [self.popUpView animateBlock:^(CFTimeInterval duration) {
            [UIView animateWithDuration:duration animations:^{
                [super setValue:value animated:animated];
                [self.popUpView setAnimationOffset:[self currentValueOffset] returnColor:^(UIColor *opaqueReturnColor) {
                    super.minimumTrackTintColor = opaqueReturnColor;
                }];
                [self layoutIfNeeded];
            }];
        }];
    } else {
        [super setValue:value animated:animated];
    }
}

- (void)setMinimumTrackTintColor:(UIColor *)color
{
    self.autoAdjustTrackColor = NO; // if a custom value is set then prevent auto coloring
    [super setMinimumTrackTintColor:color];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL begin = [super beginTrackingWithTouch:touch withEvent:event];
    if (begin && !self.popUpViewAlwaysOn) [self _showPopUpViewAnimated:NO];
    return begin;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL continueTrack = [super continueTrackingWithTouch:touch withEvent:event];
    if (continueTrack) {
        [self.popUpView setAnimationOffset:[self currentValueOffset] returnColor:^(UIColor *opaqueReturnColor) {
            super.minimumTrackTintColor = opaqueReturnColor;
        }];
    }
    return continueTrack;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [super cancelTrackingWithEvent:event];
    if (self.popUpViewAlwaysOn == NO) [self _hidePopUpViewAnimated:NO];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    if (self.popUpViewAlwaysOn == NO) [self _hidePopUpViewAnimated:NO];
}


@end
