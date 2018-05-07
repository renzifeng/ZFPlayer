//
//  CustomPlayerControlView.h
//  Player
//
//  Created by lip on 2018/4/8.
//  Copyright © 2018年 任子丰. All rights reserved.
//

#import "CustomPlayerControlView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+CustomControlView.h"
#import <UIKit/UIKit.h>

@interface IndicatorFlowerView: UIImageView
@end

@implementation IndicatorFlowerView

- (void)startAnimatingWhite {
    self.hidden = NO;
    NSMutableArray<UIImage *> *images = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < 10; i++) {
        NSString *string = [NSString stringWithFormat:@"default_white0%d", i];
        UIImage *image = ZFPlayerImage(string);
        [images addObject:image];
    }
    for (NSInteger i = 10; i < 20; i++) {
        NSString *string = [NSString stringWithFormat:@"default_white%d", i];
        UIImage *image = ZFPlayerImage(string);
        [images addObject:image];
    }
    self.animationImages = images;
    self.animationDuration = images.count * 4 / 30.0;
    self.animationRepeatCount = 0;
    [self startAnimating];
}

- (void)stopAnimatingWhite {
    [self stopAnimating];
    self.hidden = YES;
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

static const CGFloat ZFPlayerAnimationTimeInterval             = 3.0f;
static const CGFloat ZFPlayerControlBarAutoFadeOutTimeInterval = 0.35f;

@interface CustomPlayerControlView () <UIGestureRecognizerDelegate>

/** 开始播放按钮 */
@property (nonatomic, strong) UIButton                *startBtn;
/** 当前播放时长label */
@property (nonatomic, strong) UILabel                 *currentTimeLabel;
/** 视频总时长label */
@property (nonatomic, strong) UILabel                 *totalTimeLabel;
/** 缓冲进度条 */
@property (nonatomic, strong) UIProgressView          *progressView;
/** 滑杆 */
@property (nonatomic, strong) ASValueTrackingSlider   *videoSlider;
/** 全屏按钮 */
@property (nonatomic, strong) UIButton                *fullScreenBtn;
/** 系统菊花 */
@property (nonatomic, strong) IndicatorFlowerView *activity;
/** 返回按钮*/
@property (nonatomic, strong) UIButton                *backBtn;
/** 关闭按钮*/
@property (nonatomic, strong) UIButton                *closeBtn;
/** 重播按钮 */
@property (nonatomic, strong) UIButton                *repeatBtn;
/** 分享按钮 */
@property (nonatomic, strong) UIButton                *shareBtn;
/** 重播标签 */
@property (nonatomic, strong) UILabel                *repeatLabel;
/** 分享标签 */
@property (nonatomic, strong) UILabel                *shareLabel;
/** bottomView*/
@property (nonatomic, strong) UIImageView             *bottomImageView;
/** topView */
@property (nonatomic, strong) UIImageView             *topImageView;
/** 缓存按钮 */
@property (nonatomic, strong) UIButton                *downLoadBtn;
/** 切换分辨率按钮 */
@property (nonatomic, strong) UIButton                *resolutionBtn;
/** 分辨率的View */
@property (nonatomic, strong) UIView                  *resolutionView;
/** 加载失败按钮 */
@property (nonatomic, strong) UIButton                *failBtn;
/** 加载失败标签 */
@property (nonatomic, strong) UILabel                *failLabel;
/** 快进快退View*/
@property (nonatomic, strong) UIView                  *fastView;
/** 快进快退进度progress*/
@property (nonatomic, strong) UIProgressView          *fastProgressView;
/** 快进快退时间*/
@property (nonatomic, strong) UILabel                 *fastTimeLabel;
/** 快进快退ImageView*/
@property (nonatomic, strong) UIImageView             *fastImageView;
/** 当前选中的分辨率btn按钮 */
@property (nonatomic, weak  ) UIButton                *resoultionCurrentBtn;
/** 占位图 */
@property (nonatomic, strong) UIImageView             *placeholderImageView;
/** 分辨率的名称 */
@property (nonatomic, strong) NSArray                 *resolutionArray;

/** 显示控制层 */
@property (nonatomic, assign, getter=isShowing) BOOL  showing;
/** 小屏播放 */
@property (nonatomic, assign, getter=isShrink ) BOOL  shrink;
/** 在cell上播放 */
@property (nonatomic, assign, getter=isCellVideo)BOOL cellVideo;
/** 是否拖拽slider控制播放进度 */
@property (nonatomic, assign, getter=isDragged) BOOL  dragged;
/** 是否播放结束 */
@property (nonatomic, assign, getter=isPlayEnd) BOOL  playeEnd;
/** 是否全屏播放 */
@property (nonatomic, assign,getter=isFullScreen) BOOL fullScreen;

@end

@implementation CustomPlayerControlView

- (BOOL)currentIsFullScreen {
    return self.frame.size.height == ScreenHeight;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self addSubview:self.placeholderImageView];
        [self addSubview:self.topImageView];
        [self addSubview:self.bottomImageView];
        [self addSubview:self.startBtn];
        [self.bottomImageView addSubview:self.currentTimeLabel];
        [self.bottomImageView addSubview:self.progressView];
        [self.bottomImageView addSubview:self.videoSlider];
        [self.bottomImageView addSubview:self.fullScreenBtn];
        [self.bottomImageView addSubview:self.totalTimeLabel];
        
        [self.topImageView addSubview:self.downLoadBtn];
        [self.topImageView addSubview:self.backBtn];
        [self addSubview:self.activity];
        [self addSubview:self.repeatBtn];
        [self addSubview:self.shareBtn];
        [self addSubview:self.repeatLabel];
        [self addSubview:self.shareLabel];
        [self addSubview:self.failBtn];
        [self addSubview:self.failLabel];

        [self addSubview:self.fastView];
        [self.fastView addSubview:self.fastImageView];
        [self.fastView addSubview:self.fastTimeLabel];
        [self.fastView addSubview:self.fastProgressView];
        
        [self.topImageView addSubview:self.resolutionBtn];
        [self addSubview:self.closeBtn];
        
        // 添加子控件的约束
        [self makeSubViewsConstraints];
        
        self.downLoadBtn.hidden     = YES;
        self.resolutionBtn.hidden   = YES;
        // 初始化时重置controlView
        [self zf_playerResetControlView];
        // app退到后台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
        // app进入前台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [self listeningRotating];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)makeSubViewsConstraints {
    [self.placeholderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.mas_trailing).offset(7);
        make.top.equalTo(self.mas_top).offset(-7);
        make.width.height.mas_equalTo(20);
    }];
    
    [self.topImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(self.mas_top).offset(0);
        make.height.mas_equalTo(50);
    }];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.topImageView.mas_leading).offset(10);
        make.top.equalTo(self.topImageView.mas_top).offset(3);
        make.width.height.mas_equalTo(40);
    }];
    
    [self.downLoadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(49);
        make.trailing.equalTo(self.topImageView.mas_trailing).offset(-10);
        make.centerY.equalTo(self.backBtn.mas_centerY);
    }];
    
    [self.resolutionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(25);
        make.trailing.equalTo(self.downLoadBtn.mas_leading).offset(-10);
        make.centerY.equalTo(self.backBtn.mas_centerY);
    }];
    
    [self.bottomImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.mas_equalTo(0);
        make.height.mas_equalTo(50);
    }];

    [self.startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.center.equalTo(self);
    }];

    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bottomImageView.mas_leading).offset(15);
        make.centerY.equalTo(self.bottomImageView);
        make.width.mas_equalTo(43);
    }];
    
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(20);
        make.trailing.equalTo(self.bottomImageView.mas_trailing).offset(-15);
        make.centerY.equalTo(self.bottomImageView);
    }];

    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.fullScreenBtn.mas_leading).offset(-15);
        make.centerY.equalTo(self.bottomImageView);
        make.width.mas_equalTo(43);
    }];

    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(12);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-12);
        make.centerY.equalTo(self.bottomImageView);
    }];

    [self.videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(12);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-12);
        make.centerY.equalTo(self.bottomImageView).offset(-1);
        make.height.mas_equalTo(30);
    }];

    [self.repeatBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_centerY).offset(-40);
        make.right.equalTo(self.mas_centerX).offset(-30);
        make.width.height.mas_equalTo(55);
    }];

    [self.shareBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_centerY).offset(-40);
        make.left.equalTo(self.mas_centerX).offset(30);
        make.width.height.mas_equalTo(55);
    }];

    [self.repeatLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.repeatBtn.mas_bottom).offset(15);
        make.centerX.equalTo(self.repeatBtn);
        make.height.mas_equalTo(13);
        make.width.mas_equalTo(55);
    }];

    [self.shareLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.shareBtn.mas_bottom).offset(15);
        make.centerX.equalTo(self.shareBtn);
        make.height.mas_equalTo(13);
        make.width.mas_equalTo(55);
    }];
    
    [self.activity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.with.height.mas_equalTo(40);
    }];
    
    [self.failBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_centerY);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(70);
        make.height.mas_equalTo(26);
    }];
    
    [self.failLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_centerY).offset(-15);
        make.centerX.equalTo(self);
        make.width.equalTo(self);
        make.height.mas_equalTo(15);
    }];

    [self.fastImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_offset(32);
        make.height.mas_offset(32);
        make.top.mas_equalTo(5);
        make.centerX.mas_equalTo(self.fastView.mas_centerX);
    }];
    
    [self.fastTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.with.trailing.mas_equalTo(0);
        make.top.mas_equalTo(self.fastImageView.mas_bottom).offset(2);
    }];
    
    [self.fastProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(12);
        make.trailing.mas_equalTo(-12);
        make.top.mas_equalTo(self.fastTimeLabel.mas_bottom).offset(10);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (currentOrientation == UIDeviceOrientationPortrait) {
        [self setOrientationPortraitConstraint];
    } else {
        [self setOrientationLandscapeConstraint];
    }
}

#pragma mark - Action

/**
 *  点击切换分别率按钮
 */
- (void)changeResolution:(UIButton *)sender {
    sender.selected = YES;
    if (sender.isSelected) {
        sender.backgroundColor = RGBA(86, 143, 232, 1);
    } else {
        sender.backgroundColor = [UIColor clearColor];
    }
    self.resoultionCurrentBtn.selected = NO;
    self.resoultionCurrentBtn.backgroundColor = [UIColor clearColor];
    self.resoultionCurrentBtn = sender;
    // 隐藏分辨率View
    self.resolutionView.hidden  = YES;
    // 分辨率Btn改为normal状态
    self.resolutionBtn.selected = NO;
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:resolutionAction:)]) {
        [self.zfDelegate zf_controlView:self resolutionAction:sender];
    }
}

/**
 *  UISlider TapAction
 */
- (void)tapSliderAction:(UITapGestureRecognizer *)tap {
    if ([tap.view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)tap.view;
        CGPoint point = [tap locationInView:slider];
        CGFloat length = slider.frame.size.width;
        // 视频跳转的value
        CGFloat tapValue = point.x / length;
        if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:progressSliderTap:)]) {
            [self.zfDelegate zf_controlView:self progressSliderTap:tapValue];
        }
    }
}
// 不做处理，只是为了滑动slider其他地方不响应其他手势
- (void)panRecognizer:(UIPanGestureRecognizer *)sender {}

- (void)backBtnClick:(UIButton *)sender {
    sender.hidden = YES;
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:fullScreenAction:)]) {
        [self.zfDelegate zf_controlView:self fullScreenAction:sender];
    }
}

- (void)lockScrrenBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.showing = NO;
    [self zf_playerShowControlView];
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:lockScreenAction:)]) {
        [self.zfDelegate zf_controlView:self lockScreenAction:sender];
    }
}

- (void)playBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:playAction:)]) {
        [self.zfDelegate zf_controlView:self playAction:sender];
    }
}

- (void)closeBtnClick:(UIButton *)sender {
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:closeAction:)]) {
        [self.zfDelegate zf_controlView:self closeAction:sender];
    }
}

- (void)fullScreenBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.fullScreen = sender.selected;
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:fullScreenAction:)]) {
        [self.zfDelegate zf_controlView:self fullScreenAction:sender];
    }
}

- (void)repeatBtnClick:(UIButton *)sender {
    // 重置控制层View
    [self zf_playerResetControlView];
    [self zf_playerShowControlView];
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:repeatPlayAction:)]) {
        [self.zfDelegate zf_controlView:self repeatPlayAction:sender];
    }
}

- (void)shareBtnClick:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didClickShortVideoShareBtn" object:nil];
}

- (void)downloadBtnClick:(UIButton *)sender {
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:downloadVideoAction:)]) {
        [self.zfDelegate zf_controlView:self downloadVideoAction:sender];
    }
}

- (void)resolutionBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    // 显示隐藏分辨率View
    self.resolutionView.hidden = !sender.isSelected;
}

- (void)centerPlayBtnClick:(UIButton *)sender {
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:cneterPlayAction:)]) {
        [self.zfDelegate zf_controlView:self cneterPlayAction:sender];
    }
}

- (void)failBtnClick:(UIButton *)sender {
    self.failBtn.hidden = YES;
    self.failLabel.hidden = YES;
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:failAction:)]) {
        [self.zfDelegate zf_controlView:self failAction:sender];
    }
}

- (void)progressSliderTouchBegan:(ASValueTrackingSlider *)sender {
    [self zf_playerCancelAutoFadeOutControlView];
    self.videoSlider.popUpView.hidden = YES;
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:progressSliderTouchBegan:)]) {
        [self.zfDelegate zf_controlView:self progressSliderTouchBegan:sender];
    }
}

- (void)progressSliderValueChanged:(ASValueTrackingSlider *)sender {
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:progressSliderValueChanged:)]) {
        [self.zfDelegate zf_controlView:self progressSliderValueChanged:sender];
    }
}

- (void)progressSliderTouchEnded:(ASValueTrackingSlider *)sender {
    self.showing = YES;
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlView:progressSliderTouchEnded:)]) {
        [self.zfDelegate zf_controlView:self progressSliderTouchEnded:sender];
    }
}

/**
 *  应用退到后台
 */
- (void)appDidEnterBackground {
    [self zf_playerCancelAutoFadeOutControlView];
}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayground {
    if (!self.isShrink) { [self zf_playerShowControlView]; }
}

- (void)playerPlayDidEnd {
    self.backgroundColor  = RGBA(0, 0, 0, .6);
    self.repeatBtn.hidden = NO;
    self.shareBtn.hidden = NO;
    self.repeatLabel.hidden = NO;
    if ([self currentIsFullScreen] == YES) {
        self.topImageView.hidden = NO;
        self.backBtn.hidden = NO;
    } else {
        self.topImageView.hidden = YES;
        self.backBtn.hidden = YES;
    }
    // 初始化显示controlView为YES
    self.showing = NO;
    // 延迟隐藏controlView
    [self zf_playerShowControlView];
}

/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange {
    if (ZFPlayerShared.isLockScreen) { return; }
    self.fullScreenBtn.selected = [self currentIsFullScreen];
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || orientation == UIDeviceOrientationPortraitUpsideDown) { return; }
    if (!self.isShrink && !self.isPlayEnd && !self.showing) {
        // 显示、隐藏控制层
        [self zf_playerShowOrHideControlView];
    }
}

- (void)setOrientationLandscapeConstraint {
    if (self.isCellVideo) {
        self.shrink             = NO;
    }
    self.backBtn.hidden = NO;
    self.topImageView.hidden = NO;
    self.fullScreenBtn.selected = [self currentIsFullScreen];
    [self.backBtn setImage:ZFPlayerImage(@"ZFPlayer_back_full") forState:UIControlStateNormal];
    [self.backBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topImageView.mas_top).offset(23);
        make.leading.equalTo(self.topImageView.mas_leading).offset(10);
        make.width.height.mas_equalTo(40);
    }];
}
/**
 *  设置竖屏的约束
 */
- (void)setOrientationPortraitConstraint {
    // 如果现在是小屏幕就不显示返回按钮,反之就显示
    self.backBtn.hidden = ![self currentIsFullScreen];

    [self.backBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topImageView.mas_top).offset(3);
        make.leading.equalTo(self.topImageView.mas_leading).offset(10);
        make.width.height.mas_equalTo(40);
    }];
}

#pragma mark - Private Method

- (void)showControlView {
    self.showing = YES;
    self.topImageView.alpha    = 1;
    self.bottomImageView.alpha = 1;
    if (self.activity.isHidden == YES) {
        self.startBtn.alpha = 1;
    } else {
        self.startBtn.alpha = 0;
    }
    self.backgroundColor           = RGBA(0, 0, 0, 0.3);
    if (self.isCellVideo) {
        self.shrink                = NO;
    }
    ZFPlayerShared.isStatusBarHidden = NO;
}

- (void)hideControlView {
    self.showing = NO;
    self.backgroundColor          = RGBA(0, 0, 0, 0);
    self.topImageView.alpha       = self.playeEnd;
    self.bottomImageView.alpha    = 0;
    self.startBtn.alpha = 0;
    // 隐藏resolutionView
    self.resolutionBtn.selected = YES;
    [self resolutionBtnClick:self.resolutionBtn];
    if ([self currentIsFullScreen] && !self.playeEnd && !self.isShrink) {
        ZFPlayerShared.isStatusBarHidden = YES;
    }
}

/**
 *  监听设备旋转通知
 */
- (void)listeningRotating {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


- (void)autoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(zf_playerHideControlView) object:nil];
    [self performSelector:@selector(zf_playerHideControlView) withObject:nil afterDelay:ZFPlayerAnimationTimeInterval];
}

/**
 slider滑块的bounds
 */
- (CGRect)thumbRect {
    return [self.videoSlider thumbRectForBounds:self.videoSlider.bounds
                                      trackRect:[self.videoSlider trackRectForBounds:self.videoSlider.bounds]
                                          value:self.videoSlider.value];
}

#pragma mark - setter

- (void)setShrink:(BOOL)shrink {
    _shrink = shrink;
    self.closeBtn.hidden = !shrink;
}

- (void)setFullScreen:(BOOL)fullScreen {
    _fullScreen = fullScreen;
    ZFPlayerShared.isLandscape = fullScreen;
}

#pragma mark - getter

- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:ZFPlayerImage(@"ZFPlayer_back_full") forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (UIImageView *)topImageView {
    if (!_topImageView) {
        _topImageView                        = [[UIImageView alloc] init];
        _topImageView.userInteractionEnabled = YES;
        _topImageView.alpha                  = 0;
        _topImageView.image                  = ZFPlayerImage(@"ZFPlayer_top_shadow");
    }
    return _topImageView;
}

- (UIImageView *)bottomImageView {
    if (!_bottomImageView) {
        _bottomImageView                        = [[UIImageView alloc] init];
        _bottomImageView.userInteractionEnabled = YES;
        _bottomImageView.alpha                  = 0;
        _bottomImageView.image                  = ZFPlayerImage(@"ZFPlayer_bottom_shadow");
    }
    return _bottomImageView;
}

- (UIButton *)startBtn {
    if (!_startBtn) {
        _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startBtn setImage:ZFPlayerImage(@"ZFPlayer_play") forState:UIControlStateNormal];
        [_startBtn setImage:ZFPlayerImage(@"ZFPlayer_pause") forState:UIControlStateSelected];
        [_startBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBtn;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setImage:ZFPlayerImage(@"ZFPlayer_close") forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _closeBtn.hidden = YES;
    }
    return _closeBtn;
}

- (UILabel *)currentTimeLabel {
    if (!_currentTimeLabel) {
        _currentTimeLabel               = [[UILabel alloc] init];
        _currentTimeLabel.textColor     = [UIColor whiteColor];
        _currentTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView                   = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _progressView.trackTintColor    = [UIColor clearColor];
    }
    return _progressView;
}

- (ASValueTrackingSlider *)videoSlider {
    if (!_videoSlider) {
        _videoSlider                       = [[ASValueTrackingSlider alloc] init];
        _videoSlider.popUpViewCornerRadius = 0.0;
        _videoSlider.popUpViewColor = RGBA(19, 19, 9, 1);
        _videoSlider.popUpViewArrowLength = 8;
        
        [_videoSlider setThumbImage:ZFPlayerImage(@"ZFPlayer_slider") forState:UIControlStateNormal];
        _videoSlider.maximumValue          = 1;
        _videoSlider.minimumTrackTintColor = RGBA(89, 182, 215, 1);
        _videoSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];

        // slider开始滑动事件
        [_videoSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
        // slider滑动中事件
        [_videoSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        // slider结束滑动事件
        [_videoSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        
        UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderAction:)];
        [_videoSlider addGestureRecognizer:sliderTap];
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panRecognizer:)];
        panRecognizer.delegate = self;
        [panRecognizer setMaximumNumberOfTouches:1];
        [panRecognizer setDelaysTouchesBegan:YES];
        [panRecognizer setDelaysTouchesEnded:YES];
        [panRecognizer setCancelsTouchesInView:YES];
        [_videoSlider addGestureRecognizer:panRecognizer];
    }
    return _videoSlider;
}

- (UILabel *)totalTimeLabel {
    if (!_totalTimeLabel) {
        _totalTimeLabel               = [[UILabel alloc] init];
        _totalTimeLabel.textColor     = [UIColor whiteColor];
        _totalTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UIButton *)fullScreenBtn {
    if (!_fullScreenBtn) {
        _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenBtn setImage:ZFPlayerImage(@"ZFPlayer_fullscreen") forState:UIControlStateNormal];
        [_fullScreenBtn setImage:ZFPlayerImage(@"ZFPlayer_shrinkscreen") forState:UIControlStateSelected];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenBtn;
}

- (IndicatorFlowerView *)activity {
    if (!_activity) {
        _activity = [[IndicatorFlowerView alloc] init];
        _activity.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        _activity.clipsToBounds = YES;
        _activity.layer.cornerRadius = 40 / 2;
    }
    return _activity;
}

- (UIButton *)repeatBtn {
    if (!_repeatBtn) {
        _repeatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_repeatBtn setImage:ZFPlayerImage(@"ZFPlayer_repeat_video") forState:UIControlStateNormal];
        [_repeatBtn addTarget:self action:@selector(repeatBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _repeatBtn;
}

- (UIButton *)shareBtn {
    if (!_shareBtn) {
        _shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareBtn setImage:ZFPlayerImage(@"ico_video_share") forState:UIControlStateNormal];
        [_shareBtn addTarget:self action:@selector(shareBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareBtn;
}

- (UILabel *)repeatLabel {
    if (!_repeatLabel) {
        _repeatLabel = [[UILabel alloc] init];
        [_repeatLabel setText:@"重播"];
        [_repeatLabel setTextColor:[UIColor whiteColor]];
        [_repeatLabel setTextAlignment:NSTextAlignmentCenter];
        _repeatLabel.font = [UIFont systemFontOfSize:14.0];
    }
    return _repeatLabel;
}

- (UILabel *)shareLabel {
    if (!_shareLabel) {
        _shareLabel = [[UILabel alloc] init];
        [_shareLabel setText:@"分享"];
        [_shareLabel setTextColor:[UIColor whiteColor]];
        [_shareLabel setTextAlignment:NSTextAlignmentCenter];
        _shareLabel.font = [UIFont systemFontOfSize:14.0];
    }
    return _shareLabel;
}

- (UIButton *)downLoadBtn {
    if (!_downLoadBtn) {
        _downLoadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_downLoadBtn setImage:ZFPlayerImage(@"ZFPlayer_download") forState:UIControlStateNormal];
        [_downLoadBtn setImage:ZFPlayerImage(@"ZFPlayer_not_download") forState:UIControlStateDisabled];
        [_downLoadBtn addTarget:self action:@selector(downloadBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downLoadBtn;
}

- (UIButton *)resolutionBtn {
    if (!_resolutionBtn) {
        _resolutionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _resolutionBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        _resolutionBtn.backgroundColor = RGBA(0, 0, 0, 0.7);
        [_resolutionBtn addTarget:self action:@selector(resolutionBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resolutionBtn;
}

- (UIButton *)failBtn {
    if (!_failBtn) {
        _failBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_failBtn setTitle:@"重试" forState:UIControlStateNormal];
        [_failBtn setImage:ZFPlayerImage(@"ico_video_retry") forState:UIControlStateNormal];
        [_failBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_failBtn setBackgroundColor:RGBA(89, 182, 215, 1)];
        _failBtn.clipsToBounds = YES;
        _failBtn.layer.cornerRadius = 4;
        _failBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
        _failBtn.backgroundColor = RGBA(0, 0, 0, 0.7);
        [_failBtn addTarget:self action:@selector(failBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _failBtn;
}

- (UILabel *)failLabel {
    if (!_failLabel) {
        _failLabel = [[UILabel alloc] init];
        [_failLabel setText:@"网络状况不佳，视频加载失败。"];
        [_failLabel setTextColor:[UIColor whiteColor]];
        [_failLabel setTextAlignment:NSTextAlignmentCenter];
        _failLabel.font = [UIFont systemFontOfSize:14.0];
    }
    return _failLabel;
}

- (UIView *)fastView {
    if (!_fastView) {
        _fastView                     = [[UIView alloc] init];
        _fastView.backgroundColor     = RGBA(0, 0, 0, 0.8);
        _fastView.layer.cornerRadius  = 4;
        _fastView.layer.masksToBounds = YES;
    }
    return _fastView;
}

- (UIImageView *)fastImageView {
    if (!_fastImageView) {
        _fastImageView = [[UIImageView alloc] init];
    }
    return _fastImageView;
}

- (UILabel *)fastTimeLabel {
    if (!_fastTimeLabel) {
        _fastTimeLabel               = [[UILabel alloc] init];
        _fastTimeLabel.textColor     = [UIColor whiteColor];
        _fastTimeLabel.textAlignment = NSTextAlignmentCenter;
        _fastTimeLabel.font          = [UIFont systemFontOfSize:14.0];
    }
    return _fastTimeLabel;
}

- (UIProgressView *)fastProgressView {
    if (!_fastProgressView) {
        _fastProgressView                   = [[UIProgressView alloc] init];
        _fastProgressView.progressTintColor = RGBA(89, 182, 215, 1);
        _fastProgressView.trackTintColor    = [UIColor clearColor];
    }
    return _fastProgressView;
}

- (UIImageView *)placeholderImageView {
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] init];
        _placeholderImageView.userInteractionEnabled = YES;
        _placeholderImageView.contentScaleFactor = UIScreen.mainScreen.scale;
        _placeholderImageView.contentMode = UIViewContentModeScaleAspectFill;
        _placeholderImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _placeholderImageView.clipsToBounds = YES;
    }
    return _placeholderImageView;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGRect rect = [self thumbRect];
    CGPoint point = [touch locationInView:self.videoSlider];
    if ([touch.view isKindOfClass:[UISlider class]]) { // 如果在滑块上点击就不响应pan手势
        if (point.x <= rect.origin.x + rect.size.width && point.x >= rect.origin.x) { return NO; }
    }
    return YES;
}

#pragma mark - Public method

/** 重置ControlView */
- (void)zf_playerResetControlView {
    [self.activity stopAnimatingWhite];
    self.videoSlider.value           = 0;
    self.progressView.progress       = 0;
    self.currentTimeLabel.text       = @"00:00";
    self.totalTimeLabel.text         = @"00:00";
    self.fastView.hidden             = YES;
    self.repeatBtn.hidden            = YES;
    self.shareBtn.hidden = YES;
    self.repeatLabel.hidden = YES;
    self.shareLabel.hidden = YES;
    self.resolutionView.hidden       = YES;
    self.failBtn.hidden              = YES;
    self.failLabel.hidden = YES;
    self.backgroundColor             = [UIColor clearColor];
    self.downLoadBtn.enabled         = YES;
    self.shrink                      = NO;
    self.showing                     = NO;
    self.playeEnd                    = NO;
    self.placeholderImageView.alpha  = 1;
    [self hideControlView];
}

- (void)zf_playerResetControlViewForResolution {
    self.fastView.hidden        = YES;
    self.repeatBtn.hidden       = YES;
    self.shareBtn.hidden = YES;
    self.repeatLabel.hidden = YES;
    self.shareLabel.hidden = YES;
    self.resolutionView.hidden  = YES;
    self.downLoadBtn.enabled    = YES;
    self.failBtn.hidden         = YES;
    self.failLabel.hidden = YES;
    self.backgroundColor        = [UIColor clearColor];
    self.shrink                 = NO;
    self.showing                = NO;
    self.playeEnd               = NO;
    self.placeholderImageView.alpha  = 1;
}

/**
 *  取消延时隐藏controlView的方法
 */
- (void)zf_playerCancelAutoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

/** 设置播放模型 */
- (void)zf_playerModel:(ZFPlayerModel *)playerModel {

    // 设置网络占位图片
    if (playerModel.placeholderImageURLString) {
        [self.placeholderImageView setImageWithURLString:playerModel.placeholderImageURLString placeholder:ZFPlayerImage(@"ZFPlayer_loading_bgView")];
    } else {
        self.placeholderImageView.image = playerModel.placeholderImage;
    }
    if (playerModel.resolutionDic) {
        [self zf_playerResolutionArray:[playerModel.resolutionDic allKeys]];
    }
}

/** 正在播放（隐藏placeholderImageView） */
- (void)zf_playerItemPlaying {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.placeholderImageView.alpha = 0;
        });
    });
}

- (void)zf_playerShowOrHideControlView {
    if (self.isShowing) {
        [self zf_playerHideControlView];
    } else {
        [self zf_playerShowControlView];
    }
}
/**
 *  显示控制层
 */
- (void)zf_playerShowControlView {
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlViewWillShow:isFullscreen:)]) {
        [self.zfDelegate zf_controlViewWillShow:self isFullscreen:[self currentIsFullScreen]];
    }
    [self zf_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self showControlView];
    } completion:^(BOOL finished) {
        self.showing = YES;
        [self autoFadeOutControlView];
    }];
}

/**
 *  隐藏控制层
 */
- (void)zf_playerHideControlView {
    if ([self.zfDelegate respondsToSelector:@selector(zf_controlViewWillHidden:isFullscreen:)]) {
        [self.zfDelegate zf_controlViewWillHidden:self isFullscreen:[self currentIsFullScreen]];
    }
    [self zf_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self hideControlView];
    } completion:^(BOOL finished) {
        self.showing = NO;
    }];
}

/** 小屏播放 */
- (void)zf_playerBottomShrinkPlay {
    self.shrink = YES;
    [self hideControlView];
}

/** 在cell播放 */
- (void)zf_playerCellPlay {
    self.cellVideo = YES;
    self.shrink    = NO;
}

- (void)zf_playerCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value {
    // 当前时长进度progress
    NSInteger proMin = currentTime / 60;//当前秒
    NSInteger proSec = currentTime % 60;//当前分钟
    // duration 总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟
    if (!self.isDragged) {
        // 更新slider
        self.videoSlider.value           = value;
        // 更新当前播放时间
        self.currentTimeLabel.text       = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    }
    // 更新总时间
    self.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
}

- (void)zf_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview {
    // 快进快退时候停止菊花
    [self.activity stopAnimatingWhite];
    // 拖拽的时长
    NSInteger proMin = draggedTime / 60;//当前秒
    NSInteger proSec = draggedTime % 60;//当前分钟
    
    //duration 总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟
    
    NSString *currentTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    NSString *totalTimeStr   = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    CGFloat  draggedValue    = (CGFloat)draggedTime/(CGFloat)totalTime;
    NSString *timeStr        = [NSString stringWithFormat:@"%@ / %@", currentTimeStr, totalTimeStr];
    
    // 显示、隐藏预览窗
    self.videoSlider.popUpView.hidden = !preview;
    // 更新slider的值
    self.videoSlider.value            = draggedValue;
    // 更新当前时间
    self.currentTimeLabel.text        = currentTimeStr;
    // 正在拖动控制播放进度
    self.dragged = YES;
    
    if (forawrd) {
        self.fastImageView.image = ZFPlayerImage(@"ZFPlayer_fast_forward");
    } else {
        self.fastImageView.image = ZFPlayerImage(@"ZFPlayer_fast_backward");
    }
    self.fastView.hidden           = preview;
    self.fastTimeLabel.text        = timeStr;
    self.fastProgressView.progress = draggedValue;
    
}

- (void)zf_playerDraggedEnd {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.fastView.hidden = YES;
    });
    self.dragged = NO;
    // 结束滑动时候把开始播放按钮改为播放状态
    self.startBtn.selected = YES;
    // 滑动结束延时隐藏controlView
    [self autoFadeOutControlView];
}

- (void)zf_playerDraggedTime:(NSInteger)draggedTime sliderImage:(UIImage *)image; {
    // 拖拽的时长
    NSInteger proMin = draggedTime / 60;//当前秒
    NSInteger proSec = draggedTime % 60;//当前分钟
    NSString *currentTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    [self.videoSlider setImage:image];
    [self.videoSlider setText:currentTimeStr];
    self.fastView.hidden = YES;
}

/** progress显示缓冲进度 */
- (void)zf_playerSetProgress:(CGFloat)progress {
    [self.progressView setProgress:progress animated:NO];
}

/** 视频加载失败 */
- (void)zf_playerItemStatusFailed:(NSError *)error {
    self.failBtn.hidden = NO;
    self.failLabel.hidden = NO;
}

/** 加载的菊花 */
- (void)zf_playerActivity:(BOOL)animated {
    if (animated) {
        [self.activity startAnimatingWhite];
        self.fastView.hidden = YES;
    } else {
        [self.activity stopAnimatingWhite];
    }
}

/** 播放完了 */
- (void)zf_playerPlayEnd {
    self.repeatBtn.hidden = NO;
    self.shareBtn.hidden = NO;
    self.repeatLabel.hidden = NO;
    self.shareLabel.hidden = NO;
    self.playeEnd         = YES;
    self.showing          = NO;
    if ([self currentIsFullScreen] == YES) {
        self.topImageView.hidden = NO;
        self.backBtn.hidden = NO;
    } else {
        self.topImageView.hidden = YES;
        self.backBtn.hidden = YES;
    }
    // 隐藏controlView
    [self hideControlView];
    self.backgroundColor  = RGBA(0, 0, 0, .3);
    ZFPlayerShared.isStatusBarHidden = NO;
}

/**
 是否有下载功能
 */
- (void)zf_playerHasDownloadFunction:(BOOL)sender {
    self.downLoadBtn.hidden = !sender;
}

/**
 是否有切换分辨率功能
 */
- (void)zf_playerResolutionArray:(NSArray *)resolutionArray {
    self.resolutionBtn.hidden = NO;
    
    _resolutionArray = resolutionArray;
    [_resolutionBtn setTitle:resolutionArray.firstObject forState:UIControlStateNormal];
    // 添加分辨率按钮和分辨率下拉列表
    self.resolutionView = [[UIView alloc] init];
    self.resolutionView.hidden = YES;
    self.resolutionView.backgroundColor = RGBA(0, 0, 0, 0.7);
    [self addSubview:self.resolutionView];
    
    [self.resolutionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(25*resolutionArray.count);
        make.leading.equalTo(self.resolutionBtn.mas_leading).offset(0);
        make.top.equalTo(self.resolutionBtn.mas_bottom).offset(0);
    }];
    
    // 分辨率View上边的Btn
    for (NSInteger i = 0 ; i < resolutionArray.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.layer.borderColor = [UIColor whiteColor].CGColor;
        btn.layer.borderWidth = 0.5;
        btn.tag = 200+i;
        btn.frame = CGRectMake(0, 25*i, 40, 25);
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        [btn setTitle:resolutionArray[i] forState:UIControlStateNormal];
        if (i == 0) {
            self.resoultionCurrentBtn = btn;
            btn.selected = YES;
            btn.backgroundColor = RGBA(86, 143, 232, 1);
        }
        [self.resolutionView addSubview:btn];
        [btn addTarget:self action:@selector(changeResolution:) forControlEvents:UIControlEventTouchUpInside];
    }
}

/** 播放按钮状态 */
- (void)zf_playerPlayBtnState:(BOOL)state {
    self.startBtn.selected = state;
}

/** 下载按钮状态 */
- (void)zf_playerDownloadBtnState:(BOOL)state {
    self.downLoadBtn.enabled = state;
}

#pragma clang diagnostic pop

@end

