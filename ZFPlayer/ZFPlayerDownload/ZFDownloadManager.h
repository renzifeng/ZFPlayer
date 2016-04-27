//
//  ZFDownloadManager.h
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

#import <UIKit/UIKit.h>
#import "ZFSessionModel.h"

// 缓存主目录
#define ZFCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]stringByAppendingPathComponent:@"ZFCache"]

// 保存文件名
#define ZFFileName(url)  [[url componentsSeparatedByString:@"/"] lastObject]

// 文件的存放路径（caches）
#define ZFFileFullpath(url) [ZFCachesDirectory stringByAppendingPathComponent:ZFFileName(url)]

// 文件的已下载长度
#define ZFDownloadLength(url) [[[NSFileManager defaultManager] attributesOfItemAtPath:ZFFileFullpath(url) error:nil][NSFileSize] integerValue]

// 存储文件信息的路径（caches）
#define ZFDownloadDetailPath [ZFCachesDirectory stringByAppendingPathComponent:@"downloadDetail.data"]

@protocol ZFDownloadDelegate <NSObject>
/** 下载中的回调 */
- (void)downloadResponse:(ZFSessionModel *)sessionModel;

@end

@interface ZFDownloadManager : NSObject

/** 保存所有下载相关信息 */
@property (nonatomic, strong, readonly) NSMutableDictionary *sessionModels;
/** ZFDownloadDelegate */
@property (nonatomic, assign) id<ZFDownloadDelegate> delegate;

/**
 *  单例
 *
 *  @return 返回单例对象
 */
+ (instancetype)sharedInstance;

/**
 * 归档
 */
- (void)save:(NSArray *)sessionModels;

/**
 * 读取model
 */
- (NSArray *)getSessionModels;

/**
 *  开启任务下载资源
 *
 *  @param url           下载地址
 *  @param progressBlock 回调下载进度
 *  @param stateBlock    下载状态
 */
- (void)download:(NSString *)url progress:(ZFDownloadProgressBlock)progressBlock state:(ZFDownloadStateBlock)stateBlock;

/**
 *  查询该资源的下载进度值
 *
 *  @param url 下载地址
 *
 *  @return 返回下载进度值
 */
- (CGFloat)progress:(NSString *)url;

/**
 *  获取该资源总大小
 *
 *  @param url 下载地址
 *
 *  @return 资源总大小
 */
- (NSInteger)fileTotalLength:(NSString *)url;

/**
 *  判断该资源是否下载完成
 *
 *  @param url 下载地址
 *
 *  @return YES: 完成
 */
- (BOOL)isCompletion:(NSString *)url;

/**
 *  删除该资源
 *
 *  @param url 下载地址
 */
- (void)deleteFile:(NSString *)url;

/**
 *  清空所有下载资源
 */
- (void)deleteAllFile;

/**
 *  开始下载
 */
- (void)start:(NSString *)url;

/**
 *  暂停下载
 */
- (void)pause:(NSString *)url;

/**
 *  判断当前url是否正在下载
 *
 *  @param url   视频url
 *  @param block 下载进度
 *
 *  @return 是否在下载
 */
- (BOOL)isFileDownloadingForUrl:(NSString *)url withProgressBlock:(ZFDownloadProgressBlock)block;

/**
 *  正在下载的视频URL的数组
 *
 *  @return 视频URL的数组
 */
- (NSArray *)currentDownloads;

@end
