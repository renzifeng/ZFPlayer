//
//  SecondViewController.m
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

#import "ZFVideoListViewController.h"
#import "MoviePlayerViewController.h"

@interface ZFVideoListViewController ()
@property (weak, nonatomic  ) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray     *dataSource;
@end

@implementation ZFVideoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = @[ @"http://120.25.226.186:32812/resources/videos/minion_01.mp4",
                         @"https://dev.zhibocloud.cn/api/v2/files/114",
                         @"http://120.25.226.186:32812/resources/videos/minion_03.mp4",
                         @"http://120.25.226.186:32812/resources/videos/minion_04.mp4",
                         @"http://120.25.226.186:32812/resources/videos/minion_05.mp4",
                         @"http://120.25.226.186:32812/resources/videos/minion_06.mp4",
                         @"http://120.25.226.186:32812/resources/videos/minion_07.mp4",
                         @"http://120.25.226.186:32812/resources/videos/minion_08.mp4",
                         @"http://static.smartisanos.cn/common/video/proud-farmer.mp4"];
}

// 必须支持转屏，但只是只支持竖屏，否则横屏启动起来页面是横的
- (BOOL)shouldAutorotate {
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"netListCell"];
    cell.textLabel.text   = [NSString stringWithFormat:@"网络视频%zd",indexPath.row+1];
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    MoviePlayerViewController *movie = (MoviePlayerViewController *)segue.destinationViewController;
    UITableViewCell *cell            = (UITableViewCell *)sender;
    NSIndexPath *indexPath           = [self.tableView indexPathForCell:cell];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSURL *URL                       = [NSURL URLWithString:self.dataSource[indexPath.row]];
    movie.videoURL                   = URL;
}


@end
