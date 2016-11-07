//
//  ZFTableViewController.m
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ZFTableViewController.h"
#import "ZFPlayerCell.h"
#import "ZFVideoModel.h"
#import "ZFVideoResolution.h"
#import <Masonry/Masonry.h>
#import <ZFDownload/ZFDownloadManager.h>
#import "SDWebImageManager.h"
#import "ZFPlayer.h"

@interface ZFTableViewController () <ZFPlayerDelegate>

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) ZFPlayerView   *playerView;
@property (nonatomic, strong) ZFPlayerModel  *playerModel;

@end

@implementation ZFTableViewController

#pragma mark - life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 379.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self requestData];
}

// 页面消失时候
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.playerView resetPlayer];
}

- (void)requestData
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"videoData" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    self.dataSource = @[].mutableCopy;
    NSArray *videoList = [rootDict objectForKey:@"videoList"];
    for (NSDictionary *dataDic in videoList) {
        ZFVideoModel *model = [[ZFVideoModel alloc] init];
        [model setValuesForKeysWithDictionary:dataDic];
        [self.dataSource addObject:model];
    }

}

#pragma mark - 转屏相关

// 是否支持自动转屏
- (BOOL)shouldAutorotate
{
    // 调用ZFPlayerSingleton单例记录播放状态是否锁定屏幕方向
    return !ZFPlayerShared.isLockScreen;
    
}

// 支持哪些转屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (ZFPlayerShared.isAllowLandscape) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

// 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        self.view.backgroundColor = [UIColor whiteColor];
    }else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        self.view.backgroundColor = [UIColor blackColor];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *identifier        = @"playerCell";
    ZFPlayerCell *cell                 = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    // 取到对应cell的model
    __block ZFVideoModel *model        = self.dataSource[indexPath.row];
    // 赋值model
    cell.model                         = model;
    
    __block NSIndexPath *weakIndexPath = indexPath;
    __block ZFPlayerCell *weakCell     = cell;
    __weak typeof(self) weakSelf       = self;
    // 点击播放的回调
    cell.playBlock = ^(UIButton *btn){
        
        // 分辨率字典（key:分辨率名称，value：分辨率url)
        NSMutableDictionary *dic = @{}.mutableCopy;
        for (ZFVideoResolution * resolution in model.playInfo) {
            [dic setValue:resolution.url forKey:resolution.name];
        }
        // 取出字典中的第一视频URL
        NSURL *videoURL = [NSURL URLWithString:dic.allValues.firstObject];
        
        weakSelf.playerModel = [[ZFPlayerModel alloc] init];
        weakSelf.playerModel.title            = model.title;
        weakSelf.playerModel.videoURL         = videoURL;
        weakSelf.playerModel.placeholderImage = [weakSelf getPreviewImage:model.coverForFeed];
        weakSelf.playerModel.tableView        = weakSelf.tableView;
        weakSelf.playerModel.indexPath        = weakIndexPath;
        // 赋值分辨率字典
        weakSelf.playerModel.resolutionDic    = dic;
        // (需要设置imageView的tag值，此处设置的为101)
        weakSelf.playerModel.cellImageViewTag = weakCell.picView.tag;
        
        // 设置播放model
        weakSelf.playerView.playerModel = weakSelf.playerModel;
        
        [weakSelf.playerView addPlayerToCellImageView:weakCell.picView];

        //（可选设置）可以设置视频的填充模式，默认为（等比例填充，直到一个维度到达区域边界）
        // weakSelf.playerView.playerLayerGravity = ZFPlayerLayerGravityResizeAspect;
        // 自动播放
        [weakSelf.playerView autoPlayTheVideo];
    };

    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath---%zd",indexPath.row);
}

- (UIImage *)getPreviewImage:(NSString *)url
{
    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:url];
    if (!image) {
        image = [UIImage imageNamed:@"loading_bgView1"];
    }
    return image;
}

- (ZFPlayerView *)playerView
{
    if (!_playerView) {
        _playerView = [ZFPlayerView sharedPlayerView];
        _playerView.delegate = self;
        ZFPlayerControlView *controlView = [[ZFPlayerControlView alloc] init];
        _playerView.controlView = controlView;
        // 下载功能
        _playerView.hasDownload = YES;
    }
    return _playerView;
}

#pragma mark - ZFPlayerDelegate

- (void)zf_playerDownload:(NSString *)url
{
    // 此处是截取的下载地址，可以自己根据服务器的视频名称来赋值
    NSString *name = [url lastPathComponent];
    [[ZFDownloadManager sharedDownloadManager] downFileUrl:url filename:name fileimage:nil];
    // 设置最多同时下载个数（默认是3）
    [ZFDownloadManager sharedDownloadManager].maxCount = 4;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
