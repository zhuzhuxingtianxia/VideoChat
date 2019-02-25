//
//  AudioEncoder.m
//  VideoChat
//
//  Created by ZZJ on 2019/2/25.
//  Copyright © 2019 Jion. All rights reserved.
//

#import "AudioEncoder.h"
@interface AudioEncoder()
{
    NSUInteger leftLength;
    NSUInteger audioBufferSize;
    char *aacBuffer;
    char *audioBuffer;
    AudioConverterRef m_converter;
}
@end

@implementation AudioEncoder

-(instancetype)init{
    self = [super init];
    if (self) {
        //这几个参数存在疑问🤔️？？
        leftLength = 0;
        audioBufferSize = 1024*10;
        aacBuffer = malloc(audioBufferSize);
        audioBuffer = malloc(audioBufferSize);
        [self createConfig];
    }
    return self;
}

-(void)createConfig {
    //    AudioConverterRef m_converter;
    AudioStreamBasicDescription inputFormat = {0};
    inputFormat.mSampleRate = 44100;
    inputFormat.mFormatID = kAudioFormatLinearPCM;
    inputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    inputFormat.mChannelsPerFrame = (UInt32)2;
    inputFormat.mFramesPerPacket = 1;
    inputFormat.mBitsPerChannel = 16;
    inputFormat.mBytesPerFrame = inputFormat.mBitsPerChannel / 8 * inputFormat.mChannelsPerFrame;
    inputFormat.mBytesPerPacket = inputFormat.mBytesPerFrame * inputFormat.mFramesPerPacket;
    
    AudioStreamBasicDescription outputFormat; // 这里开始是输出音频格式
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate =44100;       // 采样率保持一致
    outputFormat.mFormatID = kAudioFormatMPEG4AAC;            // AAC编码 kAudioFormatMPEG4AAC kAudioFormatMPEG4AAC_HE_V2
    outputFormat.mChannelsPerFrame = 2;
    outputFormat.mFramesPerPacket = 1024;                     // AAC一帧是1024个字节
    
    const OSType subtype = kAudioFormatMPEG4AAC;
    AudioClassDescription requestedCodecs[2] = {
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleSoftwareAudioCodecManufacturer
        },
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleHardwareAudioCodecManufacturer
        }
    };
    
    OSStatus result = AudioConverterNewSpecific(&inputFormat, &outputFormat, 2, requestedCodecs, &m_converter);
    UInt32 outputBitrate = 96000;
    UInt32 propSize = sizeof(outputBitrate);
    
    
    if(result == noErr) {
        result = AudioConverterSetProperty(m_converter, kAudioConverterEncodeBitRate, propSize, &outputBitrate);
    }
}

OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription * *outDataPacketDescription, void *inUserData)
{
    AudioBufferList bufferList = *(AudioBufferList *)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}

- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp {
    if(leftLength + audioData.length >= audioBufferSize){
        NSInteger totalSize = leftLength + audioData.length;
        NSInteger encodeCount = totalSize / audioBufferSize;
        char *totalBuf = malloc(totalSize);
        char *p = totalBuf;
        
        memset(totalBuf, (int)totalSize, 0);
        memcpy(totalBuf, audioBuffer, leftLength);
        memcpy(totalBuf + leftLength, audioData.bytes, audioData.length);
        
        for(NSInteger index = 0;index < encodeCount;index++){
            [self encodeBuffer:p  timeStamp:timeStamp];
            p += audioBufferSize;
        }
        
        leftLength = totalSize % audioBufferSize;
        memset(audioBuffer, 0, audioBufferSize);
        memcpy(audioBuffer, totalBuf + (totalSize -leftLength), leftLength);
        free(totalBuf);
    }else{
        memcpy(audioBuffer+leftLength, audioData.bytes, audioData.length);
        leftLength = leftLength + audioData.length;
    }
}
- (void)encodeBuffer:(char*)buf timeStamp:(uint64_t)timeStamp{
    
    AudioBuffer inBuffer;
    inBuffer.mNumberChannels = 1;
    inBuffer.mData = buf;
    inBuffer.mDataByteSize = (UInt32)audioBufferSize;
    
    AudioBufferList inBufferList;
    inBufferList.mNumberBuffers = 1;
    inBufferList.mBuffers[0] = inBuffer;
    
    // 初始化一个输出缓冲列表
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = inBuffer.mNumberChannels;
    outBufferList.mBuffers[0].mDataByteSize = inBuffer.mDataByteSize;   // 设置缓冲区大小
    outBufferList.mBuffers[0].mData = aacBuffer;           // 设置AAC缓冲区
    UInt32 outputDataPacketSize = 1;
    if (AudioConverterFillComplexBuffer(m_converter, inputDataProc, &inBufferList, &outputDataPacketSize, &outBufferList, NULL) != noErr) {
        return;
    }
    
    AudioFrame *audioFrame = [AudioFrame new];
    audioFrame.timestamp = timeStamp;
    audioFrame.data = [NSData dataWithBytes:aacBuffer length:outBufferList.mBuffers[0].mDataByteSize];
    
    char exeData[2];
    ///// flv编码音频头 44100 为0x12 0x10
    exeData[0] = 0x12;
    exeData[1] = 0x10;
    audioFrame.audioInfo = [NSData dataWithBytes:exeData length:2];
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioEncoder:audioFrame:)]) {
        [self.delegate audioEncoder:self audioFrame:audioFrame];
    }
    
}

//https://wiki.multimedia.cx/index.php?title=MPEG-4_Audio
/*
 根据公式就可以计算出44100的asc：
 asc[0] = 0x10 | ((sampleRateIndex>>1) & 0x7);
 asc[1] = ((sampleRateIndex & 0x1)<<7) | ((numberOfChannels & 0xF) << 3);
 即：
 asc[0] = 0x10 | ((4>>1) & 0x7) = 0x12
 asc[1] = ((4 & 0x1)<<7) | ((2 & 0xF) << 3) = 0x10
 */
- (NSInteger)sampleRateIndex:(NSInteger)frequencyInHz {
    NSInteger sampleRateIndex = 0;
    switch (frequencyInHz) {
        case 96000:
            sampleRateIndex = 0;
            break;
        case 88200:
            sampleRateIndex = 1;
            break;
        case 64000:
            sampleRateIndex = 2;
            break;
        case 48000:
            sampleRateIndex = 3;
            break;
        case 44100:
            sampleRateIndex = 4;
            break;
        case 32000:
            sampleRateIndex = 5;
            break;
        case 24000:
            sampleRateIndex = 6;
            break;
        case 22050:
            sampleRateIndex = 7;
            break;
        case 16000:
            sampleRateIndex = 8;
            break;
        case 12000:
            sampleRateIndex = 9;
            break;
        case 11025:
            sampleRateIndex = 10;
            break;
        case 8000:
            sampleRateIndex = 11;
            break;
        case 7350:
            sampleRateIndex = 12;
            break;
        default:
            sampleRateIndex = 15;
    }
    return sampleRateIndex;
}

@end

#pragma mark ----- AudioFrame

@implementation AudioFrame


@end
