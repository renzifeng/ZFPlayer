//
//  ZFPlayerSource.h
//  
//
//  Created by 邓锋 on 2018/8/1.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@protocol ZFPlayerSource <NSObject>
@required
- (AVPlayerItem* )playerSource;
@end
