//
//  ZFPlayerView.m
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

#import "ZFPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Masonry/Masonry.h>
#import <XXNibBridge/XXNibBridge.h>
#import "ZFPlayerMaskView.h"
#import "AppDelegate.h"

#define iPhone4s ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
#define ApplicationDelegate   ((AppDelegate *)[[UIApplication sharedApplication] delegate])

static const CGFloat ZFPlayerAnimationTimeInterval             = 7.0f;
static const CGFloat ZFPlayerControlBarAutoFadeOutTimeInterval = 0.5f;

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, //横向移动
    PanDirectionVerticalMoved    //纵向移动
};

//播放器的几种状态
typedef NS_ENUM(NSInteger, ZFPlayerState) {
    ZFPlayerStateBuffering,  //缓冲中
    ZFPlayerStatePlaying,    //播放中
    ZFPlayerStateStopped,    //停止播放
    ZFPlayerStatePause       //暂停播放
};

@interface ZFPlayerView () <XXNibBridge,UIGestureRecognizerDelegate>

/** 快进快退label */
@property (weak, nonatomic  ) IBOutlet UILabel                 *horizontalLabel;
/** 系统菊花 */
@property (weak, nonatomic  ) IBOutlet UIActivityIndicatorView *activity;
/** 返回按钮*/
@property (weak, nonatomic  ) IBOutlet UIButton                *backBtn;
/** 播放属性 */
@property (nonatomic, strong) AVPlayer         *player;
/** 播放属性 */
@property (nonatomic, strong) AVPlayerItem     *playerItem;
/** playerLayer */
@property (nonatomic, strong) AVPlayerLayer    *playerLayer;
/** 滑杆 */
@property (nonatomic, strong) UISlider         *volumeViewSlider;
/** 计时器 */
@property (nonatomic, strong) NSTimer          *timer;
/** 蒙版View */
@property (nonatomic, strong) ZFPlayerMaskView *maskView;
/** 用来保存快进的总时长 */
@property (nonatomic, assign) CGFloat          sumTime;
/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection     panDirection;
/** 播发器的几种状态 */
@property (nonatomic, assign) ZFPlayerState    state;
/** 是否为全屏 */
@property (nonatomic, assign) BOOL             isFullScreen;
/** 是否锁定屏幕方向 */
@property (nonatomic, assign) BOOL             isLocked;
/** 是否在调节音量*/
@property (nonatomic, assign) BOOL             isVolume;
/** 是否显示maskView*/
@property (nonatomic, assign) BOOL             isMaskShowing;
/** 是否被用户暂停 */
@property (nonatomic, assign) BOOL             isPauseByUser;
/** 是否播放本地文件 */
@property (nonatomic, assign) BOOL             isLocalVideo;
/** slider上次的值 */
@property (nonatomic, assign) CGFloat          sliderLastValue;

@end

@implementation ZFPlayerView

/** 类方法创建，该方法适用于代码创建View */
+ (instancetype)setupZFPlayer
{
    return [[NSBundle mainBundle] loadNibNamed:@"ZFPlayerView" owner:nil options:nil].lastObject;
}

- (void)awakeFromNib
{
    self.backgroundColor                 = [UIColor blackColor];
    // 设置快进快退label
    self.horizontalLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Management_Mask"]];
    self.horizontalLabel.hidden          = YES;//先隐藏
    // 每次初始化都解锁屏幕锁定
    [self unLockTheScreen];
    self.state = ZFPlayerStateStopped;
}

- (void)dealloc
{
    //NSLog(@"%@释放了",self.class);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;

    // 屏幕方向一发生变化就会调用这里
    [UIApplication sharedApplication].statusBarHidden = NO;
    self.isMaskShowing = NO;
    // 延迟隐藏maskView
    [self animateShow];
    
    // 解决4s，屏幕宽高比不是16：9的问题
    if (iPhone4s) {
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            CGFloat width = [UIScreen mainScreen].bounds.size.width;
            make.height.mas_equalTo(width*320/480);
        }];
    }
}

- (void)setVideoURL:(NSURL *)videoURL
{
    // 创建AVPlayer
    self.playerItem  = [AVPlayerItem playerItemWithURL:videoURL];
    self.player      = [AVPlayer playerWithPlayerItem:_playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    
    if([self.playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]){
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }else{
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    [self.player play];
    
    
    self.maskView = [ZFPlayerMaskView setupPlayerMaskView];
    [self insertSubview:self.maskView belowSubview:self.backBtn];
    
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsMake(0, 0, 0, 0));
    }];
    if (self.player.rate == 1.0) {
        self.maskView.startBtn.selected = YES;
        self.isPauseByUser = NO;
    } else {
        self.maskView.startBtn.selected = NO;
        self.isPauseByUser = YES;
    }
    // AVPlayer播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];

    // slider开始滑动事件
    [self.maskView.videoSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    // slider滑动中事件
    [self.maskView.videoSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    // slider结束滑动事件
    [self.maskView.videoSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    // 播放按钮点击事件
    [self.maskView.startBtn addTarget:self action:@selector(startAction:) forControlEvents:UIControlEventTouchUpInside];
    // 返回按钮点击事件
    [self.backBtn addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    // 全屏按钮点击事件
    [self.maskView.fullScreenBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    // 锁定屏幕方向点击事件
    [self.maskView.lockBtn addTarget:self action:@selector(lockScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // 监听播放状态
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监听loadedTimeRanges属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // Will warn you when your buffer is empty
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    // Will warn you when your buffer is good to go again.
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];

    // 本地文件不设置ZFPlayerStateBuffering状态
    if ([videoURL.scheme isEqualToString:@"file"]) {
        self.state = ZFPlayerStatePlaying;
        self.isLocalVideo = YES;
    } else {
        self.state = ZFPlayerStateBuffering;
        self.isLocalVideo = NO;
    }
    
    // 初始化显示maskView为YES
    self.isMaskShowing = YES;
    // 延迟隐藏maskView
    [self autoFadeOutControlBar];
    // 计时器
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(playerTimerAction) userInfo:nil repeats:YES];

    // 监测设备方向
    [self listeningRotating];
    [self onDeviceOrientationChange];
    
    // 添加手势
    [self createGesture];
    //获取系统音量
    [self configureVolume];
    
    [self.activity startAnimating];
    
}

//创建手势
- (void)createGesture
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    
    [self addGestureRecognizer:tap];
}

//获取系统音量
- (void)configureVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
}

#pragma mark - ShowOrHideMaskView

- (void)autoFadeOutControlBar
{
    if (!self.isMaskShowing) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideMaskView) object:nil];
    [self performSelector:@selector(hideMaskView) withObject:nil afterDelay:ZFPlayerAnimationTimeInterval];

}
- (void)cancelAutoFadeOutControlBar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)hideMaskView
{
    if (!self.isMaskShowing) {
        return;
    }
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        self.maskView.alpha     = 0;
        if (self.isFullScreen) {
            self.backBtn.alpha  = 0;
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }
    }completion:^(BOOL finished) {
        self.isMaskShowing = NO;
    }];
}

- (void)animateShow
{
    if (self.isMaskShowing) {
        return;
    }
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        self.maskView.alpha = 1;
        self.backBtn.alpha  = 1;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    } completion:^(BOOL finished) {
        self.isMaskShowing = YES;
        [self autoFadeOutControlBar];
    }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.playerItem) {
        if ([keyPath isEqualToString:@"status"]) {
            
            if (self.player.status == AVPlayerStatusReadyToPlay) {
                
                self.state = ZFPlayerStatePlaying;
                // 加载完成后，再添加拖拽手势
                // 添加平移手势，用来控制音量、亮度、快进快退
                UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
                pan.delegate                = self;
                [self addGestureRecognizer:pan];
                
            } else if (self.player.status == AVPlayerStatusFailed){
                
                [self.activity startAnimating];
            }
            
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            
            NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
            CMTime duration             = self.playerItem.duration;
            CGFloat totalDuration       = CMTimeGetSeconds(duration);
            [self.maskView.progressView setProgress:timeInterval / totalDuration animated:NO];
            
        }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            
            // 当缓冲是空的时候
            if (self.playerItem.playbackBufferEmpty) {
                //NSLog(@"playbackBufferEmpty");
                self.state = ZFPlayerStateBuffering;
                [self bufferingSomeSecond];
            }
            
        }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
            // 当缓冲好的时候
            if (self.playerItem.playbackLikelyToKeepUp){
                //NSLog(@"playbackLikelyToKeepUp");
                self.state = ZFPlayerStatePlaying;
            }
            
        }
    }
}

//缓冲较差时候
- (void)bufferingSomeSecond
{
    [self.activity startAnimating];
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    static BOOL isBuffering = NO;
    if (isBuffering) {
        return;
    }
    isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (self.isPauseByUser) {
            isBuffering = NO;
            return;
        }
        
        [self.player play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
}

#pragma mark - 计时器事件

- (void)playerTimerAction
{
    if (_playerItem.duration.timescale != 0) {
        self.maskView.videoSlider.maximumValue = 1;//音乐总共时长
        self.maskView.videoSlider.value        = CMTimeGetSeconds([_playerItem currentTime]) / (_playerItem.duration.value / _playerItem.duration.timescale);//当前进度

        //当前时长进度progress
        NSInteger proMin                       = (NSInteger)CMTimeGetSeconds([_player currentTime]) / 60;//当前秒
        NSInteger proSec                       = (NSInteger)CMTimeGetSeconds([_player currentTime]) % 60;//当前分钟

        //duration 总时长
        NSInteger durMin                       = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale / 60;//总秒
        NSInteger durSec                       = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale % 60;//总分钟

        self.maskView.currentTimeLabel.text    = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
        self.maskView.totalTimeLabel.text      = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    }
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

#pragma mark - 监听设备旋转方向

- (void)listeningRotating{
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
    
}

- (void)onDeviceOrientationChange{
    if (self.isLocked) {
        self.isFullScreen = YES;
        return;
    }
    UIDeviceOrientation orientation             = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
            //NSLog(@"第3个旋转方向---电池栏在下");
            [self.maskView.fullScreenBtn setImage:[UIImage imageNamed:@"kr-video-player-shrinkscreen"] forState:UIControlStateNormal];
            self.isFullScreen = YES;
        }
            break;
        case UIInterfaceOrientationPortrait:{
            //NSLog(@"第0个旋转方向---电池栏在上");
            [self.maskView.fullScreenBtn setImage:[UIImage imageNamed:@"kr-video-player-fullscreen"] forState:UIControlStateNormal];
            self.isFullScreen = NO;
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            //NSLog(@"第2个旋转方向---电池栏在右");
            [self.maskView.fullScreenBtn setImage:[UIImage imageNamed:@"kr-video-player-shrinkscreen"] forState:UIControlStateNormal];
            self.isFullScreen = YES;
            
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            //NSLog(@"第1个旋转方向---电池栏在左");
            [self.maskView.fullScreenBtn setImage:[UIImage imageNamed:@"kr-video-player-shrinkscreen"] forState:UIControlStateNormal];
            self.isFullScreen = YES;
        }
            break;
            
        default:
            break;
    }
    
}

#pragma mark - slider事件

// slider开始滑动事件
- (void)progressSliderTouchBegan:(UISlider *)slider
{
    [self cancelAutoFadeOutControlBar];
    // 暂停timer
    [self.timer setFireDate:[NSDate distantFuture]];
}

// slider滑动中事件
- (void)progressSliderValueChanged:(UISlider *)slider
{
    NSString *style = @"";
    CGFloat value = slider.value - self.sliderLastValue;
    if (value > 0) {
        style = @">>";
    } else if (value < 0) {
        style = @"<<";
    }
     self.sliderLastValue = slider.value;
    //拖动改变视频播放进度
    if (_player.status == AVPlayerStatusReadyToPlay) {
        
        [_player pause];
        //计算出拖动的当前秒数
        CGFloat total                       = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;

        NSInteger dragedSeconds             = floorf(total * slider.value);

        //转换成CMTime才能给player来控制播放进度

        CMTime dragedCMTime                 = CMTimeMake(dragedSeconds, 1);
        // 拖拽的时长
        NSInteger proMin                    = (NSInteger)CMTimeGetSeconds(dragedCMTime) / 60;//当前秒
        NSInteger proSec                    = (NSInteger)CMTimeGetSeconds(dragedCMTime) % 60;//当前分钟

        //duration 总时长
        NSInteger durMin                    = (NSInteger)total / 60;//总秒
        NSInteger durSec                    = (NSInteger)total % 60;//总分钟

        NSString *currentTime               = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
        NSString *totalTime                 = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];

        self.maskView.currentTimeLabel.text = currentTime;
        self.horizontalLabel.hidden         = NO;
        self.horizontalLabel.text           = [NSString stringWithFormat:@"%@ %@ / %@",style, currentTime, totalTime];
        
    }
}

// slider结束滑动事件
- (void)progressSliderTouchEnded:(UISlider *)slider
{
    // 继续开启timer
    [self.timer setFireDate:[NSDate date]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.horizontalLabel.hidden = YES;
    });
    // 结束滑动时候把开始播放按钮改为播放状态
    self.maskView.startBtn.selected = YES;
    self.isPauseByUser              = NO;
    
    // 滑动结束延时隐藏maskView
    [self autoFadeOutControlBar];
    
    //计算出拖动的当前秒数
    CGFloat total           = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;

    NSInteger dragedSeconds = floorf(total * slider.value);

    //转换成CMTime才能给player来控制播放进度

    CMTime dragedCMTime     = CMTimeMake(dragedSeconds, 1);
    
    [self endSlideTheVideo:dragedCMTime];
}


#pragma mark - Action

// 滑动结束视频跳转
- (void)endSlideTheVideo:(CMTime)dragedCMTime
{
    //[_player pause];
    [_player seekToTime:dragedCMTime completionHandler:^(BOOL finish){
        // 如果点击了暂停按钮
        if (self.isPauseByUser) {
            //NSLog(@"已暂停");
            return ;
        }
        [_player play];
        if (!self.playerItem.isPlaybackLikelyToKeepUp && !self.isLocalVideo) {
            self.state = ZFPlayerStateBuffering;
            //NSLog(@"显示菊花");
            [self.activity startAnimating];
        }
    }];
}

// 轻拍方法
- (void)tapAction:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.isMaskShowing) {
            [self hideMaskView];
        } else {
            [self animateShow];
        }
    }
}

// 播放、暂停
- (void)startAction:(UIButton *)button
{
    button.selected = !button.selected;
    self.isPauseByUser = !button.isSelected;
    if (button.selected) {
        [_player play];
        self.state = ZFPlayerStatePlaying;
    } else {
        [_player pause];
        self.state = ZFPlayerStatePause;
    }
}

// 返回按钮事件
- (void)backButtonAction
{
    if (self.isLocked) {
        [self unLockTheScreen];
        return;
    }else {
        if (!self.isFullScreen) {
            [self.timer invalidate];
            [_player pause];
            if (self.goBackBlock) {
                self.goBackBlock();
            }
        }else {
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
    }
}

// 全屏按钮事件
- (void)fullScreenAction:(UIButton *)sender
{
    if (self.isLocked) {
        [self unLockTheScreen];
        return;
    }
    UIDeviceOrientation orientation             = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {

        case UIInterfaceOrientationPortraitUpsideDown:{
            //NSLog(@"fullScreenAction第3个旋转方向---电池栏在下");
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
            break;
        case UIInterfaceOrientationPortrait:{
            //NSLog(@"fullScreenAction第0个旋转方向---电池栏在上");
            [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            //NSLog(@"fullScreenAction第2个旋转方向---电池栏在右");
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            //NSLog(@"fullScreenAction第1个旋转方向---电池栏在左");
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
            break;
            
        default:
            break;
    }

}

// 锁定屏幕方向按钮
- (void)lockScreenAction:(UIButton *)sender
{
    sender.selected              = !sender.selected;
    self.isLocked                = sender.selected;
    // 调用AppDelegate单例记录播放状态是否锁屏，在TabBarController设置哪些页面支持旋转
    ApplicationDelegate.isLockScreen = sender.selected;
}

// 解锁屏幕方向锁定
- (void)unLockTheScreen
{
    // 调用AppDelegate单例记录播放状态是否锁屏
    ApplicationDelegate.isLockScreen = NO;
    [self lockScreenAction:self.maskView.lockBtn];
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
}

#pragma mark - NSNotification Action

// 播放完了
- (void)moviePlayDidEnd:(NSNotification *)notification
{
    self.state                   = ZFPlayerStateStopped;
    ApplicationDelegate.isLockScreen = NO;
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
    // 关闭定时器
    [self.timer invalidate];
    if (self.goBackBlock) {
        self.goBackBlock();
    }
}

// 应用退到后台
- (void)appDidEnterBackground
{
    [_player pause];
    self.state = ZFPlayerStatePause;
    [self cancelAutoFadeOutControlBar];
}

// 应用进入前台
- (void)appDidEnterPlayGround
{
    self.isMaskShowing = NO;
    // 延迟隐藏maskView
    [self animateShow];
    if (!self.isPauseByUser) {
        self.state                      = ZFPlayerStatePlaying;
        self.maskView.startBtn.selected = YES;
        self.isPauseByUser              = NO;
        [_player play];
    }
}

#pragma mark - 平移手势方法

- (void)panDirection:(UIPanGestureRecognizer *)pan
{
    //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];
    
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                self.panDirection           = PanDirectionHorizontalMoved;
                // 取消隐藏
                self.horizontalLabel.hidden = NO;
                // 给sumTime初值
                CMTime time                 = self.player.currentTime;
                self.sumTime                = time.value/time.timescale;
                
                // 暂停视频播放
                [_player pause];
                // 暂停timer
                [self.timer setFireDate:[NSDate distantFuture]];
            }
            else if (x < y){ // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else { // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
                
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    
                    // 继续播放
                    [_player play];
                    [self.timer setFireDate:[NSDate date]];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        // 隐藏视图
                        self.horizontalLabel.hidden = YES;
                    });
                    //快进、快退时候把开始播放按钮改为播放状态
                    self.maskView.startBtn.selected = YES;
                    self.isPauseByUser              = NO;

                    // 转换成CMTime才能给player来控制播放进度
                    CMTime dragedCMTime             = CMTimeMake(self.sumTime, 1);
                    //[_player pause];
                    
                    [self endSlideTheVideo:dragedCMTime];

                    // 把sumTime滞空，不然会越加越多
                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.horizontalLabel.hidden = YES;
                    });
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - pan垂直移动的方法

- (void)verticalMoved:(CGFloat)value
{
    if (self.isVolume) {
        // 更改系统的音量
        self.volumeViewSlider.value      -= value / 10000;// 越小幅度越小
    }else {
        //亮度
        [UIScreen mainScreen].brightness -= value / 10000;
        //NSString *brightness             = [NSString stringWithFormat:@"亮度%.0f%%",[UIScreen mainScreen].brightness/1.0*100];
        //self.horizontalLabel.hidden      = NO;
        //self.horizontalLabel.text        = brightness;
    }
}

#pragma mark - pan水平移动的方法

- (void)horizontalMoved:(CGFloat)value
{
    // 快进快退的方法
    NSString *style = @"";
    if (value < 0) {
        style = @"<<";
    }
    else if (value > 0){
        style = @">>";
    }
    
    // 每次滑动需要叠加时间
    self.sumTime += value / 200;
    
    // 需要限定sumTime的范围
    CMTime totalTime           = self.playerItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (self.sumTime > totalMovieDuration) {
        self.sumTime = totalMovieDuration;
    }else if (self.sumTime < 0){
        self.sumTime = 0;
    }
    
    // 当前快进的时间
    NSString *nowTime         = [self durationStringWithTime:(int)self.sumTime];
    // 总时间
    NSString *durationTime    = [self durationStringWithTime:(int)totalMovieDuration];
    // 给label赋值
    self.horizontalLabel.text = [NSString stringWithFormat:@"%@ %@ / %@",style, nowTime, durationTime];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint point = [touch locationInView:self.maskView];
    // 屏幕下方slider区域不响应pan手势
    if ((point.y > self.bounds.size.height-40)) {
        return NO;
    }
    return YES;
}

#pragma mark - 根据时长求出字符串

- (NSString *)durationStringWithTime:(int)time
{
    // 获取分钟
    NSString *min = [NSString stringWithFormat:@"%02d",time / 60];
    // 获取秒数
    NSString *sec = [NSString stringWithFormat:@"%02d",time % 60];
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}

#pragma mark 强制转屏相关

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    // arc下
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector             = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val                  = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
    /*
     // 非arc下
     if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        [[UIDevice currentDevice] performSelector:@selector(setOrientation:)
                                       withObject:@(orientation)];
     }
     
    // 直接调用这个方法通不过apple上架审核
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
    
     */
}


#pragma mark - Setter 

- (void)setState:(ZFPlayerState)state
{
    if (state != ZFPlayerStateBuffering) {
        [self.activity stopAnimating];
    }

    if (_state == state) {
        return;
    }
    _state = state;
}


@end
