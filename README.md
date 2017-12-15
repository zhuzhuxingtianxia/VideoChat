# VideoChat
摄像头视频采集

## 采集代码
```
#import <AVFoundation/AVFoundation.h>
#import <malloc/malloc.h>

@interface SysChat ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic,strong)AVCaptureDeviceInput *videoInput;
@property(nonatomic,strong)AVCaptureSession *capSession;

@property(nonatomic,strong)UIImageView *imageView;
@end
```

```
@implementation SysChat

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"切换摄像头" style:UIBarButtonItemStylePlain target:self action:@selector(switchCamera:)];
    [self.view addSubview:self.imageView];
    [self buildDecive];
}

-(void)buildDecive{
    NSError *error = nil;
    
    // Setup the video input
    AVCaptureDevice *videoDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
    // Create a device input with the device and add it to the session.
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

    // Setup the video output
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.alwaysDiscardsLateVideoFrames = NO;
    videoOutput.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    // Setup the queue
    dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
    [videoOutput setSampleBufferDelegate:self queue:queue];
    // [_audioOutput setSampleBufferDelegate:self queue:queue];
    
    // Create the session
    _capSession = [[AVCaptureSession alloc] init];
    [_capSession beginConfiguration];
    if ([_capSession canAddInput:_videoInput]) {
        [_capSession addInput:_videoInput];
        //[_capSession addInput:audioInput];
    }
    if ([_capSession canAddOutput:videoOutput]) {
        [_capSession addOutput:videoOutput];
        //[_capSession addOutput:_audioOutput];
    }
    
    _capSession.sessionPreset = AVCaptureSessionPreset1280x720;
    
    [_capSession commitConfiguration];
    
    [_capSession startRunning];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{

    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

-(void)switchCamera:(id)sender{
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition currentCameraPosition = [[_videoInput device] position];
    
    if (currentCameraPosition == AVCaptureDevicePositionBack){
        currentCameraPosition = AVCaptureDevicePositionFront;
    }else{
        currentCameraPosition = AVCaptureDevicePositionBack;
    }
    AVCaptureDevice *backFacingCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == currentCameraPosition)
        {
            backFacingCamera = device;
        }
    }
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:nil];
    
    if (newVideoInput != nil){
        [_capSession beginConfiguration];
        
        [_capSession removeInput:_videoInput];
        if ([_capSession canAddInput:newVideoInput]){
            [_capSession addInput:newVideoInput];
            _videoInput = newVideoInput;
        }else{
            [_capSession addInput:_videoInput];
        }
        [_capSession commitConfiguration];
    }
}

#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    // 获取当前的信息
    CVPixelBufferRef bufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 获取视频宽度
    size_t width =  CVPixelBufferGetWidth(bufferRef);
    size_t height = CVPixelBufferGetHeight(bufferRef);
    NSLog(@"%ld %ld", width, height);
    
    NSData *data = [NSData dataWithBytes:&sampleBuffer length:malloc_size(sampleBuffer)];
    NSLog(@"byte = %.2fkb",data.length/1.0);
    [self recieveVideoFromData:data];
}

- (void)recieveVideoFromData:(NSData *)data{
    CMSampleBufferRef sampleBuffer;
    [data getBytes:&sampleBuffer length:sizeof(sampleBuffer)];
    
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                        width, height, 8, bytesPerRow, colorSpace,
                                                        kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        UIImage *image= [UIImage imageWithCGImage:newImage scale:[UIScreen mainScreen].scale
                                      orientation:UIImageOrientationRight];
        
        CGImageRelease(newImage);
        [self.imageView performSelectorOnMainThread:@selector(setImage:)
                                         withObject:image waitUntilDone:YES];
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    }
    
}

-(UIImageView*)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = self.view.bounds;
        
    }
    return _imageView;
}
```

