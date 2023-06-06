//
//  ZFDouyinCollectionViewController.m
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2019/6/4.
//  Copyright © 2019 紫枫. All rights reserved.
//

#import "ZFDouyinCollectionViewController.h"
#import "ZFDouyinCollectionViewCell.h"
#import "ZFTableData.h"
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/UIView+ZFFrame.h>
#import <ZFPlayer/ZFPlayerConst.h>
#import "UINavigationController+FDFullscreenPopGesture.h"
#import "ZFDouYinControlView.h"
#import "ZFDouYinCellDelegate.h"
#import "ZFCustomControlView.h"

static NSString * const reuseIdentifier = @"collectionViewCell";

@interface ZFDouyinCollectionViewController () <UICollectionViewDelegate,UICollectionViewDataSource,ZFDouYinCellDelegate>

@property (nonatomic, strong) NSMutableArray <ZFTableData *>*dataSource;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFDouYinControlView *controlView;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) ZFCustomControlView *fullControlView;

@end

@implementation ZFDouyinCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fd_prefersNavigationBarHidden = YES;
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.backBtn];
    [self requestData];
    
    /// playerManager
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
    
    /// player的tag值必须在cell里设置
    self.player = [ZFPlayerController playerWithScrollView:self.collectionView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    self.player.shouldAutoPlay = YES;
    self.player.allowOrientationRotation = NO;
    self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionAll;
    /// 1.0是消失100%时候
    self.player.playerDisappearPercent = 1.0;
    
    @zf_weakify(self)
    self.player.orientationWillChange = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @zf_strongify(self)
        if (isFullScreen) {
            self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionNone;
        } else {
            self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionAll;
        }
        self.player.controlView.hidden = YES;
    };
    
    self.player.orientationDidChanged = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @zf_strongify(self)
        self.player.controlView.hidden = NO;
        if (isFullScreen) {
            self.player.controlView = self.fullControlView;
        } else {
            self.player.controlView = self.controlView;
        }
    };
    
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @zf_strongify(self)
        [self.player.currentPlayerManager replay];
    };
    
    /// 停止的时候找出最合适的播放
    self.player.zf_scrollViewDidEndScrollingCallback = ^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        [self playTheVideoAtIndexPath:indexPath];
    };
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.backBtn.frame = CGRectMake(15, CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame), 36, 36);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    @zf_weakify(self)
    [self.player zf_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @zf_strongify(self)
        [self playTheVideoAtIndexPath:indexPath];
    }];
}

#pragma mark - 转屏和状态栏

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - private method

- (void)requestData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    self.dataSource = @[].mutableCopy;
    NSArray *videoList = [rootDict objectForKey:@"list"];
    for (NSDictionary *dataDic in videoList) {
        ZFTableData *data = [[ZFTableData alloc] init];
        [data setValuesForKeysWithDictionary:dataDic];
        [self.dataSource addObject:data];
    }
}

- (void)playTheIndex:(NSInteger)index {
    @zf_weakify(self)
    /// 指定到某一行播放
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    [self.player zf_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @zf_strongify(self)
        [self playTheVideoAtIndexPath:indexPath];
    }];
    /// 如果是最后一行，去请求新数据
    if (index == self.dataSource.count-1) {
        /// 加载下一页数据
        [self requestData];
        [self.collectionView reloadData];
    }
}

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    ZFTableData *data = self.dataSource[indexPath.row];
    [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:data.video_url]];
    [self.controlView resetControlView];
    [self.controlView showCoverViewWithUrl:data.thumbnail_url];
    [self.fullControlView showTitle:@"custom landscape controlView" coverURLString:data.thumbnail_url fullScreenMode:ZFFullScreenModeLandscape];
}

- (void)backClick:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
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

#pragma mark - ZFDouYinCellDelegate

- (void)zf_douyinRotation {
    UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
    if (self.player.isFullScreen) {
        orientation = UIInterfaceOrientationPortrait;
    } else {
        orientation = UIInterfaceOrientationLandscapeRight;
    }
    [self.player rotateToOrientation:orientation animated:YES completion:nil];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZFDouyinCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.data = self.dataSource[indexPath.row];
    cell.delegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath];
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemWidth = self.view.frame.size.width;
        CGFloat itemHeight = self.view.frame.size.height;
        layout.itemSize = CGSizeMake(itemWidth, itemHeight);
        layout.sectionInset = UIEdgeInsetsZero;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        if (self.scrollViewDirection == ZFPlayerScrollViewDirectionVertical) {
            layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        } else if (self.scrollViewDirection == ZFPlayerScrollViewDirectionHorizontal) {
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        }
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        /// 横向滚动 这行代码必须写
        _collectionView.zf_scrollViewDirection = self.scrollViewDirection;
        [_collectionView registerClass:[ZFDouyinCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
        _collectionView.pagingEnabled = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.scrollsToTop = NO;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    return _collectionView;
}

- (ZFDouYinControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFDouYinControlView new];
    }
    return _controlView;
}

- (ZFCustomControlView *)fullControlView {
    if (!_fullControlView) {
        _fullControlView = [[ZFCustomControlView alloc] init];
    }
    return _fullControlView;
}

- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"icon_titlebar_whiteback"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

@end
