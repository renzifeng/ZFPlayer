# ZFDownload

<p align="left">
<a href="https://travis-ci.org/renzifeng/ZFDownload"><img src="https://travis-ci.org/renzifeng/ZFDownload.svg?branch=master"></a>
<a href="https://img.shields.io/cocoapods/v/ZFDownload.svg"><img src="https://img.shields.io/cocoapods/v/ZFDownload.svg"></a>
<a href="https://img.shields.io/cocoapods/v/ZFDownload.svg"><img src="https://img.shields.io/github/license/renzifeng/ZFDownload.svg?style=flat"></a>
<a href="http://cocoadocs.org/docsets/ZFDownload"><img src="https://img.shields.io/cocoapods/p/ZFDownload.svg?style=flat"></a>
<a href="http://weibo.com/zifeng1300"><img src="https://img.shields.io/badge/weibo-@%E4%BB%BB%E5%AD%90%E4%B8%B0-yellow.svg?style=flat"></a>
</p>

## 特性
* 支持断点下载
* 异常退出，再次打开保留下载进度
* 实时下载进度
* 实时下载速度

## 要求
* iOS 7+
* Xcode 6+

---
#### ZFDownload的具体实现，可以看ZFPlayer，已获取1000多颗star：[ZFPlayer](https://github.com/renzifeng/ZFPlayer)
---

## 效果图

![图片效果演示](https://github.com/renzifeng/ZFDownload/raw/master/ZFDownload.gif)

## 安装
### Cocoapods

```ruby
pod 'ZFDownload'
```

## 使用
```objc
 [[ZFDownloadManager sharedInstance] download:urlString progress:^(CGFloat progress, NSString *speed, NSString *remainingTime, NSString *writtenSize, NSString *totalSize) {
            dispatch_async(dispatch_get_main_queue(), ^{
				// insert code here
            });
 } state:^(DownloadState state) {}];

```
在cell上获取实时下载进度，遵守 ZFDownloadDelegate代理，然后实现

```objc
#pragma mark - ZFDownloadDelegate

- (void)downloadResponse:(ZFSessionModel *)sessionModel
{
    if (self.downloadObjectArr) {
        // 取到对应的cell上的model
        NSArray *downloadings = self.downloadObjectArr[1];
        if ([downloadings containsObject:sessionModel]) {
            
            NSInteger index = [downloadings indexOfObject:sessionModel];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
            __block ZFDownloadingCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            sessionModel.progressBlock = ^(CGFloat progress, NSString *speed, NSString *remainingTime, NSString *writtenSize, NSString *totalSize) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.progressLabel.text   = [NSString stringWithFormat:@"%@/%@ (%.2f%%)",writtenSize,totalSize,progress*100];
                    cell.speedLabel.text      = speed;
                    cell.progress.progress    = progress;
                    cell.downloadBtn.selected = YES;
                });
            };
            
            sessionModel.stateBlock = ^(DownloadState state){
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 更新数据源
                    if (state == DownloadStateCompleted) {
                        [weakSelf initData];
                        cell.downloadBtn.selected = NO;
                    }
                    // 暂停
                    if (state == DownloadStateSuspended) {
                        cell.speedLabel.text = @"已暂停";
                        cell.downloadBtn.selected = NO;
                    }
                });
            };
        }
    }
}
```

# 联系我
- 微博: [@任子丰](https://weibo.com/zifeng1300)
- 邮箱: zifeng1300@gmail.com
- QQ群：213376937

# License

ZFDownload is available under the MIT license. See the LICENSE file for more info.