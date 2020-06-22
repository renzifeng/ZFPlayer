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

@end

@implementation ZFKeyboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.containerView];
    [self.controlView addSubview:self.textField];
    
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
    
    /// 播放器相关
    self.player = [[ZFPlayerController alloc] initWithPlayerManager:playerManager containerView:self.containerView];
    /// 适配横屏键盘，这里强制横屏处理
    self.player.forceDeviceOrientation = YES;
    self.player.controlView = self.controlView;
    @zf_weakify(self)
    self.player.orientationWillChange = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @zf_strongify(self)
        self.view.backgroundColor = isFullScreen ? [UIColor blackColor] : [UIColor whiteColor];
        [self.textField resignFirstResponder];
        kAPPDelegate.allowOrentitaionRotation = isFullScreen;
        [self setNeedsStatusBarAppearanceUpdate];
        if (!isFullScreen) {
            /// 解决导航栏上移问题
            self.navigationController.navigationBar.zf_height = KNavBarHeight;
        }
    };
    
    NSString *URLString = [@"http://flv3.bn.netease.com/tvmrepo/2018/6/H/9/EDJTRBEH9/SD/EDJTRBEH9-mobile.mp4" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    playerManager.assetURL = [NSURL URLWithString:URLString];
    
    [self.controlView showTitle:@"视频标题" coverURLString:@"https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" fullScreenMode:ZFFullScreenModeLandscape];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect frame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSLog(@"%@",NSStringFromCGRect(frame));
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
    x = (self.containerView.zf_width - w)/2;
    y = (self.containerView.zf_height - h)/2;
    self.textField.frame = CGRectMake(x, y, w, h);
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
        _controlView.prepareShowControlView = YES;
        _controlView.prepareShowLoading = YES;
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
    }
    return _containerView;
}

@end
