//
//  TXPlayerManager.h
//  luotuo
//
//  Created by guduzhonglao on 4/15/20.
//  Copyright © 2020 guduzhonglao. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<ZFPlayer/ZFPlayerMediaPlayback.h>)
#import <ZFPlayer/ZFPlayerMediaPlayback.h>
#else
#import "ZFPlayerMediaPlayback.h"
#endif
#import <TXLiteAVSDK_Smart/TXLivePlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface TXLivePlayerManager : NSObject<ZFPlayerMediaPlayback>

@property (nonatomic,strong,readonly) TXLivePlayer* player;

@end

NS_ASSUME_NONNULL_END
