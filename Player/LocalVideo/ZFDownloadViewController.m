//
//  ZFDownloadViewController.m
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

#import "ZFDownloadViewController.h"
#import "MoviePlayerViewController.h"
#import "ZFPlayer.h"
#import "ZFDownloadingCell.h"
#import "ZFDownloadedCell.h"

@interface ZFDownloadViewController ()<ZFDownloadDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic  ) IBOutlet UITableView    *tableView;
@property (atomic, strong) NSMutableArray *downloadObjectArr;
@end

@implementation ZFDownloadViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    // 更新数据源
    [self initData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, -49, 0);
    // NSLog(@"%@", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES));
}

- (void)initData
{
    NSMutableArray *downloads = [[ZFDownloadManager sharedInstance] getSessionModels].mutableCopy;
    NSMutableArray *downladed = @[].mutableCopy;
    NSMutableArray *downloading = @[].mutableCopy;
    for (ZFSessionModel *obj in downloads) {
        if ([[ZFDownloadManager sharedInstance] isCompletion:obj.url]) {
            [downladed addObject:obj];
        }else {
            [downloading addObject:obj];
        }
    }
    _downloadObjectArr = @[].mutableCopy;
    [_downloadObjectArr addObject:downladed];
    [_downloadObjectArr addObject:downloading];

    [self.tableView reloadData];
}

#pragma mark - ZFDownloadDelegate

- (void)downloadResponse:(ZFSessionModel *)sessionModel
{
    if (self.downloadObjectArr) {
        // 取到对应的cell上的model
        NSArray *downloadings = self.downloadObjectArr[1];
        for (ZFSessionModel *model in downloadings) {
            if ([model.url isEqualToString:sessionModel.url]) {
                // 取到当前下载model在数组的位置，来确定cell的具体位置
                NSInteger index = [downloadings indexOfObject:model];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
                __block ZFDownloadingCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                __weak typeof(self) weakSelf = self;
                sessionModel.progressBlock = ^(CGFloat progress, NSString *speed, NSString *remainingTime, NSString *writtenSize, NSString *totalSize) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.progressLabel.text = [NSString stringWithFormat:@"%@/%@ (%.2f%%)",writtenSize,totalSize,progress*100];
                        cell.speedLabel.text    = speed;
                        cell.progress.progress  = progress;
                    });
                };
                sessionModel.stateBlock = ^(DownloadState state){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (state == DownloadStateStart) {
                            [cell addDownloadAnimation];
                        }else if (state == DownloadStateCompleted) {
                            // 更新数据源
                            [weakSelf initData];
                            [cell removeDownloadAnimtion];
                        }else if (state == DownloadStateSuspended) {
                            [cell removeDownloadAnimtion];
                            cell.speedLabel.text = @"已暂停";
                        }
                    });
                };
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
   
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = self.downloadObjectArr[section];
    return sectionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block ZFSessionModel *downloadObject = self.downloadObjectArr[indexPath.section][indexPath.row];
    if (indexPath.section == 0) {
        ZFDownloadedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadedCell"];
        cell.sessionModel = downloadObject;
        return cell;
    }else if (indexPath.section == 1) {
        ZFDownloadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadingCell"];
        cell.sessionModel = downloadObject;
        [ZFDownloadManager sharedInstance].delegate = self;
        cell.downloadBlock = ^ {
            [[ZFDownloadManager sharedInstance] download:downloadObject.url progress:^(CGFloat progress, NSString *speed, NSString *remainingTime, NSString *writtenSize, NSString *totalSize) {} state:^(DownloadState state) {}];
        };
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *downloadArray = _downloadObjectArr[indexPath.section];
    ZFSessionModel * downloadObject = downloadArray[indexPath.row];
    // 根据url删除该条数据
    [[ZFDownloadManager sharedInstance] deleteFile:downloadObject.url];
    [downloadArray removeObject:downloadObject];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @[@"下载完成",@"下载中"][section];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UITableViewCell *cell            = (UITableViewCell *)sender;
    NSIndexPath *indexPath           = [self.tableView indexPathForCell:cell];
    ZFSessionModel *model            = self.downloadObjectArr[indexPath.section][indexPath.row];
    NSURL *videoURL                  = [NSURL fileURLWithPath:ZFFileFullpath(model.fileName)];

    MoviePlayerViewController *movie = (MoviePlayerViewController *)segue.destinationViewController;
    movie.videoURL                   = videoURL;
}


@end
