//
//  ZFHttpRequest.h
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
#import <ASIHTTPRequest/ASIHTTPRequest.h>

@class ZFHttpRequest;

@protocol ZFHttpRequestDelegate <NSObject>

- (void)requestFailed:(ZFHttpRequest *)request;
- (void)requestStarted:(ZFHttpRequest *)request;
- (void)request:(ZFHttpRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders;
- (void)request:(ZFHttpRequest *)request didReceiveBytes:(long long)bytes;
- (void)requestFinished:(ZFHttpRequest *)request;
@optional
- (void)request:(ZFHttpRequest *)request willRedirectToURL:(NSURL *)newURL;

@end

@interface ZFHttpRequest : NSObject
@property (weak, nonatomic  ) id<ZFHttpRequestDelegate> delegate;
@property (strong, nonatomic) NSURL                  *url;
@property (strong, nonatomic) NSURL                  *originalURL;
@property (strong, nonatomic) NSDictionary           *userInfo;
@property (assign, nonatomic) NSInteger              tag;
@property (strong, nonatomic) NSString               *downloadDestinationPath;
@property (strong, nonatomic) NSString               *temporaryFileDownloadPath;
@property (strong,readonly,nonatomic) NSError *error;

- (instancetype)initWithURL:(NSURL*)url;
- (void)startAsynchronous;
- (BOOL)isFinished;
- (BOOL)isExecuting;
- (void)cancel;
@end
