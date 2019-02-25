//
//  AudioEncoder.h
//  VideoChat
//
//  Created by ZZJ on 2019/2/25.
//  Copyright © 2019 Jion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN
@class AudioEncoder;
@class AudioFrame;
@protocol AudioEncoderDelegate <NSObject>
- (void)audioEncoder:(AudioEncoder*)audioEncoder audioFrame:(AudioFrame*)audioFrame;

@end
@interface AudioEncoder : NSObject
@property (weak,nonatomic)id<AudioEncoderDelegate> delegate;

- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp;

@end


@interface AudioFrame : NSObject

@property(assign)uint64_t timestamp;

@property(nonatomic,strong)NSData  *data;

@property(nonatomic,strong)NSData *audioInfo;

@end

NS_ASSUME_NONNULL_END
