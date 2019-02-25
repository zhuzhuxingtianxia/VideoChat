//
//  AudioViewController.m
//  VideoChat
//
//  Created by ZZJ on 2019/2/25.
//  Copyright © 2019 Jion. All rights reserved.
//

#import "AudioViewController.h"
#import "AudioCapture.h"
#import "AudioEncoder.h"
@interface AudioViewController ()<AudioCaptureDelegate,AudioEncoderDelegate>
@property(nonatomic,strong)AudioEncoder *audioEncoder;

@end

@implementation AudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

-(void)createRecoder {
    AudioCapture *capture = [AudioCapture new];
    capture.delegate = self;
    [capture createAudioUnit];
    
    _audioEncoder = [[AudioEncoder alloc] init];
    _audioEncoder.delegate = self;
}

#pragma mark -- AudioCaptureDelegate
- (void)captureOutput:(AudioCapture*)audioCapture audioData:(NSData*)audioData{
    
    [_audioEncoder encodeAudioData:audioData timeStamp:0];
}

#pragma mark -- AudioEncoderDelegate
- (void)audioEncoder:(AudioEncoder*)audioEncoder audioFrame:(AudioFrame*)audioFrame {
    NSLog(@"编码后的数据：%@",audioFrame.data);
}

@end
