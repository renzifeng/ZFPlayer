//
//  UIImageView+ZFCache.m
//  ZFPlayer
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

#import "UIImageView+ZFCache.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

@implementation ZFImageDownloader

- (void)startDownloadImageWithUrl:(NSString *)url
                         progress:(ZFDownloadProgressBlock)progress
                         finished:(ZFDownLoadDataCallBack)finished {
    self.progressBlock = progress;
    self.callbackOnFinished = finished;
    
    if ([NSURL URLWithString:url] == nil) {
        if (finished) { finished(nil, nil); }
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                       timeoutInterval:60];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    self.session = [NSURLSession sessionWithConfiguration:config
                                                 delegate:self
                                            delegateQueue:queue];
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:request];
    [task resume];
    self.task = task;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSData *data = [NSData dataWithContentsOfURL:location];
    
    if (self.progressBlock) {
        self.progressBlock(self.totalLength, self.currentLength);
    }
    
    if (self.callbackOnFinished) {
        self.callbackOnFinished(data, nil);
        
        // 防止重复调用
        self.callbackOnFinished = nil;
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    self.currentLength = totalBytesWritten;
    self.totalLength = totalBytesExpectedToWrite;
    
    if (self.progressBlock) {
        self.progressBlock(self.totalLength, self.currentLength);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if ([error code] != NSURLErrorCancelled) {
        if (self.callbackOnFinished) {
            self.callbackOnFinished(nil, error);
        }
        self.callbackOnFinished = nil;
    }
}

@end

@interface NSString (md5)

+ (NSString *)cachedFileNameForKey:(NSString *)key;
+ (NSString *)zf_cachePath;
+ (NSString *)zf_keyForRequest:(NSURLRequest *)request;

@end

@implementation NSString (md5)

+ (NSString *)zf_keyForRequest:(NSURLRequest *)request{
    return request.URL.absoluteString;
}

+ (NSString *)zf_cachePath {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *directoryPath = [NSString stringWithFormat:@"%@/%@/%@",cachePath,@"default",@"com.hackemist.SDWebImageCache.default"];
    return directoryPath;
}

+ (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [[key pathExtension] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", [key pathExtension]]];
    
    return filename;
}

@end

@interface UIApplication (ZFCacheImage)

@property (nonatomic, strong, readonly) NSMutableDictionary *zf_cacheFaileTimes;

- (UIImage *)zf_cacheImageForRequest:(NSURLRequest *)request;
- (void)zf_cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request;
- (void)zf_cacheFailRequest:(NSURLRequest *)request;
- (NSUInteger)zf_failTimesForRequest:(NSURLRequest *)request;

@end

@implementation UIApplication (ZFCacheImage)

- (NSMutableDictionary *)zf_cacheFaileTimes {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
    }
    return dict;
}

- (void)setZf_cacheFaileTimes:(NSMutableDictionary *)zf_cacheFaileTimes {
    objc_setAssociatedObject(self, @selector(zf_cacheFaileTimes), zf_cacheFaileTimes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)zf_clearCache {
    [self.zf_cacheFaileTimes removeAllObjects];
    self.zf_cacheFaileTimes = nil;
}

- (void)zf_clearDiskCaches {
    NSString *directoryPath = [NSString zf_cachePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        dispatch_queue_t ioQueue = dispatch_queue_create("com.hackemist.SDWebImageCache", DISPATCH_QUEUE_SERIAL);
        dispatch_async(ioQueue, ^{
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
        });
    }
    [self zf_clearCache];
}

- (UIImage *)zf_cacheImageForRequest:(NSURLRequest *)request {
    if (request) {
        NSString *directoryPath = [NSString zf_cachePath];
        NSString *path = [NSString stringWithFormat:@"%@/%@", directoryPath, [NSString cachedFileNameForKey:[NSString zf_keyForRequest:request]]];
        return [UIImage imageWithContentsOfFile:path];
    }
    return nil;
}

- (NSUInteger)zf_failTimesForRequest:(NSURLRequest *)request {
    NSNumber *faileTimes = [self.zf_cacheFaileTimes objectForKey:[NSString cachedFileNameForKey:[NSString zf_keyForRequest:request]]];
    if (faileTimes && [faileTimes respondsToSelector:@selector(integerValue)]) {
        return faileTimes.integerValue;
    }
    return 0;
}

- (void)zf_cacheFailRequest:(NSURLRequest *)request {
    NSNumber *faileTimes = [self.zf_cacheFaileTimes objectForKey:[NSString cachedFileNameForKey:[NSString zf_keyForRequest:request]]];
    NSUInteger times = 0;
    if (faileTimes && [faileTimes respondsToSelector:@selector(integerValue)]) {
        times = [faileTimes integerValue];
    }
    
    times++;
    
    [self.zf_cacheFaileTimes setObject:@(times) forKey:[NSString cachedFileNameForKey:[NSString zf_keyForRequest:request]]];
}

- (void)zf_cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request {
    if (!image || !request) { return; }
    
    NSString *directoryPath = [NSString zf_cachePath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) { return; }
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/%@", directoryPath, [NSString cachedFileNameForKey:[NSString zf_keyForRequest:request]]];
    NSData *data = UIImagePNGRepresentation(image);
    if (data) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    }
}

@end


@implementation UIImageView (ZFCache)

#pragma mark - getter

- (ZFImageBlock)completion
{
    return objc_getAssociatedObject(self, _cmd);
}

- (ZFImageDownloader *)imageDownloader
{
    return objc_getAssociatedObject(self, _cmd);
}

- (NSUInteger)attemptToReloadTimesForFailedURL
{
    NSUInteger count = [objc_getAssociatedObject(self, _cmd) integerValue];
    if (count == 0) {  count = 2; }
    return count;
}

- (BOOL)shouldAutoClipImageToViewSize
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

#pragma mark - setter

- (void)setCompletion:(ZFImageBlock)completion
{
    objc_setAssociatedObject(self, @selector(completion), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setImageDownloader:(ZFImageDownloader *)imageDownloader
{
    objc_setAssociatedObject(self, @selector(imageDownloader), imageDownloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setAttemptToReloadTimesForFailedURL:(NSUInteger)attemptToReloadTimesForFailedURL
{
    objc_setAssociatedObject(self, @selector(attemptToReloadTimesForFailedURL), @(attemptToReloadTimesForFailedURL), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setShouldAutoClipImageToViewSize:(BOOL)shouldAutoClipImageToViewSize
{
    objc_setAssociatedObject(self, @selector(shouldAutoClipImageToViewSize), @(shouldAutoClipImageToViewSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - public method

- (void)setImageWithURLString:(NSString *)url
         placeholderImageName:(NSString *)placeholderImageName {
    return [self setImageWithURLString:url placeholderImageName:placeholderImageName completion:nil];
}

- (void)setImageWithURLString:(NSString *)url placeholder:(UIImage *)placeholderImage {
    return [self setImageWithURLString:url placeholder:placeholderImage completion:nil];
}

- (void)setImageWithURLString:(NSString *)url
         placeholderImageName:(NSString *)placeholderImage
                   completion:(void (^)(UIImage *image))completion {
    NSString *path = [[NSBundle mainBundle] pathForResource:placeholderImage ofType:nil];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if (image == nil) { image = [UIImage imageNamed:placeholderImage]; }
    
    [self setImageWithURLString:url placeholder:image completion:completion];
}

- (void)setImageWithURLString:(NSString *)url
                  placeholder:(UIImage *)placeholderImageName
                   completion:(void (^)(UIImage *image))completion {
    [self.layer removeAllAnimations];
    self.completion = completion;
    
    if (url == nil || [url isKindOfClass:[NSNull class]] || (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"])) {
        [self setImage:placeholderImageName isFromCache:YES];
        
        if (completion) {
            self.completion(self.image);
        }
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self downloadWithReqeust:request holder:placeholderImageName];
}

#pragma mark - private method

- (void)downloadWithReqeust:(NSURLRequest *)theRequest holder:(UIImage *)holder {
    UIImage *cachedImage = [[UIApplication sharedApplication] zf_cacheImageForRequest:theRequest];
    
    if (cachedImage) {
        [self setImage:cachedImage isFromCache:YES];
        if (self.completion) {
            self.completion(cachedImage);
        }
        return;
    }
    
    [self setImage:holder isFromCache:YES];
    
    if ([[UIApplication sharedApplication] zf_failTimesForRequest:theRequest] >= self.attemptToReloadTimesForFailedURL) {
        return;
    }
    
    [self cancelRequest];
    self.imageDownloader = nil;
    
    __weak __typeof(self) weakSelf = self;
    
    self.imageDownloader = [[ZFImageDownloader alloc] init];
    [self.imageDownloader startDownloadImageWithUrl:theRequest.URL.absoluteString progress:nil finished:^(NSData *data, NSError *error) {
        // success
        if (data != nil && error == nil) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                UIImage *image = [UIImage imageWithData:data];
                UIImage *finalImage = image;
                
                if (image) {
                    if (weakSelf.shouldAutoClipImageToViewSize) {
                        // cutting
                        if (fabs(weakSelf.frame.size.width - image.size.width) != 0
                            && fabs(weakSelf.frame.size.height - image.size.height) != 0) {
                            finalImage = [self clipImage:image toSize:weakSelf.frame.size isScaleToMax:YES];
                        }
                    }
                    
                    [[UIApplication sharedApplication] zf_cacheImage:finalImage forRequest:theRequest];
                } else {
                    [[UIApplication sharedApplication] zf_cacheFailRequest:theRequest];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (finalImage) {
                        [weakSelf setImage:finalImage isFromCache:NO];
                        
                        if (weakSelf.completion) {
                            weakSelf.completion(weakSelf.image);
                        }
                    } else {// error data
                        if (weakSelf.completion) {
                            weakSelf.completion(weakSelf.image);
                        }
                    }
                });
            });
        } else { // error
            [[UIApplication sharedApplication] zf_cacheFailRequest:theRequest];
            
            if (weakSelf.completion) {
                weakSelf.completion(weakSelf.image);
            }
        }
    }];
}

- (void)setImage:(UIImage *)image isFromCache:(BOOL)isFromCache {
    self.image = image;
    if (!isFromCache) {
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.6f];
        [animation setType:kCATransitionFade];
        animation.removedOnCompletion = YES;
        [self.layer addAnimation:animation forKey:@"transition"];
    }
}

- (void)cancelRequest {
    [self.imageDownloader.task cancel];
}

- (UIImage *)clipImage:(UIImage *)image toSize:(CGSize)size isScaleToMax:(BOOL)isScaleToMax {
    CGFloat scale =  [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    
    CGSize aspectFitSize = CGSizeZero;
    if (image.size.width != 0 && image.size.height != 0) {
        CGFloat rateWidth = size.width / image.size.width;
        CGFloat rateHeight = size.height / image.size.height;
        
        CGFloat rate = isScaleToMax ? MAX(rateHeight, rateWidth) : MIN(rateHeight, rateWidth);
        aspectFitSize = CGSizeMake(image.size.width * rate, image.size.height * rate);
    }
    
    [image drawInRect:CGRectMake(0, 0, aspectFitSize.width, aspectFitSize.height)];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImage;
}

@end
