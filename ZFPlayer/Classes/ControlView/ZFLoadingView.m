//
//  ZFLoadingView.m
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

#import "ZFLoadingView.h"

@interface ZFLoadingView ()

@property (nonatomic, strong, readonly) CAShapeLayer *shapeLayer;
@property (nonatomic, assign, getter=isAnimating) BOOL animating;
@property (nonatomic, assign) BOOL strokeShow;

@end

@implementation ZFLoadingView

@synthesize lineColor = _lineColor;
@synthesize shapeLayer = _shapeLayer;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialize];
}

- (void)initialize {
    [self.layer addSublayer:self.shapeLayer];
    self.duration = 1;
    self.lineWidth = 1;
    self.lineColor = [UIColor whiteColor];
    self.userInteractionEnabled = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = MIN(self.bounds.size.width, self.bounds.size.height);
    CGFloat height = width;
    self.shapeLayer.frame = CGRectMake(0, 0, width, height);
    
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = MIN(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2) - self.shapeLayer.lineWidth / 2;
    CGFloat startAngle = (CGFloat)(0);
    CGFloat endAngle = (CGFloat)(2*M_PI);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    self.shapeLayer.path = path.CGPath;
}

- (void)startAnimating {
    if (self.animating) return;
    self.animating = YES;
    if (self.animType == ZFLoadingTypeFadeOut) [self fadeOutShow];
    CABasicAnimation *rotationAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnim.toValue = [NSNumber numberWithFloat:2 * M_PI];
    rotationAnim.duration = self.duration;
    rotationAnim.repeatCount = CGFLOAT_MAX;
    rotationAnim.removedOnCompletion = NO;
    [self.shapeLayer addAnimation:rotationAnim forKey:@"rotation"];
    if (self.hidesWhenStopped) {
        self.hidden = NO;
    }
}

- (void)stopAnimating {
    if (!self.animating) return;
    self.animating = NO;
    [self.shapeLayer removeAllAnimations];
    if (self.hidesWhenStopped) {
        self.hidden = YES;
    }
}

- (void)fadeOutShow {
    CABasicAnimation *headAnimation = [CABasicAnimation animation];
    headAnimation.keyPath = @"strokeStart";
    headAnimation.duration = self.duration / 1.5f;
    headAnimation.fromValue = @(0.f);
    headAnimation.toValue = @(0.25f);
    
    CABasicAnimation *tailAnimation = [CABasicAnimation animation];
    tailAnimation.keyPath = @"strokeEnd";
    tailAnimation.duration = self.duration / 1.5f;
    tailAnimation.fromValue = @(0.f);
    tailAnimation.toValue = @(1.f);
    
    CABasicAnimation *endHeadAnimation = [CABasicAnimation animation];
    endHeadAnimation.keyPath = @"strokeStart";
    endHeadAnimation.beginTime = self.duration / 1.5f;
    endHeadAnimation.duration = self.duration / 3.0f;
    endHeadAnimation.fromValue = @(0.25f);
    endHeadAnimation.toValue = @(1.f);
    
    CABasicAnimation *endTailAnimation = [CABasicAnimation animation];
    endTailAnimation.keyPath = @"strokeEnd";
    endTailAnimation.beginTime = self.duration / 1.5f;
    endTailAnimation.duration = self.duration / 3.0f;
    endTailAnimation.fromValue = @(1.f);
    endTailAnimation.toValue = @(1.f);
    
    CAAnimationGroup *animations = [CAAnimationGroup animation];
    [animations setDuration:self.duration];
    [animations setAnimations:@[headAnimation, tailAnimation, endHeadAnimation, endTailAnimation]];
    animations.repeatCount = INFINITY;
    animations.removedOnCompletion = NO;
    [self.shapeLayer addAnimation:animations forKey:@"strokeAnim"];
    
    if (self.hidesWhenStopped) {
        self.hidden = NO;
    }
}

#pragma mark - setter and getter

- (CAShapeLayer *)shapeLayer {
    if (!_shapeLayer) {
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.strokeColor = self.lineColor.CGColor;
        _shapeLayer.fillColor = [UIColor clearColor].CGColor;
        _shapeLayer.strokeStart = 0.1;
        _shapeLayer.strokeEnd = 1;
        _shapeLayer.lineCap = @"round";
        _shapeLayer.anchorPoint = CGPointMake(0.5, 0.5);
    }
    return _shapeLayer;
}

- (UIColor *)lineColor {
    if (!_lineColor) {
        return [UIColor whiteColor];
    }
    return _lineColor;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    self.shapeLayer.lineWidth = lineWidth;
}

- (void)setLineColor:(UIColor *)lineColor {
    if (!lineColor) return;
    _lineColor = lineColor;
    self.shapeLayer.strokeColor = lineColor.CGColor;
}

- (void)setHidesWhenStopped:(BOOL)hidesWhenStopped {
    _hidesWhenStopped = hidesWhenStopped;
    self.hidden = !self.isAnimating && hidesWhenStopped;
}

@end
