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


#import <Foundation/Foundation.h>
#import "ZFCommonHelper.h"
#import "ZFDownloadDelegate.h"
#import "ZFFileModel.h"
#import "ZFHttpRequest.h"

#define kMaxRequestCount  @"kMaxRequestCount"

@interface ZFDownloadManager : NSObject<ZFHttpRequestDelegate>

/** 获得下载事件的vc，用在比如多选图片后批量下载的情况，这时需配合 allowNextRequest 协议方法使用 */
@property (nonatomic, weak  ) id<ZFDownloadDelegate> VCdelegate;
/** 下载列表delegate */
@property (nonatomic, weak  ) id<ZFDownloadDelegate> downloadDelegate;
/** 设置最大的并发下载个数 */
@property (nonatomic, assign) NSInteger              maxCount;
/** 已下载完成的文件列表（文件对象） */
@property (atomic, strong, readonly) NSMutableArray  *finishedlist;
/** 正在下载的文件列表(ASIHttpRequest对象) */
@property (atomic, strong, readonly) NSMutableArray  *downinglist;
/** 未下载完成的临时文件数组（文件对象) */
@property (atomic, strong, readonly) NSMutableArray  *filelist;
/** 下载文件的模型 */
@property (nonatomic, strong, readonly) ZFFileModel  *fileInfo;

/** 单例 */
+ (ZFDownloadManager *)sharedDownloadManager;
/** 
 * 清除所有正在下载的请求
 */
- (void)clearAllRquests;
/** 
 * 清除所有下载完的文件
 */
- (void)clearAllFinished;
/** 
 * 恢复下载
 */
- (void)resumeRequest:(ZFHttpRequest *)request;
/**
 * 删除这个下载请求
 */
- (void)deleteRequest:(ZFHttpRequest *)request;
/** 
 * 停止这个下载请求
 */
- (void)stopRequest:(ZFHttpRequest *)request;
/** 
 * 保存下载完成的文件信息到plist
 */
- (void)saveFinishedFile;
/** 
 * 删除某一个下载完成的文件
 */
- (void)deleteFinishFile:(ZFFileModel *)selectFile;
/** 
 * 下载视频时候调用
 */
- (void)downFileUrl:(NSString*)url
           filename:(NSString*)name
          fileimage:(UIImage *)image;
/** 
 * 开始任务 
 */
- (void)startLoad;
/** 
 * 全部开始（等于最大下载个数，超过的还是等待下载状态）
 */
- (void)startAllDownloads;
/**
 * 全部暂停 
 */
- (void)pauseAllDownloads;

@end


