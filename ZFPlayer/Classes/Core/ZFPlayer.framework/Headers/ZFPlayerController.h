//
//  ZFPlayer.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZFPlayerMediaPlayback.h"
#import "ZFOrientationObserver.h"
#import "ZFPlayerMediaControl.h"
#import "ZFPlayerGestureControl.h"
#import "ZFFloatView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZFPlayerController : NSObject

/// The video contrainerView in normal model.
@property (nonatomic, strong) UIView *containerView;

/// The currentPlayerManager must conform `ZFPlayerMediaPlayback` protocol.
@property (nonatomic, strong) id<ZFPlayerMediaPlayback> currentPlayerManager;

/// The custom controlView must conform `ZFPlayerMediaControl` protocol.
@property (nonatomic, strong) UIView<ZFPlayerMediaControl> *controlView;

/*!
 @method            playerWithPlayerManager:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerView to see the video frames must set the contrainerView.
 @result            An instance of ZFPlayerController.
 */
+ (instancetype)playerWithPlayerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

/*!
 @method            playerWithPlayerManager:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerView to see the video frames must set the contrainerView.
 @result            An instance of ZFPlayerController.
 */
- (instancetype)initWithPlayerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

/*!
 @method            playerWithScrollView:playerManager:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item. Use in `tableView` or `collectionView`.
 @param             scrollView is `tableView` or `collectionView`.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerViewTag to see the video at scrollView must set the contrainerViewTag.
 @result            An instance of ZFPlayerController.
 */
+ (instancetype)playerWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag;

/*!
 @method            playerWithScrollView:playerManager:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item. Use in `tableView` or `collectionView`.
 @param             scrollView is `tableView` or `collectionView`.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerViewTag to see the video at scrollView must set the contrainerViewTag.
 @result            An instance of ZFPlayerController.
 */
- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag;

- (void)updateScrollViewPlayerToCell;

- (void)updateNoramlPlayerWithContainerView:(UIView *)containerView;

@end

@interface ZFPlayerController (ZFPlayerTimeControl)

/// The player current play time.
@property (nonatomic, readonly) NSTimeInterval currentTime;

/// The player total time.
@property (nonatomic, readonly) NSTimeInterval totalTime;

/// The player buffer time.
@property (nonatomic, readonly) NSTimeInterval bufferTime;

/// The player progress, 0...1
@property (nonatomic, readonly) float progress;

/// The player bufferProgress, 0...1
@property (nonatomic, readonly) float bufferProgress;

/// Use this method to seek to a specified time for the current player and to be notified when the seek operation is complete.
- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler;

@end

@interface ZFPlayerController (ZFPlayerPlaybackControl)

/// 0...1.0
/// Only affects audio volume for the device instance and not for the player.
/// You can change device volume or player volume as needed,change the player volume you can conform the `ZFPlayerMediaPlayback` protocol.
@property (nonatomic) float volume;

/// The device muted.
/// Only affects audio muting for the device instance and not for the player.
/// You can change device mute or player mute as needed,change the player mute you can conform the `ZFPlayerMediaPlayback` protocol.
@property (nonatomic, getter=isMuted) BOOL muted;

// 0...1.0, where 1.0 is maximum brightness. Only supported by main screen.
@property (nonatomic) float brightness;

/// The play asset URL.
@property (nonatomic) NSURL *assetURL;

/// if tableView or collectionView has only one section , use sectionAssetURLs.
/// if normal model set this can use `playTheNext` `playThePrevious` `playTheIndex:`.
@property (nonatomic, copy, nullable) NSArray <NSURL *>*assetURLs;

/// The currently playing index,limited to one-dimensional arrays.
@property (nonatomic) NSInteger currentPlayIndex;

/// is the last asset URL in `assetURLs`.
@property (nonatomic, readonly) BOOL isLastAssetURL;

/// is the first asset URL in `assetURLs`.
@property (nonatomic, readonly) BOOL isFirstAssetURL;

/// If Yes, player will be called pause method When Received `UIApplicationWillResignActiveNotification` notification.
/// default is YES.
@property (nonatomic) BOOL pauseWhenAppResignActive;

/// When the player is playing, it is paused by some event,not by user click to pause
/// For example, when the player is playing, application goes into the background or pushes to another viewController
@property (nonatomic, getter=isPauseByEvent) BOOL pauseByEvent;

/// The current player controller is disappear, not dealloc
@property (nonatomic, getter=isViewControllerDisappear) BOOL viewControllerDisappear;

/// The block invoked when the player is Prepare to play.
@property (nonatomic, copy, nullable) void(^playerPrepareToPlay)(id<ZFPlayerMediaPlayback> asset, NSURL *assetURL);

/// The block invoked when the player is Ready to play.
@property (nonatomic, copy, nullable) void(^playerReadyToPlay)(id<ZFPlayerMediaPlayback> asset, NSURL *assetURL);

/// The block invoked when the player play progress changed.
@property (nonatomic, copy, nullable) void(^playerPlayTimeChanged)(id<ZFPlayerMediaPlayback> asset, NSTimeInterval currentTime, NSTimeInterval duration);

/// The block invoked when the player play buffer changed.
@property (nonatomic, copy, nullable) void(^playerBufferTimeChanged)(id<ZFPlayerMediaPlayback> asset, NSTimeInterval bufferTime);

/// The block invoked when the player playback state changed.
@property (nonatomic, copy, nullable) void(^playerPlayStateChanged)(id<ZFPlayerMediaPlayback> asset, ZFPlayerPlaybackState playState);

/// The block invoked when the player load state changed.
@property (nonatomic, copy, nullable) void(^playerLoadStateChanged)(id<ZFPlayerMediaPlayback> asset, ZFPlayerLoadState loadState);

/// The block invoked when the player play failed.
@property (nonatomic, copy, nullable) void(^playerPlayFailed)(id<ZFPlayerMediaPlayback> asset, id error);

/// The block invoked when the player play end.
@property (nonatomic, copy, nullable) void(^playerDidToEnd)(id<ZFPlayerMediaPlayback> asset);

/// Play the next url ,while the `assetURLs` is not NULL.
- (void)playTheNext;

/// Play the previous url ,while the `assetURLs` is not NULL.
- (void)playThePrevious;

/// Play the index of url ,while the `assetURLs` is not NULL.
- (void)playTheIndex:(NSInteger)index;

/// Player stop and playerView remove from super view,remove other notification.
- (void)stop;

/*!
 @method           replaceCurrentPlayerManager:
 @abstract         Replaces the player's current playeranager with the specified player item.
 @param            manager must conform `ZFPlayerMediaPlayback` protocol
 @discussion       The playerManager that will become the player's current playeranager.
 */
- (void)replaceCurrentPlayerManager:(id<ZFPlayerMediaPlayback>)manager;

@end

@interface ZFPlayerController (ZFPlayerOrientationRotation)

@property (nonatomic, readonly) ZFOrientationObserver *orientationObserver;

/// Whether automatic screen rotation is supported.
/// iOS8.1~iOS8.3 the value is YES, other iOS version the value is NO.
/// This property is used for the return value of UIViewController `shouldAutorotate` method.
@property (nonatomic, readonly) BOOL shouldAutorotate;

/// Whether allow the video orientation rotate.
/// default is YES.
@property (nonatomic) BOOL allowOrentitaionRotation;

/// When ZFFullScreenMode is ZFFullScreenModeLandscape the orientation is LandscapeLeft or LandscapeRight, this value is YES.
/// When ZFFullScreenMode is ZFFullScreenModePortrait, while the player fullSceen this value is YES.
@property (nonatomic, readonly) BOOL isFullScreen;

/// Lock the screen orientation.
@property (nonatomic, getter=isLockedScreen) BOOL lockedScreen;

/// The statusbar hidden.
@property (nonatomic, getter=isStatusBarHidden) BOOL statusBarHidden;

/// The current orientation of the player.
/// Default is UIInterfaceOrientationPortrait.
@property (nonatomic, readonly) UIInterfaceOrientation currentOrientation;

/// The block invoked When player will rotate.
@property (nonatomic, copy, nullable) void(^orientationWillChange)(ZFPlayerController *player, BOOL isFullScreen);

/// The block invoked when player rotated.
@property (nonatomic, copy, nullable) void(^orientationDidChanged)(ZFPlayerController *player, BOOL isFullScreen);

/// Add the device orientation observer.
- (void)addDeviceOrientationObserver;

/// Remove the device orientation observer.
- (void)removeDeviceOrientationObserver;

/// Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModeLandscape.
- (void)enterLandscapeFullScreen:(UIInterfaceOrientation)orientation animated:(BOOL)animated;

/// Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModePortrait.
- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

// FullScreen mode is determined by ZFFullScreenMode
- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

@end

@interface ZFPlayerController (ZFPlayerViewGesture)

/// An instance of ZFPlayerGestureControl.
@property (nonatomic, readonly) ZFPlayerGestureControl *gestureControl;

/// The gesture types that the player not support.
@property (nonatomic, assign) ZFPlayerDisableGestureTypes disableGestureTypes;

@end

@interface ZFPlayerController (ZFPlayerScrollView)

/// The scroll view is `tableView` or `collectionView`.
@property (nonatomic, readonly, nullable) UIScrollView *scrollView;

/// The scrollView player should auto player, default is YES.
@property (nonatomic) BOOL shouldAutoPlay;

/// WWAN network auto play, only support in scrollView mode when the `shouldAutoPlay` is YES.
/// default is NO.
@property (nonatomic, getter=isWWANAutoPlay) BOOL WWANAutoPlay;

/// The current playing cell has out off the screen, the player add the small container view.
@property (nonatomic, readonly, nullable) ZFFloatView *smallFloatView;

/// Whether the small window is displayed.
@property (nonatomic, readonly) BOOL isSmallFloatViewShow;

/// The indexPath is playing.
@property (nonatomic, readonly, nullable) NSIndexPath *playingIndexPath;

/// The view tag that the player display in scrollView.
@property (nonatomic, readonly) NSInteger containerViewTag;

/// The current playing cell stop playing when the cell has out off the screen，defalut is YES.
@property (nonatomic) BOOL stopWhileNotVisible;

/// The current player scroll slides off the screen percent.
/// the property used when the `stopWhileNotVisible` is YES, the current playing player stop percent.
/// the property used when the `stopWhileNotVisible` is NO, the current playing player add to small container view percent.
/// 0.0~1.0, defalut is 0.5.
/// 0.0 is the player will disappear.
/// 1.0 is the player did disappear.
@property (nonatomic) CGFloat playerDisapperaPercent;

/// The current player scroll to the screen percent.
/// the property is only used when the `stopWhileNotVisible` is NO.
/// 0.0~1.0, defalut is 0.0.
/// 0.0 is the player will appear.
/// 1.0 is the player did appear.
@property (nonatomic) CGFloat playerApperaPercent;

/// if tableView or collectionView has more section, use sectionAssetURLs.
@property (nonatomic, copy, nullable) NSArray <NSArray <NSURL *>*>*sectionAssetURLs;

/// The block invoked When the player appearing.
@property (nonatomic, copy, nullable) void(^zf_playerAppearingInScrollView)(NSIndexPath *indexPath, CGFloat playerApperaPercent);

/// The block invoked When the player disappearing.
@property (nonatomic, copy, nullable) void(^zf_playerDisappearingInScrollView)(NSIndexPath *indexPath, CGFloat playerDisapperaPercent);

/// The block invoked When the player will appeared.
@property (nonatomic, copy, nullable) void(^zf_playerWillAppearInScrollView)(NSIndexPath *indexPath);

/// The block invoked When the player did appeared.
@property (nonatomic, copy, nullable) void(^zf_playerDidAppearInScrollView)(NSIndexPath *indexPath);

/// The block invoked When the player will disappear.
@property (nonatomic, copy, nullable) void(^zf_playerWillDisappearInScrollView)(NSIndexPath *indexPath);

/// The block invoked When the player did disappeared.
@property (nonatomic, copy, nullable) void(^zf_playerDidDisappearInScrollView)(NSIndexPath *indexPath);

/// stop the current playing video on cell.
- (void)stopCurrentPlayingCell;

/// Play the indexPath of url, while the `assetURLs` or `sectionAssetURLs` is not NULL.
/// `scrollToTop` scroll the current cell to top with animations.
- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop;

/// Play the indexPath with assetURL.
/// `assetURL` is the player URL.
/// `scrollToTop` scroll the current cell to top with animations.
- (void)playTheIndexPath:(NSIndexPath *)indexPath assetURL:(NSURL *)assetURL scrollToTop:(BOOL)scrollToTop;

/// Play the indexPath of url ,while the `assetURLs` or `sectionAssetURLs` is not NULL.
/// `scrollToTop` scroll the current cell to top with animations.
/// Scroll completion callback.
- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop completionHandler:(void (^ __nullable)(void))completionHandler;

@end

NS_ASSUME_NONNULL_END
