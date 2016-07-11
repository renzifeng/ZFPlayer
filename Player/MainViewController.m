//
//  MainViewController.m
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

#import "MainViewController.h"
#import "MoviePlayerViewController.h"
#import "ZFTableViewController.h"
#import "ZFPlayer.h"

@interface MainViewController ()

@end

@implementation MainViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.selectedIndex = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

// 哪些页面支持自动转屏
- (BOOL)shouldAutorotate{
    
    UINavigationController *nav = self.viewControllers[self.selectedIndex];
    
    // MoviePlayerViewController 、ZFTableViewController 控制器支持自动转屏
    if ([nav.topViewController isKindOfClass:[MoviePlayerViewController class]] || [nav.topViewController isKindOfClass:[ZFTableViewController class]]) {
        // 调用ZFPlayerSingleton单例记录播放状态是否锁定屏幕方向
        return !ZFPlayerShared.isLockScreen;
    }
    return NO;
}

// viewcontroller支持哪些转屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    UINavigationController *nav = self.viewControllers[self.selectedIndex];
    if ([nav.topViewController isKindOfClass:[MoviePlayerViewController class]]) { // MoviePlayerViewController这个页面支持转屏方向
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }else if ([nav.topViewController isKindOfClass:[ZFTableViewController class]]) { // ZFTableViewController这个页面支持转屏方向
        if (ZFPlayerShared.isAllowLandscape) {
            return UIInterfaceOrientationMaskAllButUpsideDown;
        }else {
            return UIInterfaceOrientationMaskPortrait;
        }
    }
    // 其他页面
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
