//
//  ZFPlayerModel.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ZFPlayerModel : NSObject

/** 视频标题 */
@property (nonatomic, copy  ) NSString     *title;
/** 视频URL */
@property (nonatomic, strong) NSURL        *videoURL;
/** 视频封面本地图片 */
@property (nonatomic, strong) UIImage      *placeholderImage;
/** 播放器View的父视图（非cell播放使用这个）*/
@property (nonatomic, weak  ) UIView       *fatherView;

/**
 * 视频封面网络图片url
 * 如果和本地图片同时设置，则忽略本地图片，显示网络图片
 */
@property (nonatomic, copy  ) NSString     *placeholderImageURLString;
/**
 * 视频分辨率字典, 分辨率标题与该分辨率对应的视频URL.
 * 例如: @{@"高清" : @"https://xx/xx-hd.mp4", @"标清" : @"https://xx/xx-sd.mp4"}
 */
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *resolutionDic;
/** 从xx秒开始播放视频(默认0) */
@property (nonatomic, assign) NSInteger    seekTime;
// cell播放视频，以下属性必须设置值
@property (nonatomic, strong) UIScrollView *scrollView;
/** cell所在的indexPath */
@property (nonatomic, strong) NSIndexPath  *indexPath;
/** 
 * cell上播放必须指定
 * 播放器View的父视图tag（根据tag值在cell里查找playerView加到哪里)
 */
@property (nonatomic, assign) NSInteger    fatherViewTag;

@end
