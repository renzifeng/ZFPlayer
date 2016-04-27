//
//  ZFDownloadingCell.m
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

#import "ZFDownloadingCell.h"

@interface ZFDownloadingCell ()
@property (nonatomic, assign) BOOL hasDownloadAnimation;
@end

@implementation ZFDownloadingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.downloadBtn.clipsToBounds = true;
    [self.downloadBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.downloadBtn setTitle:@"🕘" forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/**
 *  添加下载的动画
 */
- (void)addDownloadAnimation {
    if(self.downloadBtn && !self.hasDownloadAnimation){
        self.hasDownloadAnimation = YES;
        //1.创建关键帧动画并设置动画属性
        CAKeyframeAnimation *keyframeAnimation=[CAKeyframeAnimation animationWithKeyPath:@"position"];
        
        //2.设置关键帧
        NSValue *key1 = [NSValue valueWithCGPoint:CGPointMake(self.downloadBtn.center.x, self.downloadBtn.frame.origin.y)];//对于关键帧动画初始值不能省略
        NSValue *key2 = [NSValue valueWithCGPoint:CGPointMake(self.downloadBtn.center.x, self.downloadBtn.frame.size.height+self.downloadBtn.frame.origin.y)];
        NSArray *values = @[key1,key2];
        keyframeAnimation.values = values;
        //设置其他属性
        keyframeAnimation.duration = 1.2;
        keyframeAnimation.repeatCount = MAXFLOAT;
        
        //3.添加动画到图层，添加动画后就会执行动画
        [self.downloadBtn.layer addAnimation:keyframeAnimation forKey:@"downloadBtn"];
        [self.downloadBtn setTitle:@"↓" forState:UIControlStateNormal];
    }
}

/**
 *  移除下载button的动画
 */
- (void)removeDownloadAnimtion {
    self.hasDownloadAnimation = NO;
    [self.downloadBtn.layer removeAnimationForKey:@"downloadBtn"];
    [self.downloadBtn setTitle:@"🕘" forState:UIControlStateNormal];
}

/**
 *  暂停、下载
 *
 *  @param sender UIButton
 */
- (IBAction)clickDownload:(UIButton *)sender {
    if (self.downloadBlock) {
        self.downloadBlock();
    }
}

/**
 *  model setter
 *
 *  @param sessionModel sessionModel 
 */
- (void)setSessionModel:(ZFSessionModel *)sessionModel
{
    _sessionModel = sessionModel;
    self.fileNameLabel.text = sessionModel.fileName;
    NSUInteger receivedSize = ZFDownloadLength(sessionModel.url);
    NSString *writtenSize = [NSString stringWithFormat:@"%.2f %@",
                                                     [sessionModel calculateFileSizeInUnit:(unsigned long long)receivedSize],
                                                     [sessionModel calculateUnit:(unsigned long long)receivedSize]];
    CGFloat progress = 1.0 * receivedSize / sessionModel.totalLength;
    self.progressLabel.text = [NSString stringWithFormat:@"%@/%@ (%.2f%%)",writtenSize,sessionModel.totalSize,progress*100];
    self.progress.progress = progress;
    self.speedLabel.text = @"已暂停";
}


@end
