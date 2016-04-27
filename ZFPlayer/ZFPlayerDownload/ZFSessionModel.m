//
//  ZFNSURLSession.m
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

#import "ZFSessionModel.h"

@implementation ZFSessionModel

- (float)calculateFileSizeInUnit:(unsigned long long)contentLength
{
    if(contentLength >= pow(1024, 3))
        return (float) (contentLength / (float)pow(1024, 3));
    else if(contentLength >= pow(1024, 2))
        return (float) (contentLength / (float)pow(1024, 2));
    else if(contentLength >= 1024)
        return (float) (contentLength / (float)1024);
    else
        return (float) (contentLength);
}

- (NSString *)calculateUnit:(unsigned long long)contentLength
{
    if(contentLength >= pow(1024, 3))
        return @"GB";
    else if(contentLength >= pow(1024, 2))
        return @"MB";
    else if(contentLength >= 1024)
        return @"KB";
    else
        return @"B";
}

- (void)encodeWithCoder:(NSCoder *)aCoder //将属性进行编码
{
    [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeObject:self.fileName forKey:@"fileName"];
    [aCoder encodeInteger:self.totalLength forKey:@"totalLength"];
    [aCoder encodeObject:self.totalSize forKey:@"totalSize"];
}

- (id)initWithCoder:(NSCoder *)aDecoder //将属性进行解码
{
    self = [super init];
    if (self) {
        self.url = [aDecoder decodeObjectForKey:@"url"];
        self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
        self.totalLength = [aDecoder decodeIntegerForKey:@"totalLength"];
        self.totalSize = [aDecoder decodeObjectForKey:@"totalSize"];
    }
    return self;
}

@end
