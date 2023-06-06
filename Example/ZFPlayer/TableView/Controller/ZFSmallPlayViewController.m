//
//  ZFSmallPlayViewController.m
//  ZFPlayer
//
//  Created by 任子丰 on 2018/4/1.
//  Copyright © 2018年 紫枫. All rights reserved.
//

#import "ZFSmallPlayViewController.h"
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/ZFIJKPlayerManager.h>
#import <ZFPlayer/UIView+ZFFrame.h>
#import <ZFPlayer/ZFPlayerConst.h>
#import "ZFPlayerDetailViewController.h"
#import "ZFUtilities.h"
#import "ZFTableViewCell.h"
#import "ZFTableData.h"
#import "ZFAutoPlayerViewController.h"

static NSString *kIdentifier = @"kIdentifier";

@interface ZFSmallPlayViewController () <UITableViewDelegate,UITableViewDataSource,ZFTableViewCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFPlayerControlView *controlView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UIActivityIndicatorView *activity;

@end

@implementation ZFSmallPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.activity];
    [self requestData];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Push" style:UIBarButtonItemStylePlain target:self action:@selector(pushNewVC)];
    
    /// playerManager
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
//    ZFIJKPlayerManager *playerManager = [[ZFIJKPlayerManager alloc] init];
    
    /// player的tag值必须在cell里设置
    self.player = [ZFPlayerController playerWithScrollView:self.tableView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    /// 移动网络依然自动播放
    self.player.WWANAutoPlay = YES;
    
    /// 1.0是完全消失的时候 
    self.player.playerDisappearPercent = 1.0;
    /// 0.0是刚开始显示的时候
    self.player.playerAppearPercent = 0.0;

    @zf_weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @zf_strongify(self)
        [self.controlView resetControlView];
        [self.player stopCurrentPlayingCell];
    };
    
    /// 停止的时候找出最合适的播放
    self.player.zf_scrollViewDidEndScrollingCallback = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (!self.player.playingIndexPath) {
            [self playTheVideoAtIndexPath:indexPath];
        }
    };
  
    /// 以下设置滑出屏幕后不停止播放
    self.player.stopWhileNotVisible = NO;
    
    CGFloat margin = 20;
    CGFloat w = ZFPlayer_ScreenWidth/2;
    CGFloat h = w * 9/16;
    CGFloat x = ZFPlayer_ScreenWidth - w - margin;
    CGFloat y = ZFPlayer_ScreenHeight - h - margin;
    self.player.smallFloatView.frame = CGRectMake(x, y, w, h);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.player.viewControllerDisappear = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.player.viewControllerDisappear = YES;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat h = CGRectGetMaxY(self.view.frame)-y;
    self.tableView.frame = CGRectMake(0, y, self.view.frame.size.width, h);
    self.activity.center = self.view.center;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (!parent) {
        self.tableView.delegate = nil;
        [self.player stopCurrentPlayingCell];
    }
}

- (void)requestData {
    [self.activity startAnimating];
    @zf_weakify(self)
    /// 模拟网络请求
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.activity stopAnimating];
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
        [self.tableView reloadData];
        
        /// 找到可播放的cell
        [self.player zf_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
            @zf_strongify(self)
            [self playTheVideoAtIndexPath:indexPath];
        }];
    });
}

- (void)pushNewVC {
    ZFAutoPlayerViewController *autoVC = [[ZFAutoPlayerViewController alloc] init];
    [self.navigationController pushViewController:autoVC animated:YES];
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
    [cell setDelegate:self withIndexPath:indexPath];
    cell.layout = self.dataSource[indexPath.row];
    [cell setNormalMode];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /// 如果正在播放的index和当前点击的index不同，则停止当前播放的index
    if (self.player.playingIndexPath != indexPath) {
        [self.player stopCurrentPlayingCell];
    }
    /// 如果没有播放，则点击进详情页会自动播放
    if (!self.player.currentPlayerManager.isPlaying) {
        [self playTheVideoAtIndexPath:indexPath];
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
    [self playTheVideoAtIndexPath:indexPath];
}

#pragma mark - private method

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    ZFTableViewCellLayout *layout = self.dataSource[indexPath.row];
    [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:layout.data.video_url]];
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
        _tableView.tableFooterView = [UIView new];
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

- (ZFPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFPlayerControlView new];
    }
    return _controlView;
}

- (UIActivityIndicatorView *)activity {
    if (!_activity) {
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activity.hidesWhenStopped = YES;
    }
    return _activity;
}

@end

