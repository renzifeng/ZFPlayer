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
#import "ZFPlayerControlViewDelegate.h"

@protocol ZFPlayerDelegate <NSObject>
@optional
/** 返回按钮事件 */
- (void)zf_playerBackAction;
/** 下载视频 */
- (void)zf_playerDownload:(NSString *)url;
/** 控制层即将显示 */
- (void)zf_playerControlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen;
/** 控制层即将隐藏 */
- (void)zf_playerControlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen;

@end

// playerLayer的填充模式（默认：等比例填充，直到一个维度到达区域边界）
typedef NS_ENUM(NSInteger, ZFPlayerLayerGravity) {
     ZFPlayerLayerGravityResize,           // 非均匀模式。两个维度完全填充至整个视图区域
     ZFPlayerLayerGravityResizeAspect,     // 等比例填充，直到一个维度到达区域边界
     ZFPlayerLayerGravityResizeAspectFill  // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
};

// 播放器的几种状态
typedef NS_ENUM(NSInteger, ZFPlayerState) {
    ZFPlayerStateFailed,     // 播放失败
    ZFPlayerStateBuffering,  // 缓冲中
    ZFPlayerStatePlaying,    // 播放中
    ZFPlayerStateStopped,    // 停止播放
    ZFPlayerStatePause       // 暂停播放
};

@interface ZFPlayerView : UIView <ZFPlayerControlViewDelagate>

/** 设置playerLayer的填充模式 */
@property (nonatomic, assign) ZFPlayerLayerGravity    playerLayerGravity;
/** 是否有下载功能(默认是关闭) */
@property (nonatomic, assign) BOOL                    hasDownload;
/** 是否开启预览图 */
@property (nonatomic, assign) BOOL                    hasPreviewView;
/** 设置代理 */
@property (nonatomic, weak) id<ZFPlayerDelegate>      delegate;
/** 是否被用户暂停 */
@property (nonatomic, assign, readonly) BOOL          isPauseByUser;
/** 播发器的几种状态 */
@property (nonatomic, assign, readonly) ZFPlayerState state;
/** 静音（默认为NO）*/
@property (nonatomic, assign) BOOL                    mute;
/** 当cell划出屏幕的时候停止播放（默认为NO） */
@property (nonatomic, assign) BOOL                    stopPlayWhileCellNotVisable;
/** 当cell播放视频由全屏变为小屏时候，是否回到中间位置(默认YES) */
@property (nonatomic, assign) BOOL                    cellPlayerOnCenter;
/** player在栈上，即此时push或者模态了新控制器 */
@property (nonatomic, assign) BOOL                    playerPushedOrPresented;

/**
 *  单例，用于列表cell上多个视频
 *
 *  @return ZFPlayer
 */
+ (instancetype)sharedPlayerView;

/**
 * 指定播放的控制层和模型
 * 控制层传nil，默认使用ZFPlayerControlView(如自定义可传自定义的控制层)
 */
- (void)playerControlView:(UIView *)controlView playerModel:(ZFPlayerModel *)playerModel;

/**
 * 使用自带的控制层时候可使用此API
 */
- (void)playerModel:(ZFPlayerModel *)playerModel;

/**
 *  自动播放，默认不自动播放
 */
- (void)autoPlayTheVideo;

/**
 *  重置player
 */
- (void)resetPlayer;

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

@end
