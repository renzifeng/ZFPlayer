//
//  ZFDownloadManager.m
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

#import "ZFDownloadManager.h"

@interface ZFDownloadManager()<NSCopying, NSURLSessionDelegate>

/** 保存所有任务(注：用下载地址/后作为key) */
@property (nonatomic, strong) NSMutableDictionary *tasks;
/** 保存所有下载相关信息 */
@property (nonatomic, strong) NSMutableDictionary *sessionModels;
/** 所有本地存储的下载信息数据 */
@property (nonatomic, strong) NSMutableArray *sessionModelsArray;
@end

@implementation ZFDownloadManager

- (NSMutableDictionary *)tasks
{
    if (!_tasks) {
        _tasks = [NSMutableDictionary dictionary];
    }
    return _tasks;
}

- (NSMutableDictionary *)sessionModels
{
    if (!_sessionModels) {
        _sessionModels = [NSMutableDictionary dictionary];
    }
    return _sessionModels;
}

- (NSMutableArray *)sessionModelsArray
{
    if (!_sessionModelsArray) {
        _sessionModelsArray = @[].mutableCopy;
        [_sessionModelsArray addObjectsFromArray:[self getSessionModels]];
    }
    return _sessionModelsArray;
}


static ZFDownloadManager *_downloadManager;

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _downloadManager = [super allocWithZone:zone];
    });
    
    return _downloadManager;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    return _downloadManager;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [[self alloc] init];
    });
    
    return _downloadManager;
}

/**
 * 归档
 */
- (void)save:(NSArray *)sessionModels
{
    [NSKeyedArchiver archiveRootObject:sessionModels toFile:ZFDownloadDetailPath];
}

/**
 * 读取model
 */
- (NSArray *)getSessionModels
{
    // 文件信息
    NSArray *sessionModels = [NSKeyedUnarchiver unarchiveObjectWithFile:ZFDownloadDetailPath];
    return sessionModels;
}


/**
 *  创建缓存目录文件
 */
- (void)createCacheDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:ZFCachesDirectory]) {
        [fileManager createDirectoryAtPath:ZFCachesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

/**
 *  开启任务下载资源
 */
- (void)download:(NSString *)url progress:(ZFDownloadProgressBlock)progressBlock state:(ZFDownloadStateBlock)stateBlock
{
    if (!url) return;
    if ([self isCompletion:url]) {
        stateBlock(DownloadStateCompleted);
        NSLog(@"----该资源已下载完成");
        return;
    }
    
    // 暂停
    if ([self.tasks valueForKey:ZFFileName(url)]) {
        [self handle:url];
        return;
    }
    
    // 创建缓存目录文件
    [self createCacheDirectory];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    // 创建流
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:ZFFileFullpath(url) append:YES];
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    // 设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", ZFDownloadLength(url)];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    // 创建一个Data任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    // 保存任务
    [self.tasks setValue:task forKey:ZFFileName(url)];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:ZFFileFullpath(url)]) {
        ZFSessionModel *sessionModel = [[ZFSessionModel alloc] init];
        sessionModel.url = url;
        sessionModel.progressBlock = progressBlock;
        sessionModel.stateBlock = stateBlock;
        sessionModel.stream = stream;
        sessionModel.startTime = [NSDate date];
        sessionModel.fileName = ZFFileName(url);
        [self.sessionModels setValue:sessionModel forKey:@(task.taskIdentifier).stringValue];
        [self.sessionModelsArray addObject:sessionModel];
        // 保存
        [self save:self.sessionModelsArray];
    }else {
        for (ZFSessionModel *sessionModel in self.sessionModelsArray) {
            if ([sessionModel.url isEqualToString:url]) {
                sessionModel.url = url;
                sessionModel.progressBlock = progressBlock;
                sessionModel.stateBlock = stateBlock;
                sessionModel.stream = stream;
                sessionModel.startTime = [NSDate date];
                sessionModel.fileName = ZFFileName(url);
                [self.sessionModels setValue:sessionModel forKey:@(task.taskIdentifier).stringValue];
            }
        }
    }
    [self start:url];
}


- (void)handle:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    if (task.state == NSURLSessionTaskStateRunning) {
        [self pause:url];
    } else {
        [self start:url];
    }
}

/**
 *  开始下载
 */
- (void)start:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    [task resume];
    
    [self getSessionModel:task.taskIdentifier].stateBlock(DownloadStateStart);
}

/**
 *  暂停下载
 */
- (void)pause:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    [task suspend];
    
    [self getSessionModel:task.taskIdentifier].stateBlock(DownloadStateSuspended);
}

/**
 *  根据url获得对应的下载任务
 */
- (NSURLSessionDataTask *)getTask:(NSString *)url
{
    return (NSURLSessionDataTask *)[self.tasks valueForKey:ZFFileName(url)];
}

/**
 *  根据url获取对应的下载信息模型
 */
- (ZFSessionModel *)getSessionModel:(NSUInteger)taskIdentifier
{
    return (ZFSessionModel *)[self.sessionModels valueForKey:@(taskIdentifier).stringValue];
}

/**
 *  判断该文件是否下载完成
 */
- (BOOL)isCompletion:(NSString *)url
{
    if ([self fileTotalLength:url] && ZFDownloadLength(url) == [self fileTotalLength:url]) {
        return YES;
    }
    return NO;
}

/**
 *  查询该资源的下载进度值
 */
- (CGFloat)progress:(NSString *)url
{
    return [self fileTotalLength:url] == 0 ? 0.0 : 1.0 * ZFDownloadLength(url) /  [self fileTotalLength:url];
}

/**
 *  获取该资源总大小
 */
- (NSInteger)fileTotalLength:(NSString *)url
{
    for (ZFSessionModel *model in self.sessionModelsArray) {
        if ([model.url isEqualToString:url]) {
            return model.totalLength;
        }
    }
    return 0;
}

#pragma mark - 删除
/**
 *  删除该资源
 */
- (void)deleteFile:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    if (task) {
        // 取消下载
        [task cancel];
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:ZFFileFullpath(url)]) {
        // 删除沙盒中的资源
        [fileManager removeItemAtPath:ZFFileFullpath(url) error:nil];
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:ZFDownloadDetailPath]) {
            // 从沙盒中移除该条模型的信息
            for (ZFSessionModel *model in self.sessionModelsArray.mutableCopy) {
                if ([model.url isEqualToString:url]) {
                    // 关闭流
                    [model.stream close];
                    [self.sessionModelsArray removeObject:model];
                }
            }
        }
        // 删除任务
        [self.tasks removeObjectForKey:ZFFileName(url)];
        [self.sessionModels removeObjectForKey:@([self getTask:url].taskIdentifier).stringValue];
        // 保存归档信息
        [self save:self.sessionModelsArray];
    }
}

/**
 *  清空所有下载资源
 */
- (void)deleteAllFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:ZFCachesDirectory]) {

        // 删除沙盒中所有资源
        [fileManager removeItemAtPath:ZFCachesDirectory error:nil];
        // 删除任务
        [[self.tasks allValues] makeObjectsPerformSelector:@selector(cancel)];
        [self.tasks removeAllObjects];
        
        for (ZFSessionModel *sessionModel in [self.sessionModels allValues]) {
            [sessionModel.stream close];
        }
        [self.sessionModels removeAllObjects];
        
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:ZFDownloadDetailPath]) {
            [fileManager removeItemAtPath:ZFDownloadDetailPath error:nil];
            [self.sessionModelsArray removeAllObjects];
            self.sessionModelsArray = nil;
        }
    }
}

- (BOOL)isFileDownloadingForUrl:(NSString *)url withProgressBlock:(ZFDownloadProgressBlock)progressBlock
{
    BOOL retValue = NO;
    NSURLSessionDataTask *task = [self getTask:url];
    ZFSessionModel *session = [self getSessionModel:task.taskIdentifier];
    if (session) {
        if (progressBlock) {
            session.progressBlock = progressBlock;
        }
        retValue = YES;
    }
    return retValue;
}

- (NSArray *)currentDownloads {
    NSMutableArray *currentDownloads = [NSMutableArray new];
    [self.sessionModels enumerateKeysAndObjectsUsingBlock:^(id key, ZFSessionModel *download, BOOL *stop) {
        [currentDownloads addObject:download.url];
    }];
    return currentDownloads;
}

#pragma mark NSURLSessionDataDelegate

/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    ZFSessionModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 打开流
    [sessionModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + ZFDownloadLength(sessionModel.url);
    sessionModel.totalLength = totalLength;
    
    // 总文件大小
    NSString *fileSizeInUnits = [NSString stringWithFormat:@"%.2f %@",
                                 [sessionModel calculateFileSizeInUnit:(unsigned long long)totalLength],
                                 [sessionModel calculateUnit:(unsigned long long)totalLength]];
    sessionModel.totalSize = fileSizeInUnits;
    // 更新数据(文件总长度)
    [self save:self.sessionModelsArray];

    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    ZFSessionModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 写入数据
    [sessionModel.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSUInteger receivedSize = ZFDownloadLength(sessionModel.url);
    NSUInteger expectedSize = sessionModel.totalLength;
    CGFloat progress = 1.0 * receivedSize / expectedSize;
    
    // 每秒下载速度
    NSTimeInterval downloadTime = -1 * [sessionModel.startTime timeIntervalSinceNow];
    NSUInteger speed = receivedSize / downloadTime;
    if (speed == 0) { return; }
    float speedSec = [sessionModel calculateFileSizeInUnit:(unsigned long long) speed];
    NSString *unit = [sessionModel calculateUnit:(unsigned long long) speed];
    NSString *speedStr = [NSString stringWithFormat:@"%.2f%@/s",speedSec,unit];
    
    // 剩余下载时间
    NSMutableString *remainingTimeStr = [[NSMutableString alloc] init];
    unsigned long long remainingContentLength = expectedSize - receivedSize;
    int remainingTime = (int)(remainingContentLength / speed);
    int hours = remainingTime / 3600;
    int minutes = (remainingTime - hours * 3600) / 60;
    int seconds = remainingTime - hours * 3600 - minutes * 60;
    
    if(hours>0) {[remainingTimeStr appendFormat:@"%d 小时 ",hours];}
    if(minutes>0) {[remainingTimeStr appendFormat:@"%d 分 ",minutes];}
    if(seconds>0) {[remainingTimeStr appendFormat:@"%d 秒",seconds];}
    
    NSString *writtenSize = [NSString stringWithFormat:@"%.2f %@",
                                 [sessionModel calculateFileSizeInUnit:(unsigned long long)receivedSize],
                                 [sessionModel calculateUnit:(unsigned long long)receivedSize]];
    
    // 下载中
    if (sessionModel.stateBlock) {
        sessionModel.stateBlock(DownloadStateStart);
    }
    if (sessionModel.progressBlock) {
        sessionModel.progressBlock(progress, speedStr, remainingTimeStr,writtenSize, sessionModel.totalSize);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(downloadResponse:)]) {
            [self.delegate downloadResponse:sessionModel];
        }
    });
}

/**
 * 请求完毕（成功|失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    ZFSessionModel *sessionModel = [self getSessionModel:task.taskIdentifier];
    if (!sessionModel) return;
    
    if ([self isCompletion:sessionModel.url]) {
        // 下载完成
        sessionModel.stateBlock(DownloadStateCompleted);
    } else if (error){
        // 下载失败
        sessionModel.stateBlock(DownloadStateFailed);
    }
    
    // 关闭流
    [sessionModel.stream close];
    sessionModel.stream = nil;
    
    // 清除任务
    [self.tasks removeObjectForKey:ZFFileName(sessionModel.url)];
    [self.sessionModels removeObjectForKey:@(task.taskIdentifier).stringValue];
}

@end
