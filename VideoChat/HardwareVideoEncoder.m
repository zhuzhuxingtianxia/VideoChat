//
//  HardwareVideoEncoder.m
//  Category
//
//  Created by ZZJ on 2019/2/25.
//  Copyright © 2019 Jion. All rights reserved.
//

#import "HardwareVideoEncoder.h"

@interface HardwareVideoEncoder ()
{
    VTCompressionSessionRef compressionSession;
    int  frameCount;
    NSData *sps;
    NSData *pps;
    
    CGFloat videoFrameRate;//帧率
    CGFloat videoMaxKeyframeInterval;//最大关键帧间隔
}
@end
@implementation HardwareVideoEncoder

-(instancetype)init{
    self = [super init];
    if (self) {
        [self initWithConfiguration];
    }
    return self;
}

- (void) initWithConfiguration {
    
    compressionSession = nil;
    frameCount = 0;
    sps = NULL;
    pps = NULL;
}
#pragma mark -- Video Hard coded
- (void)encodeVideoData:(CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp {
    if (compressionSession == nil|| compressionSession == NULL){
        return;
    }
    frameCount++;
    CMTime presentationTimeStamp = CMTimeMake(frameCount, (int32_t)videoFrameRate);
    VTEncodeInfoFlags flags;
    
    if (timeStamp>0) {
        NSNumber *timeNumber = @(timeStamp);
        CMTime duration = CMTimeMake(1, (int32_t)videoFrameRate);
        NSDictionary *properties = nil;
        if (frameCount % (int32_t)videoMaxKeyframeInterval == 0) {
            properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
        }
        OSStatus status = VTCompressionSessionEncodeFrame(compressionSession, pixelBuffer, presentationTimeStamp, duration, (__bridge CFDictionaryRef)properties, (__bridge_retained void *)timeNumber, &flags);
        if(status != noErr){
            [self resetCompressionSession];
        }
    }else{
        OSStatus status = VTCompressionSessionEncodeFrame(compressionSession, pixelBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, NULL, &flags);
        if(status != noErr){
            [self resetCompressionSession];
        }
    }
    
    
}

-(void)resetCompressionSession {
    if (compressionSession != nil|| compressionSession != NULL){
        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
    }
}

-(void)encodebyWidth:(int32_t)width  height:(int32_t)height{
    
    //
    OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, VideoCompressonOutputCallback, (__bridge void*)self, &compressionSession);
    if (status != noErr) {
        //硬编码session创建失败
        NSLog(@"Error by VTCompressionSessionCreate ");
        return ;
    }
    CGFloat videoBitRate = 800*1024;//码率
    videoFrameRate = 24;//帧率
    videoMaxKeyframeInterval = 48;//最大关键帧间隔
    
    // 关键帧最大间隔，关键帧也就是I帧。
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(videoMaxKeyframeInterval));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(videoMaxKeyframeInterval/videoFrameRate));
    
    //设置帧率
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(videoFrameRate));
    
    // 设置码率
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(videoBitRate));
    NSArray *limit = @[@(videoBitRate * 1.5/8), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    
    // 设置实时编码
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    // ProfileLevel，h264的协议等级，不同的清晰度使用不同的ProfileLevel。
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
    
    // 关闭重排Frame，因为有了B帧（双向预测帧，根据前后的图像计算出本帧）后，编码顺序可能跟显示顺序不同。此参数可以关闭B帧。
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanTrue);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
    
    //参数设置完毕，准备开始，至此初始化完成，随时来数据，随时编码
    VTCompressionSessionPrepareToEncodeFrames(compressionSession);
}

static void VideoCompressonOutputCallback(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer){
    
    if (!sampleBuffer) return;
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    if (!array) return;
    CFDictionaryRef dic = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);
    if (!dic) return;
    //是否是关键帧，关键帧和非关键帧要区分清楚。推流时也要注明。
    BOOL keyframe = !CFDictionaryContainsKey(dic, kCMSampleAttachmentKey_NotSync);
    uint64_t timeStamp = [((__bridge_transfer NSNumber *)VTFrameRef) longLongValue];
    
    HardwareVideoEncoder *videoEncoder = (__bridge HardwareVideoEncoder *)VTref;
    if (status != noErr) {
        return;
    }
    
    if (keyframe && !videoEncoder->sps) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        if (statusCode == noErr) {
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            if (statusCode == noErr) {
                videoEncoder->sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                videoEncoder->pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
            }
        }
    }
    
    //获取真正的视频帧数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        //一般情况下都是只有1帧，在最开始编码的时候有2帧，取最后一帧
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            VideoFrame *videoFrame = [VideoFrame new];
            videoFrame.timestamp = timeStamp;
            videoFrame.data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            videoFrame.isKeyFrame = keyframe;
            videoFrame.sps = videoEncoder->sps;
            videoFrame.pps = videoEncoder->pps;
            
            if (videoEncoder.h264Delegate && [videoEncoder.h264Delegate respondsToSelector:@selector(videoEncoder:videoFrame:)]) {
                [videoEncoder.h264Delegate videoEncoder:videoEncoder videoFrame:videoFrame];
            }
            
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}
@end

#pragma mark ---- VideoFrame

@implementation VideoFrame


@end
