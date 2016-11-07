//
//  ZFPlayerView.h
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
#import "ZFPlayer.h"
#import "ZFPlayerControlView.h"
#import "ZFPlayerModel.h"

@protocol ZFPlayerDelegate <NSObject>
@optional
/** 返回按钮事件 */
- (void)zf_playerBackAction;
/** 下载视频 */
- (void)zf_playerDownload:(NSString *)url;

@end

// 返回按钮的block
typedef void(^ZFPlayerBackCallBack)(void);
// 下载按钮的回调
typedef void(^ZFDownloadCallBack)(NSString *urlStr);

// playerLayer的填充模式（默认：等比例填充，直到一个维度到达区域边界）
typedef NS_ENUM(NSInteger, ZFPlayerLayerGravity) {
     ZFPlayerLayerGravityResize,           // 非均匀模式。两个维度完全填充至整个视图区域
     ZFPlayerLayerGravityResizeAspect,     // 等比例填充，直到一个维度到达区域边界
     ZFPlayerLayerGravityResizeAspectFill  // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
};

@interface ZFPlayerView : UIView <ZFPlayerControlViewDelagate>

/** 视频model */
@property (nonatomic, strong) ZFPlayerModel        *playerModel;
/** 设置playerLayer的填充模式 */
@property (nonatomic, assign) ZFPlayerLayerGravity playerLayerGravity;
/** 是否有下载功能(默认是关闭) */
@property (nonatomic, assign) BOOL                 hasDownload;
/** 是否开启预览图 */
@property (nonatomic, assign) BOOL                 hasPreviewView;
/** 控制层View */
@property (nonatomic, strong) UIView               *controlView;
/** 设置代理 */
@property (nonatomic, weak) id<ZFPlayerDelegate>   delegate;
/** 是否被用户暂停 */
@property (nonatomic, assign, readonly) BOOL       isPauseByUser;

/** 从xx秒开始播放视频 */
@property (nonatomic, assign) NSInteger            seekTime __deprecated_msg("Please use 'ZFPlayerModel.seekTime' instead");;
/** 视频URL */
@property (nonatomic, strong) NSURL                *videoURL __deprecated_msg("Please use 'ZFPlayerModel.videoURL' instead");
/** 视频标题 */
@property (nonatomic, strong) NSString             *title __deprecated_msg("Please use 'ZFPlayerModel.title' instead");
/** 切换分辨率传的字典(key:分辨率名称，value：分辨率url) */
@property (nonatomic, strong) NSDictionary         *resolutionDic __deprecated_msg("Please use 'ZFPlayerModel.resolutionDic' instead");
/** 播放前占位图片，不设置就显示默认占位图（需要在设置视频URL之前设置） */
@property (nonatomic, copy  ) UIImage              *placeholderImage __deprecated_msg("Please use 'ZFPlayerModel.placeholderImage' instead");
@property (nonatomic, copy  ) ZFPlayerBackCallBack goBackBlock __deprecated_msg("Please use ZFPlayerDelegate 'zf_playerBackAction' instead");
@property (nonatomic, copy  ) ZFDownloadCallBack   downloadBlock __deprecated_msg("Please use ZFPlayerDelegate 'zf_playerDownload:' instead");
@property (nonatomic, copy  ) NSString             *placeholderImageName __deprecated_msg("Please use 'ZFPlayerModel.placeholderImage' instead");

/**
 *  自动播放，默认不自动播放
 */
- (void)autoPlayTheVideo; 

/**
 *  单例，用于列表cell上多个视频
 *
 *  @return ZFPlayer
 */
+ (instancetype)sharedPlayerView;

/**
 *  player添加到cell上
 *
 *  @param cell 添加player的cellImageView
 */
- (void)addPlayerToCellImageView:(UIImageView *)imageView;

/**
 *  重置player
 */
- (void)resetPlayer;

/**
 *  在当前页面，设置新的Player的URL调用此方法
 */
- (void)resetToPlayNewURL __deprecated_msg("Please use 'resetToPlayNewVideo:' instead");

/**
 *  在当前页面，设置新的视频时候调用此方法
 */
- (void)resetToPlayNewVideo:(ZFPlayerModel *)playerModel;

/** 
 *  播放
 */
- (void)play;

/** 
  * 暂停 
 */
- (void)pause;

/** 设置URL的setter方法 */
- (void)setVideoURL:(NSURL *)videoURL;

/**
 *  用于cell上播放player
 *
 *  @param videoURL  视频的URL
 *  @param tableView tableView
 *  @param indexPath indexPath 
 *  @param ImageViewTag ImageViewTag
 */
- (void)setVideoURL:(NSURL *)videoURL
      withTableView:(UITableView *)tableView
        AtIndexPath:(NSIndexPath *)indexPath
   withImageViewTag:(NSInteger)tag  __deprecated_msg("Please use 'ZFPlayerModel' instead");


@end
