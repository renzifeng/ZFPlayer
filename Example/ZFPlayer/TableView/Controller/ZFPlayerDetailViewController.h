//
//  ZFPlayerDetailViewController.h
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2018/9/12.
//  Copyright © 2018年 紫枫. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZFPlayer/ZFPlayer.h>

@interface ZFPlayerDetailViewController : UIViewController

@property (nonatomic, strong) ZFPlayerController *player;

@property (nonatomic, copy) void(^detailVCPopCallback)();

@property (nonatomic, copy) void(^detailVCPlayCallback)();

@end
