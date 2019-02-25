//
//  AudioCapture.h
//  VideoChat
//
//  Created by ZZJ on 2019/2/25.
//  Copyright © 2019 Jion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN
@class AudioCapture;
@protocol AudioCaptureDelegate <NSObject>
- (void)captureOutput:(AudioCapture*)audioCapture audioData:(NSData*)audioData;

@end
@interface AudioCapture : NSObject

@property(nonatomic,weak)id <AudioCaptureDelegate> delegate;

//音频采集
-(void)createAudioUnit;

@end

NS_ASSUME_NONNULL_END
