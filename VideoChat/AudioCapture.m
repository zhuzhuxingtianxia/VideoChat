//
//  AudioCapture.m
//  VideoChat
//
//  Created by ZZJ on 2019/2/25.
//  Copyright © 2019 Jion. All rights reserved.
//

#import "AudioCapture.h"
@interface AudioCapture ()
@property(nonatomic)AudioUnit componetInstance;

@property(nonatomic)AudioComponent component;

//是否消除声音
@property(nonatomic,assign)BOOL muted;
@end
@implementation AudioCapture

-(instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

//音频采集
-(void)createAudioUnit {
    //    AudioComponentInstance和AudioUnit一样
    self.component = [self getInputAudioComponent];
    OSStatus status = noErr;
    status = AudioComponentInstanceNew(self.component, &_componetInstance);
    
    if (noErr != status) {
        [self handleAudioInitializeError];
    }
    
    UInt32 flagOne = 1;
    
    AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
    
    //音频流描述
    AudioStreamBasicDescription desc = {0};
    desc.mSampleRate = 44100;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    desc.mChannelsPerFrame = 2;
    desc.mFramesPerPacket = 1;
    desc.mBitsPerChannel = 16;
    desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
    desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    AudioUnitSetProperty(_componetInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &desc, sizeof(desc));
    
    //设置回调
    AURenderCallbackStruct cb;
    cb.inputProcRefCon = (__bridge void *)(self);
    cb.inputProc = handleInputBuffer;
    
    AudioUnitSetProperty(_componetInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &cb, sizeof(cb));
    
    status = AudioUnitInitialize(_componetInstance);
    
    if (noErr != status) {
        [self handleAudioInitializeError];
    }
}

-(void)handleAudioInitializeError {
    NSLog(@"Audio init error");
}

-(AudioComponent)getInputAudioComponent {
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Output;
    acd.componentSubType = kAudioUnitSubType_RemoteIO;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    acd.componentFlags = 0;
    acd.componentFlagsMask = 0;
    
    AudioComponent component = AudioComponentFindNext(NULL, &acd);
    
    return component;
}
static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        AudioCapture *source = (__bridge AudioCapture *)inRefCon;
        if (!source) return -1;
        
        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;
        
        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
        
        OSStatus status = AudioUnitRender(source.componetInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &buffers);
        
        if (source.muted) {
            for (int i = 0; i < buffers.mNumberBuffers; i++) {
                AudioBuffer ab = buffers.mBuffers[i];
                memset(ab.mData, 0, ab.mDataByteSize);
            }
        }
        
        if (!status) {
            if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
                [source.delegate captureOutput:source audioData:[NSData dataWithBytes:buffers.mBuffers[0].mData length:buffers.mBuffers[0].mDataByteSize]];
            }
        }
        return status;
    }
}


@end


