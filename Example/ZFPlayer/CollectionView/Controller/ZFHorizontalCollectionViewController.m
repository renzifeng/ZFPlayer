//
//  ZFHorizontalCollectionViewController.m
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2018/11/22.
//  Copyright © 2018 紫枫. All rights reserved.
//

#import "ZFHorizontalCollectionViewController.h"
#import "ZFCollectionViewCell.h"
#import "ZFTableData.h"
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/KSMediaPlayerManager.h>
#import <ZFPlayer/UIView+ZFFrame.h>

static NSString * const reuseIdentifier = @"collectionViewCell";

@interface ZFHorizontalCollectionViewController () <UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) NSMutableArray <ZFTableData *>*dataSource;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFPlayerControlView *controlView;
@property (nonatomic, strong) UILabel *markLabel;

@end

@implementation ZFHorizontalCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.markLabel];
    [self.view addSubview:self.collectionView];
    [self requestData];
    
    /// playerManager
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
    
    /// player的tag值必须在cell里设置
    self.player = [ZFPlayerController playerWithScrollView:self.collectionView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    self.player.assetURLs = self.urls;
    self.player.shouldAutoPlay = YES;
    self.player.disablePanMovingDirection = ZFPlayerDisablePanMovingDirectionAll;
    /// 1.0是消失100%时候
    self.player.playerDisapperaPercent = 1.0;
    
    @zf_weakify(self)
    self.player.orientationWillChange = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @zf_strongify(self)
        [self setNeedsStatusBarAppearanceUpdate];
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
    CGFloat width = self.view.frame.size.width;
    CGFloat height = width*9/16;
    CGFloat y = 0;
    self.collectionView.frame = CGRectMake(0, y, width, height);
    self.collectionView.center = self.view.center;
    
    self.markLabel.frame = CGRectMake(0, self.collectionView.frame.origin.y-50, 100, 20);
    self.markLabel.zf_centerX = self.view.zf_centerX;
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
    if (self.player.isFullScreen) {
        return UIStatusBarStyleLightContent;
    }
    return UIStatusBarStyleDefault;
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

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    [self.player playTheIndexPath:indexPath];
    ZFTableData *data = self.dataSource[indexPath.row];
    [self.controlView showTitle:data.title
                 coverURLString:data.thumbnail_url
                 fullScreenMode:ZFFullScreenModeLandscape];
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
    ZFCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.data = self.dataSource[indexPath.row];
    @zf_weakify(self)
    cell.playBlock = ^(UIButton *sender) {
        @zf_strongify(self)
        [self playTheVideoAtIndexPath:indexPath];
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath];
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemWidth = self.view.frame.size.width;
        CGFloat itemHeight = itemWidth*9/16;
        layout.itemSize = CGSizeMake(itemWidth, itemHeight);
        layout.sectionInset = UIEdgeInsetsZero;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        /// 横向滚动 这行代码必须写
        _collectionView.zf_scrollViewDirection = ZFPlayerScrollViewDirectionHorizontal;
        [_collectionView registerClass:[ZFCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
        _collectionView.pagingEnabled = YES;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    return _collectionView;
}

- (ZFPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFPlayerControlView new];
        _controlView.fastViewAnimated = YES;
        _controlView.effectViewShow = NO;
        _controlView.customDisablePanMovingDirection = YES;
    }
    return _controlView;
}

- (UILabel *)markLabel {
    if (!_markLabel) {
        _markLabel = [UILabel new];
        _markLabel.text = @"请横向滚动";
    }
    return _markLabel;
}

@end
