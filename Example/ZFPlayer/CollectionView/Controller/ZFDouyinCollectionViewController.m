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
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/KSMediaPlayerManager.h>
#import <ZFPlayer/UIView+ZFFrame.h>
#import "UINavigationController+FDFullscreenPopGesture.h"
#import "ZFDouYinControlView.h"

static NSString * const reuseIdentifier = @"collectionViewCell";

@interface ZFDouyinCollectionViewController () <UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) NSMutableArray <ZFTableData *>*dataSource;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFDouYinControlView *controlView;
@property (nonatomic, strong) UIButton *backBtn;

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
    self.player.assetURLs = self.urls;
    self.player.shouldAutoPlay = YES;
    self.player.allowOrentitaionRotation = NO;
    self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionAll;
    /// 1.0是消失100%时候
    self.player.playerDisapperaPercent = 1.0;
    
    @zf_weakify(self)
    self.player.orientationWillChange = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @zf_strongify(self)
        kAPPDelegate.allowOrentitaionRotation = isFullScreen;
        [self setNeedsStatusBarAppearanceUpdate];
        if (!isFullScreen) {
            /// 解决导航栏上移问题
            self.navigationController.navigationBar.zf_height = KNavBarHeight;
        }
        self.collectionView.scrollsToTop = !isFullScreen;
        if (isFullScreen) {
            self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionNone;
        } else {
            self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionAll;
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
    /// 如果只是支持iOS9+ 那直接return NO即可，这里为了适配iOS8
    return self.player.isStatusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

#pragma mark - private method

- (void)requestData {
    self.urls = @[].mutableCopy;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    self.dataSource = @[].mutableCopy;
    NSArray *videoList = [rootDict objectForKey:@"list"];
    for (NSDictionary *dataDic in videoList) {
        ZFTableData *data = [[ZFTableData alloc] init];
        [data setValuesForKeysWithDictionary:dataDic];
        [self.dataSource addObject:data];
        NSURL *url = [NSURL URLWithString:data.video_url];
        [self.urls addObject:url];
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
        self.player.assetURLs = self.urls;
        [self.collectionView reloadData];
    }
}

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    [self.player playTheIndexPath:indexPath];
    [self.controlView resetControlView];
    ZFTableData *data = self.dataSource[indexPath.row];
    UIViewContentMode imageMode;
    if (data.thumbnail_width >= data.thumbnail_height) {
        imageMode = UIViewContentModeScaleAspectFit;
    } else {
        imageMode = UIViewContentModeScaleAspectFill;
    }
    [self.controlView showCoverViewWithUrl:data.thumbnail_url withImageMode:imageMode];
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

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZFDouyinCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.data = self.dataSource[indexPath.row];
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

- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"icon_titlebar_whiteback"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

@end
