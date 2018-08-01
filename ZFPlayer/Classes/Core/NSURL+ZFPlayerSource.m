//
//  NSURL+ZFPlayerSource.m
// 
//
//  Created by 邓锋 on 2018/8/1.
//

#import "NSURL+ZFPlayerSource.h"
#import <AVFoundation/AVFoundation.h>
@implementation NSURL (ZFPlayerSource)


//实现协议
- (AVPlayerItem* )playerSource{
    return [[AVPlayerItem alloc] initWithURL:self];
}
@end
