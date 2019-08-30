//
//  ViewController.m
//  Category
//
//  Created by ZZJ on 2019/2/23.
//  Copyright © 2019 Jion. All rights reserved.
//

#import "ViewController.h"
#import "VideoCaptureController.h"
#import "AudioViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}
- (IBAction)actionClick:(UIButton*)sender {
    if (sender.tag == 1) {
        VideoCaptureController *vedeoVC = [VideoCaptureController new];
        [self.navigationController pushViewController:vedeoVC animated:YES];
    }else{
        AudioViewController *audioVC = [AudioViewController new];
        [self.navigationController pushViewController:audioVC animated:YES];
    }
}

@end
