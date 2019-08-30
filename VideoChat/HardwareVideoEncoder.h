//
//  HardwareVideoEncoder.h
//  Category
//
//  Created by ZZJ on 2019/2/25.
//  Copyright © 2019 Jion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN
@class HardwareVideoEncoder;
@class VideoFrame;
@protocol HardwareVideoEncoderDelegate <NSObject>
- (void)videoEncoder:(HardwareVideoEncoder*)videoEncoder videoFrame:(VideoFrame*)videoFrame;

@end
@interface HardwareVideoEncoder : NSObject

@property (weak, nonatomic) id<HardwareVideoEncoderDelegate> h264Delegate;
-(void)encodebyWidth:(int32_t)width  height:(int32_t)height;

- (void)encodeVideoData:(CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp;

@end

@interface VideoFrame : NSObject

@property(assign)uint64_t timestamp;
//一帧h264数据
@property(nonatomic,strong)NSData  *data;

@property(nonatomic,strong)NSData *sps;
@property(nonatomic,strong)NSData *pps;

@property(assign)BOOL  isKeyFrame;

@end

NS_ASSUME_NONNULL_END
