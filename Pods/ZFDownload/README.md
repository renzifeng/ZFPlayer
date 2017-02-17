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
// 设置代理<ZFDownloadDelegate>
self.downloadManage.downloadDelegate = self;
// 指定下载URL,文件名称...
[[ZFDownloadManager sharedDownloadManager] downFileUrl:urlStr filename:name fileimage:nil];
// 设置最多同时下载个数（默认是3）
[ZFDownloadManager sharedDownloadManager].maxCount = 2;

```
在cell上获取实时下载进度，遵守 ZFDownloadDelegate代理，然后实现

```objc

#pragma mark - ZFDownloadDelegate

// 开始下载
- (void)startDownload:(ZFHttpRequest *)request;

// 下载中
- (void)updateCellProgress:(ZFHttpRequest *)request;

// 下载完成
- (void)finishedDownload:(ZFHttpRequest *)request;


```

# 联系我
- 微博: [@任子丰](https://weibo.com/zifeng1300)
- 邮箱: zifeng1300@gmail.com
- QQ群：213376937

# License

ZFDownload is available under the MIT license. See the LICENSE file for more info.