//
//  ZFMixViewController.m
//  ZFPlayer_Example
//
//  Created by 任子丰 on 2018/6/21.
//  Copyright © 2018年 紫枫. All rights reserved.
//

#import "ZFMixViewController.h"
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFIJKPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/UIView+ZFFrame.h>
#import <ZFPlayer/ZFPlayerConst.h>
#import "ZFPlayerDetailViewController.h"
#import "ZFTableViewCell.h"
#import "ZFTableData.h"
#import "ZFOtherCell.h"

static NSString *kIdentifier = @"kIdentifier";
static NSString *kDouYinIdentifier = @"douYinIdentifier";

@interface ZFMixViewController () <UITableViewDelegate,UITableViewDataSource,ZFTableViewCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFPlayerControlView *controlView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ZFMixViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self requestData];
    
    /// playerManager
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
//    ZFIJKPlayerManager *playerManager = [[ZFIJKPlayerManager alloc] init];
    
    /// player,tag值必须在cell里设置
    self.player = [ZFPlayerController playerWithScrollView:self.tableView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    /// 1.0是消失100%时候
    self.player.playerDisappearPercent = 0.8;
    /// 播放器view露出一半时候开始播放
    self.player.playerAppearPercent = .5;
    
    @zf_weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @zf_strongify(self)
        [self.player stopCurrentPlayingCell];
    };
    
    /// 停止的时候找出最合适的播放(只能找到设置了tag值cell)
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

#pragma mark - UIScrollViewDelegate   列表播放必须实现

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
    return 2*self.dataSource.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 3 == 1) {
        ZFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
        [cell setDelegate:self withIndexPath:indexPath];
        NSInteger index = (indexPath.row-1)/3;
        cell.layout = self.dataSource[index];
        [cell setNormalMode];
        return cell;
    }
    ZFOtherCell *cell = [tableView dequeueReusableCellWithIdentifier:kDouYinIdentifier];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 3 != 1)  return;
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
    if (indexPath.row % 3 == 1) {
        NSInteger index = (indexPath.row-1)/3;
        ZFTableViewCellLayout *layout = self.dataSource[index];
        return layout.height;
    }
    return 250;
}

#pragma mark - ZFTableViewCellDelegate

- (void)zf_playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
}

#pragma mark - private method

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollAnimated:(BOOL)animated {
    NSInteger index = (indexPath.row-1)/3;
    ZFTableViewCellLayout *layout = self.dataSource[index];
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
        [_tableView registerClass:[ZFOtherCell class] forCellReuseIdentifier:kDouYinIdentifier];
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

- (ZFPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFPlayerControlView new];
    }
    return _controlView;
}


@end
