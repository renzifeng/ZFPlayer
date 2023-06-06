//
//  ZFLightTableViewController.m
//  ZFPlayer
//
//  Created by 任子丰 on 2018/4/1.
//  Copyright © 2018年 紫枫. All rights reserved.
//

#import "ZFLightTableViewController.h"
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFIJKPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/UIView+ZFFrame.h>
#import <ZFPlayer/ZFPlayerConst.h>
#import "ZFPlayerDetailViewController.h"
#import "ZFTableViewCellLayout.h"
#import "ZFTableViewCell.h"
#import "ZFTableData.h"

static NSString *kIdentifier = @"kIdentifier";

@interface ZFLightTableViewController () <UITableViewDelegate,UITableViewDataSource,ZFTableViewCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFPlayerControlView *controlView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ZFLightTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self requestData];
    
    /// playerManager
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
//    ZFIJKPlayerManager *playerManager = [[ZFIJKPlayerManager alloc] init];
    
    /// player的tag值必须在cell里设置
    self.player = [ZFPlayerController playerWithScrollView:self.tableView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    /// 消失比例停止播放
    self.player.playerDisappearPercent = 0.2;
    self.player.playerAppearPercent = 0.8;
    
    /// 移动网络依然自动播放
    self.player.WWANAutoPlay = YES;
    
    @zf_weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @zf_strongify(self)
        if (self.player.playingIndexPath.row < self.dataSource.count - 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.player.playingIndexPath.row+1 inSection:0];
            [self playTheVideoAtIndexPath:indexPath scrollAnimated:YES];
        } else {
            [self.player stopCurrentPlayingCell];
        }
    };
    
    self.player.zf_playerShouldPlayInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (indexPath == nil) { /// 没有找到可以播放视频
            /// 显示黑色蒙版
            ZFTableViewCell *cell1 = [self.tableView cellForRowAtIndexPath:self.player.shouldPlayIndexPath];
            [cell1 showMaskView];
        }
        
        /// 用来控制cell明暗的
        if ([indexPath compare:self.player.shouldPlayIndexPath] != NSOrderedSame) {
            /// 显示黑色蒙版
            ZFTableViewCell *cell1 = [self.tableView cellForRowAtIndexPath:self.player.shouldPlayIndexPath];
            [cell1 showMaskView];
            /// 隐藏黑色蒙版
            ZFTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [cell hideMaskView];
                
        }
        /// 如果当前播放的和找到的是同一个indexPath,则忽略
        if ([indexPath compare:self.player.playingIndexPath] != NSOrderedSame) {
            /// 滑动中找到适合的就自动播放，如果是停止后在寻找播放可以忽略这句
            /// 如果在滑动中就要寻找到播放indexPath，并且开始播放，那就要这样写
            [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
        }
    };
    
    /// 停止的时候找出最合适的播放
    self.player.zf_scrollViewDidEndScrollingCallback = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (!self.player.playingIndexPath) {
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
        ZFTableViewCellLayout *layout = [[ZFTableViewCellLayout alloc] initWithData:data];
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

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

#pragma mark - UIScrollViewDelegate  列表播放必须实现

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
    [cell setDelegate:self withIndexPath:indexPath];
    cell.layout = self.dataSource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /// 如果正在播放的index和当前点击的index不同，则停止当前播放的index
    if (self.player.playingIndexPath != indexPath) {
        [self.player stopCurrentPlayingCell];
    }
    /// 如果没有播放，则点击进详情页会自动播放
    if (!self.player.currentPlayerManager.isPlaying) {
        [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
    }
    /// 到详情页
    ZFPlayerDetailViewController *detailVC = [ZFPlayerDetailViewController new];
    detailVC.player = self.player;
    /// 详情页返回的回调
    detailVC.detailVCPopCallback = ^{
        [self.player addPlayerViewToCell];
    };
    /// 详情页点击播放的回调
    detailVC.detailVCPlayCallback = ^{
        [self zf_playTheVideoAtIndexPath:indexPath];
    };
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZFTableViewCellLayout *layout = self.dataSource[indexPath.row];
    return layout.height;
}

#pragma mark - ZFTableViewCellDelegate

- (void)zf_playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollAnimated:YES];
}

#pragma mark - private method

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollAnimated:(BOOL)animated {
    ZFTableViewCellLayout *layout = self.dataSource[indexPath.row];
    if (animated) {
        [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:layout.data.video_url] scrollPosition:ZFPlayerScrollViewScrollPositionTop animated:YES];
    } else {
        [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:layout.data.video_url]];
    }
    [self.controlView showTitle:layout.data.title
                 coverURLString:layout.data.thumbnail_url
                 fullScreenMode:layout.isVerticalVideo?ZFFullScreenModePortrait:ZFFullScreenModeLandscape];
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
        _tableView.separatorColor = [UIColor darkGrayColor];
        [[UITableView appearance] setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [[UITableView appearance] setSeparatorInset:UIEdgeInsetsZero];
        [[UITableViewCell appearance] setSeparatorInset:UIEdgeInsetsZero];
        if ([UITableView instancesRespondToSelector:@selector(setLayoutMargins:)]) {
            [[UITableView appearance] setLayoutMargins:UIEdgeInsetsZero];
            [[UITableViewCell appearance] setLayoutMargins:UIEdgeInsetsZero];
            [[UITableViewCell appearance] setPreservesSuperviewLayoutMargins:NO];
        }
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
    }
    return _tableView;
}

- (ZFPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFPlayerControlView new];
        _controlView.fastViewAnimated = YES;
        _controlView.horizontalPanShowControlView = NO;
        _controlView.showCustomStatusBar = YES;
    }
    return _controlView;
}

@end
