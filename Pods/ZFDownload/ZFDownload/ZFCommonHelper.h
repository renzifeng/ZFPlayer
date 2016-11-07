//
//  ZFCommonHelper.h
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

// 下载文件的总文件夹
#define BASE       @"ZFDownLoad"
// 完整文件路径
#define TARGET     @"CacheList"
// 临时文件夹名称
#define TEMP       @"Temp"
// 缓存主目录
#define CACHES_DIRECTORY     [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
// 临时文件夹的路径
#define TEMP_FOLDER          [NSString stringWithFormat:@"%@/%@/%@",CACHES_DIRECTORY,BASE,TEMP]
// 临时文件的路径
#define TEMP_PATH(name)      [NSString stringWithFormat:@"%@/%@",[ZFCommonHelper createFolder:TEMP_FOLDER],name]
// 下载文件夹路径
#define FILE_FOLDER          [NSString stringWithFormat:@"%@/%@/%@",CACHES_DIRECTORY,BASE,TARGET]
// 下载文件的路径
#define FILE_PATH(name)      [NSString stringWithFormat:@"%@/%@",[ZFCommonHelper createFolder:FILE_FOLDER],name]
// 文件信息的Plist路径
#define PLIST_PATH           [NSString stringWithFormat:@"%@/%@/FinishedPlist.plist",CACHES_DIRECTORY,BASE]

@interface ZFCommonHelper : NSObject

/** 将文件大小转化成M单位或者B单位 */
+ (NSString *)getFileSizeString:(NSString *)size;
/** 经文件大小转化成不带单位的数字 */
+ (float)getFileSizeNumber:(NSString *)size;
/** 字符串格式化成日期 */
+ (NSDate *)makeDate:(NSString *)birthday;
/** 日期格式化成字符串 */
+ (NSString *)dateToString:(NSDate*)date;
/** 检查文件名是否存在 */
+ (BOOL)isExistFile:(NSString *)fileName;
+ (NSString *)createFolder:(NSString *)path;

@end
