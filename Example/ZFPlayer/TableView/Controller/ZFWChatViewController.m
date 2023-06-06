//
//  ZFWChatViewController.m
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2020/7/11.
//  Copyright © 2020 紫枫. All rights reserved.
//

#import "ZFWChatViewController.h"
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFIJKPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/UIView+ZFFrame.h>
#import "ZFTableViewCell.h"
#import "ZFTableData.h"
#import <AVFoundation/AVFoundation.h>
#import "ZFWeChatControlView.h"

static NSString *kIdentifier = @"kIdentifier";

@interface ZFWChatViewController () <UITableViewDelegate,UITableViewDataSource,ZFTableViewCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFWeChatControlView *controlView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ZFWChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:self.tableView];
    [self requestData];
    
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
//    ZFIJKPlayerManager *playerManager = [[ZFIJKPlayerManager alloc] init];
    playerManager.scalingMode = ZFPlayerScalingModeAspectFill;

    
    /// player的tag值必须在cell里设置
    self.player = [ZFPlayerController playerWithScrollView:self.tableView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    /// 0.4是消失40%时候
    self.player.playerDisappearPercent = 0.4;
    /// 0.6是出现60%时候
    self.player.playerAppearPercent = 0.6;
    /// 移动网络依然自动播放
    self.player.WWANAutoPlay = YES;
    /// 续播
    self.player.resumePlayRecord = YES;
    /// 禁止掉滑动手势
    self.player.disableGestureTypes = ZFPlayerDisableGestureTypesPan;
    /// 竖屏的全屏
    self.player.orientationObserver.fullScreenMode = ZFFullScreenModePortrait;
    /// 隐藏全屏的状态栏
    self.player.orientationObserver.fullScreenStatusBarHidden = YES;
    self.player.orientationObserver.fullScreenStatusBarAnimation = UIStatusBarAnimationNone;

    /// 全屏的填充模式（全屏填充、按视频大小填充）
    self.player.orientationObserver.portraitFullScreenMode = ZFPortraitFullScreenModeScaleAspectFit;
    /// 禁用竖屏全屏的手势（点击、拖动手势）
    self.player.orientationObserver.disablePortraitGestureTypes = ZFDisablePortraitGestureTypesNone;

    @zf_weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @zf_strongify(self)
        [self.player.currentPlayerManager replay];
    };
    
    /// 停止的时候找出最合适的播放
    self.player.zf_scrollViewDidEndScrollingCallback = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (!self.player.playingIndexPath) {
            [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
        }
    };
    
    /// 滑动中找到适合的就自动播放
    /// 如果是停止后再寻找播放可以忽略这个回调
    /// 如果在滑动中就要寻找到播放的indexPath，并且开始播放，那就要这样写
    self.player.zf_playerShouldPlayInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if ([indexPath compare:self.player.playingIndexPath] != NSOrderedSame) {
            [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
        }
    };
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat h = CGRectGetMaxY(self.view.frame);
    self.tableView.frame = CGRectMake(0, y, self.view.frame.size.width, h-y);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    @zf_weakify(self)
    [self.player zf_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @zf_strongify(self)
        [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
    }];
}

- (void)requestData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    self.dataSource = @[].mutableCopy;
    NSArray *videoList = [rootDict objectForKey:@"list"];
    for (NSDictionary *dataDic in videoList) {
        ZFTableData *data = [[ZFTableData alloc] init];
        [data setValuesForKeysWithDictionary:dataDic];
        ZFTableViewCellLayout *layout = [[ZFTableViewCellLayout alloc] initWXData:data];
        [self.dataSource addObject:layout];
    }
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - UIScrollViewDelegate 列表播放必须实现

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [scrollView zf_scrollViewDidEndDecelerating];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [scrollView zf_scrollViewDidEndDraggingWillDecelerate:decelerate];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [scrollView zf_scrollViewDidScrollToTop];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [scrollView zf_scrollViewDidScroll];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [scrollView zf_scrollViewWillBeginDragging];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
    cell.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    [cell setDelegate:self withIndexPath:indexPath];
    cell.layout = self.dataSource[indexPath.row];
    [cell setNormalMode];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZFTableViewCellLayout *layout = self.dataSource[indexPath.row];
    return layout.height;
}

#pragma mark - ZFTableViewCellDelegate

- (void)zf_playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
    [self.player enterPortraitFullScreen:YES animated:YES];
}

#pragma mark - private method

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollAnimated:(BOOL)animated {
    ZFTableViewCellLayout *layout = self.dataSource[indexPath.row];
    if (animated) {
         [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:layout.data.video_url] scrollPosition:ZFPlayerScrollViewScrollPositionCenteredVertically animated:YES];
     } else {
         [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:layout.data.video_url]];
     }
    
    [self.controlView showCoverViewWithUrl:layout.data.thumbnail_url];
    CGSize videoSize = CGSizeMake(layout.data.video_width, layout.data.video_height);
    self.player.currentPlayerManager.presentationSize = videoSize;
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_tableView registerClass:[ZFTableViewCell class] forCellReuseIdentifier:kIdentifier];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
    }
    return _tableView;
}

- (ZFWeChatControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFWeChatControlView new];
    }
    return _controlView;
}



@end
