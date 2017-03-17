<p align="center">
<img src="https://github.com/renzifeng/ZFPlayer/raw/master/log.png" alt="ZFPlayer" title="ZFPlayer" width="557"/>
</p>

<p align="center">
<a href="https://travis-ci.org/renzifeng/ZFPlayer"><img src="https://travis-ci.org/renzifeng/ZFPlayer.svg?branch=master"></a>
<a href="https://img.shields.io/cocoapods/v/ZFPlayer.svg"><img src="https://img.shields.io/cocoapods/v/ZFPlayer.svg"></a>
<a href="https://img.shields.io/cocoapods/v/ZFPlayer.svg"><img src="https://img.shields.io/github/license/renzifeng/ZFPlayer.svg?style=flat"></a>
<a href="http://cocoadocs.org/docsets/ZFPlayer"><img src="https://img.shields.io/cocoapods/p/ZFPlayer.svg?style=flat"></a>
<a href="http://weibo.com/zifeng1300"><img src="https://img.shields.io/badge/weibo-@%E4%BB%BB%E5%AD%90%E4%B8%B0-yellow.svg?style=flat"></a>
</p>

基于AVPlayer，支持竖屏、横屏（横屏可锁定屏幕方向），上下滑动调节音量、屏幕亮度，左右滑动调节播放进度

[ZFPlayer剖析](http://www.jianshu.com/p/5566077bb25f)&emsp;&emsp;[哪些app使用ZFPlayer](http://www.jianshu.com/p/5fa55a05f87b)

## 特性
- [x] 支持横、竖屏切换，在横屏模式下可以锁定屏幕方向
- [x] 支持本地视频、网络视频播放
- [x] 支持在TableviewCell播放视频
- [x] 左侧1/2位置上下滑动调节屏幕亮度（模拟器调不了亮度，请在真机调试）
- [x] 右侧1/2位置上下滑动调节音量（模拟器调不了音量，请在真机调试）
- [x] 左右滑动调节播放进度
- [x] 全屏状态下拖动slider控制进度，显示视频的预览图
- [x] 断点下载功能
- [x] 切换视频分辨率

## 要求

- iOS 7+
- Xcode 8+


## 统计

哪些APP使用ZFPlayer，并上架AppStore，请告诉我，帮助我统计。

## 组件

- 断点下载: [ZFDownload](https://github.com/renzifeng/ZFDownload)
- 导航: [ZFNavigationController](https://github.com/renzifeng/ZFNavigationController)（滑动返回页面时候视频播放不卡顿）
- 布局: Masonry


## 安装

### CocoaPods    

```ruby
pod 'ZFPlayer'
```

Then, run the following command:

```bash
$ pod install
```

## 使用 （支持IB和代码）
##### 设置状态栏颜色
请在info.plist中增加"View controller-based status bar appearance"字段，并改为NO

##### IB用法
直接拖UIView到IB上，View类改为`ZFPlayerView`

```objc
// 初始化控制层view(可自定义)
ZFPlayerControlView *controlView = [[ZFPlayerControlView alloc] init];
// 初始化播放模型
ZFPlayerModel *playerModel = [[ZFPlayerModel alloc] init];
// playerView的父视图
playerModel.fatherView = ...;
playerModel.videoURL = ...
playerModel.title = ...
[self.playerView playerControlView:controlView playerModel:playerModel];
// 设置代理
self.playerView.delegate = self;
// 自动播放
[self.playerView autoPlayTheVideo];
```

`ZFPlayerDelegate`

```
/** 返回按钮事件 */
- (void)zf_playerBackAction;
/** 下载视频 */
- (void)zf_playerDownload:(NSString *)url;
```

##### 代码实现（Masonry）用法

```objc
self.playerView = [[ZFPlayerView alloc] init];
[self.view addSubview:self.playerView];
[self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
 	make.top.equalTo(self.view).offset(20);
 	make.left.right.equalTo(self.view);
	// 这里宽高比16：9，可以自定义视频宽高比
	make.height.equalTo(self.playerView.mas_width).multipliedBy(9.0f/16.0f);
}];

// 初始化控制层view(可自定义)
ZFPlayerControlView *controlView = [[ZFPlayerControlView alloc] init];
// 初始化播放模型
ZFPlayerModel *playerModel = [[ZFPlayerModel alloc]init];
playerModel.videoURL = ...
playerModel.title = ...
[self.playerView playerControlView:controlView playerModel:playerModel];

// 设置代理
self.playerView.delegate = self;
// 自动播放
[self.playerView autoPlayTheVideo];
```

##### 设置视频的填充模式
```objc
 // 设置视频的填充模式，内部设置默认（ZFPlayerLayerGravityResizeAspect：等比例填充，直到一个维度到达区域边界）
 self.playerView.playerLayerGravity = ZFPlayerLayerGravityResizeAspect;
```

##### 是否有断点下载功能
```objc
 // 下载功能，如需要此功能设置这里
 self.playerView.hasDownload = YES;
```

##### 从xx秒开始播放视频
 ```objc
 // 从xx秒开始播放视频
 playerModel.seekTime = 15;
 ```
 
##### 是否自动播放，默认不自动播放
```objc
// 是否自动播放，默认不自动播放
[self.playerView autoPlayTheVideo];
```

##### 设置播放前的占位图

```objc
// 设置播放前视频占位图
// 如果网络图片和本地图片同时设置，则忽略本地图片，显示网络图片
ZFPlayerModel *playerModel = [[ZFPlayerModel alloc]init];
// 本地图片
playerModel.placeholderImage = [UIImage imageNamed: @"..."];
// 网络图片
playerModel.placeholderImageURLString = @"https://xxx.jpg";
self.playerView.playerModel = playerModel;

```

##### 自定义控制层
`self.playerView.controlView = 自定义的View;`

自定义view你需要实现以下方法，直接在`.m`中实现即可，可参考`ZFPlayerControlView.m`

```
/** 
 * 设置播放模型 
 */
- (void)zf_playerModel:(ZFPlayerModel *)playerModel;

/** 
 * 显示控制层
 */
- (void)zf_playerShowControlView;

/** 
 * 隐藏控制层
 */
- (void)zf_playerHideControlView;

/** 
 * 重置ControlView 
 */
- (void)zf_playerResetControlView;

/** 
 * 切换分辨率时重置ControlView 
 */
- (void)zf_playerResetControlViewForResolution;

/** 
 * 取消自动隐藏控制层view 
 */
- (void)zf_playerCancelAutoFadeOutControlView;

/** 
 * 开始播放（用来隐藏placeholderImageView）
 */
- (void)zf_playerItemPlaying;

/** 
 * 播放完了 
 */
- (void)zf_playerPlayEnd;

/** 
 * 是否有下载功能 
 */
- (void)zf_playerHasDownloadFunction:(BOOL)sender;

/**
 * 是否有切换分辨率功能
 @param resolutionArray 分辨率名称的数组
 */
- (void)zf_playerResolutionArray:(NSArray *)resolutionArray;

/** 
 * 播放按钮状态 (播放、暂停状态)
 */
- (void)zf_playerPlayBtnState:(BOOL)state;

/** 
 * 锁定屏幕方向按钮状态 
 */
- (void)zf_playerLockBtnState:(BOOL)state;

/**
 * 下载按钮状态
 */
- (void)zf_playerDownloadBtnState:(BOOL)state;

/** 
 * 加载的菊花
 */
- (void)zf_playerActivity:(BOOL)animated;

/**
 * 设置预览图

 * @param draggedTime 拖拽的时长
 * @param image       预览图
 */
- (void)zf_playerDraggedTime:(NSInteger)draggedTime sliderImage:(UIImage *)image;

/**
 拖拽快进 快退

 * @param draggedTime 拖拽的时长
 * @param totalTime   视频总时长
 * @param forawrd     是否是快进
 * @param preview     是否有预览图
 */
- (void)zf_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview;

/** 
 * 滑动调整进度结束结束 
 */
- (void)zf_playerDraggedEnd;

/**
 * 正常播放

 * @param currentTime 当前播放时长
 * @param totalTime   视频总时长
 * @param value       slider的value(0.0~1.0)
 */
- (void)zf_playerCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value;

/** 
 * progress显示缓冲进度 
 */
- (void)zf_playerSetProgress:(CGFloat)progress;

/** 
 * 视频加载失败 
 */
- (void)zf_playerItemStatusFailed:(NSError *)error;

/**
 * 小屏播放
 */
- (void)zf_playerBottomShrinkPlay;

/**
 * 在cell播放
 */
- (void)zf_playerCellPlay;
```

### 图片效果演示

![图片效果演示](https://github.com/renzifeng/ZFPlayer/raw/master/screen.gif)

![声音调节演示](https://github.com/renzifeng/ZFPlayer/raw/master/volume.png)

![亮度调节演示](https://github.com/renzifeng/ZFPlayer/raw/master/brightness.png)

![快进快退演示](https://github.com/renzifeng/ZFPlayer/raw/master/fast.png)

![进度调节预览图](https://github.com/renzifeng/ZFPlayer/raw/master/progress.png)

### 参考链接：

- [https://segmentfault.com/a/1190000004054258](https://segmentfault.com/a/1190000004054258)
- [http://sky-weihao.github.io/2015/10/06/Video-streaming-and-caching-in-iOS/](http://sky-weihao.github.io/2015/10/06/Video-streaming-and-caching-in-iOS/)
- [https://developer.apple.com/library/prerelease/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/02_Playback.html#//apple_ref/doc/uid/TP40010188-CH3-SW8](https://developer.apple.com/library/prerelease/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/02_Playback.html#//apple_ref/doc/uid/TP40010188-CH3-SW8)

---
### Swift版Player：
请移步 [BMPlayer](https://github.com/BrikerMan/BMPlayer)，感谢 BMPlayer 作者的开源。

---

# 联系我
- 微博: [@任子丰](https://weibo.com/zifeng1300)
- 邮箱: zifeng1300@gmail.com
- QQ：459643690
- QQ群：213376937（已满） 213375947（添加这个）

# 广告时间

有不错的iOS职位可以联系我，坐标北京，谢谢！！

# License

ZFPlayer is available under the MIT license. See the LICENSE file for more info.

