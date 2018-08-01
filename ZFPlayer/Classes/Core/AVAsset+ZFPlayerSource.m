//
//  AVAsset+ZFPlayerSource.m
//
//
//  Created by 邓锋 on 2018/8/1.
//

#import "AVAsset+ZFPlayerSource.h"

@implementation AVAsset (ZFPlayerSource)

//实现协议
- (AVAsset* )playerSource{
    return self;
}

@end

@implementation AVURLAsset (ZFPlayerSource)

//实现协议
- (AVAsset* )playerSource{
    return self;
}

@end
