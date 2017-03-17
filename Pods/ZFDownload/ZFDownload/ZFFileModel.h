//
//  ZFFileModel.h
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
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,ZFDownLoadState) {
    ZFDownloading,      //下载中
    ZFWillDownload,     //等待下载
    ZFStopDownload      //停止下载
};

@interface ZFFileModel : NSObject

/** 文件名 */
@property (nonatomic, copy) NSString        *fileName;
/** 文件的总长度 */
@property (nonatomic, copy) NSString        *fileSize;
/** 文件的类型(文件后缀,比如:mp4)*/
@property (nonatomic, copy) NSString        *fileType;
/** 是否是第一次接受数据，如果是则不累加第一次返回的数据长度，之后变累加 */
@property (nonatomic, assign) BOOL          isFirstReceived;
/** 文件已下载的长度 */
@property (nonatomic, copy) NSString        *fileReceivedSize;
/** 接受的数据 */
@property (nonatomic, strong) NSMutableData *fileReceivedData;
/** 下载文件的URL */
@property (nonatomic, copy) NSString        *fileURL;
/** 下载时间 */
@property (nonatomic, copy) NSString        *time;
/** 临时文件路径 */
@property (nonatomic, copy) NSString        *tempPath;
/** 下载速度 */
@property (nonatomic, copy) NSString        *speed;
/** 开始下载的时间 */
@property (nonatomic, strong) NSDate        *startTime;
/** 剩余下载时间 */
@property (nonatomic, copy) NSString        *remainingTime;

/*下载状态的逻辑是这样的：三种状态，下载中，等待下载，停止下载
 *当超过最大下载数时，继续添加的下载会进入等待状态，当同时下载数少于最大限制时会自动开始下载等待状态的任务。
 *可以主动切换下载状态
 *所有任务以添加时间排序。
 */
@property (nonatomic, assign) ZFDownLoadState downloadState;
/** 是否下载出错 */
@property (nonatomic, assign) BOOL            error;
/** md5 */
@property (nonatomic, copy) NSString          *MD5;
/** 文件的附属图片 */
@property (nonatomic,strong) UIImage          *fileimage;

@end
