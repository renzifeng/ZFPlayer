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

A simple video player for iOS, based on AVPlayer. Support the vertical, horizontal screen(lock screen direction). Support adjust volume, brigtness and video progress.


[中文说明](https://github.com/renzifeng/ZFPlayer/blob/master/README.zh.md)&emsp;&emsp;[ZFPlayer剖析](http://www.jianshu.com/p/5566077bb25f)&emsp;&emsp;[哪些app使用ZFPlayer](http://www.jianshu.com/p/5fa55a05f87b)

## Features
- [x] Support for horizontal and vertical play mode, in horizontal mode can also lock the screen direction
- [x] Support play with online URL and local file
- [x] Support in TableviewCell playing video
- [x] Adjust brightness by slide vertical at left side of screen
- [x] Adjust volume by slide vertical at right side of screen
- [x] Slide horizontal to fast forward and rewind
- [x] Full screen mode to drag the slider control progress, display video preview
- [x] Download 
- [x] Toggle video resolution

## Requirements

- iOS 7+
- Xcode 8+


## Statistics

What App using ZFPlayer, and on AppStore, please tell me, help me to statistics.

## Component

- Breakpoint Download: [ZFDownload](https://github.com/renzifeng/ZFDownload)
- ZFNavigationController: [ZFNavigationController](https://github.com/renzifeng/ZFNavigationController)
- Layout: Masonry

## Installation

### CocoaPods    

```ruby
pod 'ZFPlayer'
```

Then, run the following command:

```bash
$ pod install
```

## Usage （Support IB and code）
##### Set status bar color
Please add the "View controller-based status bar appearance" field in info.plist and change it to NO

##### IB usage
Drag IB to UIView,the View class `ZFPlayerView` instead
```objc
// view
ZFPlayerControlView *controlView = [[ZFPlayerControlView alloc] init];
// model
ZFPlayerModel *playerModel = [[ZFPlayerModel alloc] init];
playerModel.fatherView = ...
playerModel.videoURL = ...
playerModel.title = ...
[self.playerView playerControlView:controlView playerModel:playerModel];
// delegate
self.playerView.delegate = self;
// auto play the video
[self.playerView autoPlayTheVideo];
```

`ZFPlayerDelegate`

```
/** backBtn event */
- (void)zf_playerBackAction;
/** downloadBtn event */
- (void)zf_playerDownload:(NSString *)url;
```

##### Code implementation (Masonry) usage

```objc
self.playerView = [[ZFPlayerView alloc] init];
[self.view addSubview:self.playerView];
[self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
 	make.top.equalTo(self.view).offset(20);
 	make.left.right.equalTo(self.view);
	// Here a 16:9 aspect ratio, can customize the video aspect ratio
    make.height.equalTo(self.playerView.mas_width).multipliedBy(9.0f/16.0f);
}];
// control view（you can custom）
ZFPlayerControlView *controlView = [[ZFPlayerControlView alloc] init];
// model
ZFPlayerModel *playerModel = [[ZFPlayerModel alloc]init];
playerModel.fatherView = ...
playerModel.videoURL = ...
playerModel.title = ...
[self.playerView playerControlView:controlView playerModel:playerModel];

// delegate
self.playerView.delegate = self;
// auto play the video
[self.playerView autoPlayTheVideo];
```

##### Set the fill mode for the video

```objc
 // Set the fill mode of the video, the default settings (ZFPlayerLayerGravityResizeAspect: wait for a proportional fill, until a dimension reaches the area boundary).
 self.playerView.playerLayerGravity = ZFPlayerLayerGravityResizeAspect;
```
##### Is there a breakpoint download function
```objc
 // Default is to close the breakpoint download function, such as the need for this feature set here
 self.playerView.hasDownload = YES;
```

##### Play video from XX seconds

 ```objc
 // Play video from XX seconds
 playerModel.seekTime = 15;
 ```

##### Automatically play the video，not automatically play by default
```objc
// Automatically play the video
[self.playerView autoPlayTheVideo];
```

##### Set the video placeholderImage 

```objc
//  The video placeholder image
// If network image and local image set at the same time, ignore the local image, display the network images
ZFPlayerModel *playerModel = [[ZFPlayerModel alloc]init];
// local image
playerModel.placeholderImage = [UIImage imageNamed: @"..."];
// network image
playerModel.placeholderImageURLString = @"https://xxx.jpg";
self.playerView.playerModel = playerModel;
```

##### Custom control layer
`self.playerView.controlView = your customView;`

custom view you need to implement the following method in `.m`, you can reference`ZFPlayerControlView.m`

```
/** 
 * Set playaer model 
 */
- (void)zf_playerModel:(ZFPlayerModel *)playerModel;

/** 
 * Show controlView
 */
- (void)zf_playerShowControlView;

/** 
 * Hide controlView
 */
- (void)zf_playerHideControlView;

/** 
 * Reset controlView 
 */
- (void)zf_playerResetControlView;

/** 
 * Reset controlView for resolution
 */
- (void)zf_playerResetControlViewForResolution;

/** 
 * Cancel auto fadeout controlView 
 */
- (void)zf_playerCancelAutoFadeOutControlView;

/** 
 * Begin to play
 */
- (void)zf_playerItemPlaying;

/** 
 * Play end 
 */
- (void)zf_playerPlayEnd;

/** 
 * Has download function
 */
- (void)zf_playerHasDownloadFunction:(BOOL)sender;

/**
 * Resolution function
 */
- (void)zf_playerResolutionArray:(NSArray *)resolutionArray;

/** 
 * PlayBtn state (play or pause)
 */
- (void)zf_playerPlayBtnState:(BOOL)state;

/** 
 * LockBtn state 
 */
- (void)zf_playerLockBtnState:(BOOL)state;

/**
 * DownloadBtn state
 */
- (void)zf_playerDownloadBtnState:(BOOL)state;

/** 
 * Player activity
 */
- (void)zf_playerActivity:(BOOL)animated;

/**
 * Set preview View
 */
- (void)zf_playerDraggedTime:(NSInteger)draggedTime sliderImage:(UIImage *)image;

/**
 * Dragged to control video progress
 
 * @param draggedTime Dragged time for video
 * @param totalTime   Total time for video
 * @param forawrd     Whether fast forward
 * @param preview     Is there a preview
 */
- (void)zf_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview;

/** 
 * Dragged end
 */
- (void)zf_playerDraggedEnd;

/**
 * Normal play

 * @param currentTime Current time for video
 * @param totalTime   Total Time for video
 * @param value       Slider value(0.0~1.0)
 */
- (void)zf_playerCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value;

/** 
 * Progress display buffer
 */
- (void)zf_playerSetProgress:(CGFloat)progress;

/** 
 * Video load failure 
 */
- (void)zf_playerItemStatusFailed:(NSError *)error;

/**
 * Bottom shrink play
 */
- (void)zf_playerBottomShrinkPlay;

/**
 * play on cell
 */
- (void)zf_playerCellPlay;
```

### Picture demonstration

![Picture effect](https://github.com/renzifeng/ZFPlayer/raw/master/screen.gif)

![Sound adjustment demonstration](https://github.com/renzifeng/ZFPlayer/raw/master/volume.png)

![Brightness adjustment demonstration](https://github.com/renzifeng/ZFPlayer/raw/master/brightness.png)

![Fast adjustment demonstration](https://github.com/renzifeng/ZFPlayer/raw/master/fast.png)

![Progress adjustment demonstration](https://github.com/renzifeng/ZFPlayer/raw/master/progress.png)


### Reference link：

- [https://segmentfault.com/a/1190000004054258](https://segmentfault.com/a/1190000004054258)
- [http://sky-weihao.github.io/2015/10/06/Video-streaming-and-caching-in-iOS/](http://sky-weihao.github.io/2015/10/06/Video-streaming-and-caching-in-iOS/)
- [https://developer.apple.com/library/prerelease/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/02_Playback.html#//apple_ref/doc/uid/TP40010188-CH3-SW8](https://developer.apple.com/library/prerelease/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/02_Playback.html#//apple_ref/doc/uid/TP40010188-CH3-SW8)

---
### Swift Player:
See the [BMPlayer](https://github.com/BrikerMan/BMPlayer) please, thanks the BMPlayer author's open source.

---

# Contact me
- Weibo: [@任子丰](https://weibo.com/zifeng1300)
- Email:  zifeng1300@gmail.com
- QQ：459643690
- QQ Group: 213376937（full） 213375947（add this）

# License

ZFPlayer is available under the MIT license. See the LICENSE file for more info.

