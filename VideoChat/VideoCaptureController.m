//
//  VideoCaptureController.m
//  VideoChat
//
//  Created by ZZJ on 2019/2/25.
//  Copyright © 2019 Jion. All rights reserved.
//

#import "VideoCaptureController.h"
#import <AVFoundation/AVFoundation.h>
#import "HardwareVideoEncoder.h"

@interface VideoCaptureController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,HardwareVideoEncoderDelegate>
{
    HardwareVideoEncoder *_h264Encoder;
}

@end

@implementation VideoCaptureController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"视频编码";
    // Do any additional setup after loading the view.
    [self startCapture];
    _h264Encoder = [[HardwareVideoEncoder alloc] init];
    _h264Encoder.h264Delegate = self;
    [_h264Encoder encodebyWidth:1280 height:720];
}
-(void)startCapture {
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    
    AVCaptureDeviceInput *videoInput = [self getVideoInputDevice];
    if ([captureSession canAddInput:videoInput]) {
        [captureSession addInput:videoInput];
    }
    
    
    AVCaptureVideoDataOutput *outPutDevice = [self getVideoOutPutDevice];
    [captureSession addOutput:outPutDevice];
    
    [captureSession beginConfiguration];
    captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    [outPutDevice connectionWithMediaType:AVMediaTypeVideo];
    [captureSession commitConfiguration];
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer];
    previewLayer.frame = self.view.bounds;
    [captureSession startRunning];
}
-(AVCaptureDeviceInput *)getVideoInputDevice {
    NSError *deviceError;
    AVCaptureDeviceInput *inputDevice;
    
    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        for (AVCaptureDevice *device in devicesIOS10.devices) {
            if ([device position] == AVCaptureDevicePositionFront) {
                inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:&deviceError];
            }
        }
    }else{
        for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (device.position == AVCaptureDevicePositionFront) {
                inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:&deviceError];
            }
        }
    }
    
    return inputDevice;
    
}

-(AVCaptureDeviceInput *)getAudioInputDevice{
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    return audioInputDevice;
}

-(AVCaptureVideoDataOutput *)getVideoOutPutDevice {
    AVCaptureVideoDataOutput *outPutDevice = [[AVCaptureVideoDataOutput alloc] init];
    
    //设置输出格式为 yuv420
    NSString *keyPixel = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *pixelFormatType = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    
    NSDictionary *videoSetting = @{keyPixel:pixelFormatType};
    outPutDevice.videoSettings = videoSetting;
    
    [outPutDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    return outPutDevice;
}

-(AVCaptureAudioDataOutput *)getAudioOutputDevice {
    //创建数据获取线程
    dispatch_queue_t captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //音频数据输出
    AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    //设置代理，需要当前类实现protocol：AVCaptureAudioDataOutputSampleBufferDelegate
    [audioDataOutput setSampleBufferDelegate:self queue:captureQueue];
    
    return audioDataOutput;
}

#pragma mark -- AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    // 这里面就包含了yuv420(NV12)数据的指针
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    [_h264Encoder encodeVideoData:imageBuffer timeStamp:0];
    NSLog(@"输出:%@",imageBuffer);
}

#pragma mark -- HardwareVideoEncoderDelegate
- (void)videoEncoder:(HardwareVideoEncoder*)videoEncoder videoFrame:(VideoFrame*)videoFrame {
    NSLog(@"编码数据结果");
}

#pragma mark -- GPUImage
-(void)configGPUImage {
    /*
     //Camera configuration
     GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
     videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
     videoCamera.frameRate = 24;
     
     //Filter
     GPUImageFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
     GPUImageWhiteBalanceFilter *whiteBalanceFilter = [[GPUImageWhiteBalanceFilter alloc] init];
     GPUImageOutput<GPUImageInput> *output = [[GPUImageFilter alloc] init];
     
     //Display
     GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, viewWidth, viewHeight)];
     
     //Targets
     [videoCamera addTarget: brightnessFilter];
     [brightnessFilter addTarget: whiteBalanceFilter];
     [whiteBalanceFilter addTarget: output];
     [whiteBalanceFilter addTarget:filteredVideoView];
     
     //Get the render output
     [output setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
     GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
     CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
     //TODO : Send to server
     }];
     
     [videoCamera startCameraCapture];
     */
}

-(void)dealloc {
    NSLog(@"走啊走");
}

@end
