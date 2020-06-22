//
//  ZFTableHeaderViewController.m
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2018/10/30.
//  Copyright © 2018 紫枫. All rights reserved.
//

#import "ZFTableHeaderViewController.h"
#import "ZFTableHeaderView.h"
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/KSMediaPlayerManager.h>
#import <ZFPlayer/ZFIJKPlayerManager.h>
#import <ZFPlayer/UIView+ZFFrame.h>
#import "ZFPlayerDetailViewController.h"
#import "ZFTableData.h"
#import "ZFOtherCell.h"
#import "ZFUtilities.h"

static NSString *kIdentifier = @"kIdentifier";

@interface ZFTableHeaderViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ZFTableHeaderView *headerView;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFPlayerControlView *controlView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ZFTableHeaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    
    [self requestData];
    
    self.tableView.tableHeaderView = self.headerView;
    self.headerView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width*9/16);
    
    /// playerManager
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
    /// player的tag值必须在cell里设置
    self.player = [ZFPlayerController playerWithScrollView:self.tableView playerManager:playerManager containerView:self.headerView.coverImageView];
    self.player.playerDisapperaPercent = 1.0;
    self.player.playerApperaPercent = 0.0;
    self.player.stopWhileNotVisible = NO;
    CGFloat margin = 20;
    CGFloat w = ZFPlayer_ScreenWidth/2;
    CGFloat h = w * 9/16;
    CGFloat x = ZFPlayer_ScreenWidth - w - margin;
    CGFloat y = ZFPlayer_ScreenHeight - h - margin;
    self.player.smallFloatView.frame = CGRectMake(x, y, w, h);
    self.player.controlView = self.controlView;
    
    @zf_weakify(self)
    self.player.orientationWillChange = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @zf_strongify(self)
        kAPPDelegate.allowOrentitaionRotation = isFullScreen;
        [self setNeedsStatusBarAppearanceUpdate];
        if (!isFullScreen) {
            /// 解决导航栏上移问题
            self.navigationController.navigationBar.zf_height = KNavBarHeight;
        }
        self.tableView.scrollsToTop = !isFullScreen;
    };
    
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @zf_strongify(self)
        [self.player stopCurrentPlayingCell];
    };
    
    [self playTheIndex:0];
}

- (void)requestData {
    self.dataSource = @[].mutableCopy;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    NSArray *videoList = [rootDict objectForKey:@"list"];
    for (NSDictionary *dataDic in videoList) {
        ZFTableData *data = [[ZFTableData alloc] init];
        [data setValuesForKeysWithDictionary:dataDic];
        [self.dataSource addObject:data];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat h = CGRectGetMaxY(self.view.frame);
    self.tableView.frame = CGRectMake(0, y, self.view.frame.size.width, h-y);
}

- (BOOL)shouldAutorotate {
    return self.player.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.player.isFullScreen && self.player.orientationObserver.fullScreenMode == ZFFullScreenModeLandscape) {
        return UIInterfaceOrientationMaskLandscape;
    }
    return UIInterfaceOrientationMaskPortrait;
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [scrollView zf_scrollViewDidScroll];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZFOtherCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
    cell.textLabel.text = [NSString stringWithFormat:@"点击播放第%zd个视频",indexPath.row + 1];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheIndex:indexPath.row];
}

#pragma mark - private

- (void)playTheIndex:(NSInteger)index {
    /// 在这里判断能否播放。。。
    ZFTableData *data = self.dataSource[index];
    self.player.currentPlayerManager.assetURL = [NSURL URLWithString:data.video_url];
    [self.controlView showTitle:data.title coverURLString:data.thumbnail_url fullScreenMode:ZFFullScreenModeLandscape];
    
    if (self.tableView.contentOffset.y > self.headerView.frame.size.height) {
        [self.player addPlayerViewToKeyWindow];
    } else {
        [self.player addPlayerViewToContainerView:self.headerView.coverImageView];
    }
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_tableView registerClass:[ZFOtherCell class] forCellReuseIdentifier:kIdentifier];
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
        _tableView.rowHeight = 100;
    }
    return _tableView;
}

- (ZFPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFPlayerControlView new];
        _controlView.fastViewAnimated = YES;
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
}

- (ZFTableHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[ZFTableHeaderView alloc] init];
        @zf_weakify(self)
        _headerView.playCallback = ^{
            @zf_strongify(self)
            [self playTheIndex:0];
        };
    }
    return _headerView;
}

@end
