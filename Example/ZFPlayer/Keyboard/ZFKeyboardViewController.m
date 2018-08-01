//
//  ZFKeyboardViewController.m
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2018/5/25.
//  Copyright © 2018年 紫枫. All rights reserved.
//

#import "ZFKeyboardViewController.h"
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/KSMediaPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/ZFIJKPlayerManager.h>
#import <ZFPlayer/UIView+ZFFrame.h>

@interface ZFKeyboardViewController ()
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) ZFPlayerControlView *controlView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *playBtn;

@end

@implementation ZFKeyboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.containerView];
    [self.containerView addSubview:self.playBtn];
    [self.controlView addSubview:self.textField];
    
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
//    KSMediaPlayerManager *playerManager = [[KSMediaPlayerManager alloc] init];
//    ZFIJKPlayerManager *playerManager = [[ZFIJKPlayerManager alloc] init];
    /// 播放器相关
//    self.player = [ZFPlayerController playerWithPlayerManager:playerManager containerView:self.containerView];
    self.player = [[ZFPlayerController alloc] initWithPlayerManager:playerManager containerView:self.containerView];

    self.player.controlView = self.controlView;
    @weakify(self)
    self.player.orientationWillChange = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self)
        [self.textField resignFirstResponder];
        [self setNeedsStatusBarAppearanceUpdate];
    };
    NSString *URLString = [@"http://flv3.bn.netease.com/tvmrepo/2018/6/H/9/EDJTRBEH9/SD/EDJTRBEH9-mobile.mp4" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    playerManager.playerSource = [NSURL URLWithString:URLString];
    
    [self.controlView showTitle:@"视频标题" coverURLString:@"https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" fullScreenMode:ZFFullScreenModeLandscape];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat x = 0;
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat w = CGRectGetWidth(self.view.frame);
    CGFloat h = w*9/16;
    self.containerView.frame = CGRectMake(x, y, w, h);
    
    w = 200;
    h = 35;
    x = (self.containerView.width - w)/2;
    y = (self.containerView.height - h)/2;
    self.textField.frame = CGRectMake(x, y, w, h);

    w = 44;
    h = w;
    x = (CGRectGetWidth(self.containerView.frame)-w)/2;
    y = (CGRectGetHeight(self.containerView.frame)-h)/2;
    self.playBtn.frame = CGRectMake(x, y, w, h);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.player.isFullScreen) {
        return UIStatusBarStyleLightContent;
    }
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return self.player.isStatusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (BOOL)shouldAutorotate {
    return self.player.shouldAutorotate;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.textField resignFirstResponder];
}

#pragma mark - about keyboard orientation

/// 键盘支持横屏，这里必须设置支持多个方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.player.isFullScreen) {
        return UIInterfaceOrientationMaskLandscape;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (ZFPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFPlayerControlView new];
    }
    return _controlView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.backgroundColor = [UIColor orangeColor];
        _textField.placeholder = @"Click on the input";
    }
    return _textField;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = [UIColor orangeColor];
    }
    return _containerView;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"new_allPlay_44x44_"] forState:UIControlStateNormal];
    }
    return _playBtn;
}

@end
