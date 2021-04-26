//
//  ACCAudioRecorder.m
//  ACCKit
//
//  Created by CCyber on 2021/4/13.
//

#import "ACCAudioRecorder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface ACCAudioRecorder() {
    AudioComponentInstance iOUnit;
    AudioComponentInstance mixerUnit;
}

@property (nonatomic) UInt32 sampleRate;
@property (nonatomic) UInt32 channelsPerFrame;
@property (nonatomic) UInt32 bitsPerChannel;

@end
@implementation ACCAudioRecorder
- (instancetype)initWithSampleRate:(int)sampleRate channelsPerFrame:(int)channelsPerFrame bitsPerChannel:(int)bitsPerChannel {
    if (self = [super init]) {
        _sampleRate = sampleRate;
        _channelsPerFrame = channelsPerFrame;
        _bitsPerChannel = bitsPerChannel;
        [self initRecorder];
    }
    return self;
}

- (void)dealloc {
    if (iOUnit) {
        AudioComponentInstanceDispose(iOUnit);
    }
}

- (void)initRecorder {
//    NSInteger inputChannels = [AVAudioSession sharedInstance].inputNumberOfChannels;
//    NSLog(@"ACCAudioRecorder inputChannels %li", inputChannels);
//    if (!inputChannels) {
//        NSLog(@"ERROR: NO AUDIO INPUT DEVICE");
//        return ;
//    }
    _enable = YES;
    BOOL result = YES;

    result &= [self configIOUnit];
    result &= [self configMixerUnit];
    
    //make connection, iounit bus0 output to iounit bus0 input
    AudioUnitConnection connection;
    connection.sourceAudioUnit    = iOUnit;
    connection.sourceOutputNumber = 1;
    connection.destInputNumber    = 0;
    
    OSStatus status = AudioUnitSetProperty(mixerUnit,
                                           kAudioUnitProperty_MakeConnection,
                                           kAudioUnitScope_Input,
                                           0,
                                           &connection,
                                           sizeof(connection));
    result &= [self checkStatus:status error:@"make connection failed"];

    NSLog(@"ACCAudioRecorder:初始化成功");
}

- (BOOL)configIOUnit {
    BOOL result = YES;
    //输入
    OSStatus status;
    AudioComponentDescription  desc;
    desc.componentType         = kAudioUnitType_Output;         //音频输出
    desc.componentSubType      = kAudioUnitSubType_RemoteIO;    //输出通道
    desc.componentFlags        = 0;                             //默认“0”
    desc.componentFlagsMask    = 0;                             //默认“0”
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;  //制造商信息
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);    //找音频部件

    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &iOUnit);         //实现这个部件单元
    [self checkStatus:status];
    
    
//    //Describe format 参数可以根据项目需要自行调整
//    AudioStreamBasicDescription audioFormat;
//    audioFormat.mSampleRate       = _sampleRate;
//    audioFormat.mBitsPerChannel   = _bitsPerChannel;
//    audioFormat.mChannelsPerFrame = _channelsPerFrame;
//    audioFormat.mFormatID         = kAudioFormatLinearPCM;
//    audioFormat.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
//    audioFormat.mFramesPerPacket  = 1;
//    audioFormat.mBytesPerFrame    = audioFormat.mChannelsPerFrame * audioFormat.mBitsPerChannel/8;
//    audioFormat.mBytesPerPacket   = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket;
    
    //bus0 应用输出到硬件
    AudioUnitElement bus0 = 0;
    //设置bus0
    /*
     当使用kAudioUnitSubType_VoiceProcessingIO时，控制台会不停输出 AUBuffer.h:61:GetBufferList: EXCEPTION (-1) [mPtrState == kPtrsInvalid is false]: ""，解决方案参考https://developer.apple.com/forums/thread/125147
     解决方案：设置bus0，但是不启用
     */
    /*{
        // Enable IO for playing（kAudioUnitScope_Input ==> recording）
        // flag 1 means start, 0 means stop
        uint32_t flag = 0;
        status = AudioUnitSetProperty(iOUnit,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Output, //【播放必定选kAudioUnitScope_Output!!!】
                                      bus0,
                                      &flag,
                                      sizeof(flag));
        [self checkStatus:status];

        //设置输入音频的format
        status = AudioUnitSetProperty(iOUnit,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Input,
                                      bus0,
                                      &audioFormat,
                                      sizeof(audioFormat));
        [self checkStatus:status];
        
        //设置回调
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc = (AURenderCallback)on_Audio_Playback;//自己命名一个回调函数
        callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
        status = AudioUnitSetProperty(iOUnit,
                                      kAudioUnitProperty_SetRenderCallback,
                                      kAudioUnitScope_Global,
                                      bus0,
                                      &callbackStruct,
                                      sizeof(callbackStruct));
        [self checkStatus:status];
    }*/
    
    //bus1 硬件输入到应用
    AudioUnitElement bus1 = 1;
    //设置bus1
    {
        uint32_t flag = 1;
        status = AudioUnitSetProperty(iOUnit,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Input, //【播放必定选kAudioUnitScope_Output!!!】
                                      bus1,
                                      &flag,
                                      sizeof(flag));
        [self checkStatus:status];
        
//        status = AudioUnitSetProperty(iOUnit,
//                                      kAudioUnitProperty_StreamFormat,
//                                      kAudioUnitScope_Output,
//                                      bus1,
//                                      &audioFormat,
//                                      sizeof(audioFormat));
//        [self checkStatus:status];
        
//        AURenderCallbackStruct callbackStruct;
//        callbackStruct.inputProc = (AURenderCallback)on_Audio_Record;//自己命名一个回调函数
//        callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
//        status = AudioUnitSetProperty(iOUnit,
//                                      kAudioOutputUnitProperty_SetInputCallback,
//                                      kAudioUnitScope_Global,
//                                      bus1,
//                                      &callbackStruct,
//                                      sizeof(callbackStruct));
//        [self checkStatus:status];
    }
    return result;
}

- (BOOL)configMixerUnit {
    BOOL result = YES;
    OSStatus status;
    AudioComponentDescription  desc;
    desc.componentType         = kAudioUnitType_Mixer;         //音频输出
    desc.componentSubType      = kAudioUnitSubType_MultiChannelMixer;    //输出通道
    desc.componentFlags        = 0;                             //默认“0”
    desc.componentFlagsMask    = 0;                             //默认“0”
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;  //制造商信息
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);    //找音频部件

    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &mixerUnit);//实现这个部件单元
    result &= [self checkStatus:status error:@"mixerUnit AudioComponentInstanceNew failed"];

    // Set mixer bus count
    UInt32 busCount = 1;
    status = AudioUnitSetProperty(mixerUnit,
                                  kAudioUnitProperty_ElementCount,
                                  kAudioUnitScope_Input,
                                  0,
                                  &busCount,
                                  sizeof(busCount));
    result &= [self checkStatus:status error:@"mixerUnit kAudioUnitProperty_ElementCount failed"];
    
    //设置回调
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = (AURenderCallback)on_Audio_Record;//自己命名一个回调函数
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(mixerUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  0,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    result &= [self checkStatus:status error:@"mixerUnit kAudioOutputUnitProperty_SetInputCallback failed"];
    return result;
}

static OSStatus on_Audio_Playback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  uint32_t inBusNumber,
                                  uint32_t inNumberFrames,
                                  AudioBufferList *ioData) {
    NSLog(@"on_Audio_Playback");

    return noErr;
}

static OSStatus on_Audio_Record(void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                uint32_t inBusNumber,
                                uint32_t inNumberFrames,
                                AudioBufferList *ioData) {
    ACCAudioRecorder *instance = (__bridge ACCAudioRecorder *)inRefCon;
    if (instance.enable == NO) {
        return noErr;
    }

    AudioBuffer buffer;
    buffer.mData = NULL;
    buffer.mDataByteSize = 0;
    buffer.mNumberChannels = 1;

    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;

    OSStatus stauts = AudioUnitRender(instance->iOUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    if (stauts != noErr) {
        NSLog(@"recordcallback error is %@",@(stauts));
    }
    
    for (int i = 0; i < 1; i++) {
        AudioBuffer buffer1 = bufferList.mBuffers[i];
        if (buffer1.mDataByteSize > 0 && instance.recordCallback) {
            instance.recordCallback(buffer1.mData, buffer1.mDataByteSize);
        }
    }
    return noErr;
}

- (BOOL)start {
    OSStatus status = AudioOutputUnitStart(iOUnit);
    return [self checkStatus:status];
}

- (BOOL)stop {
    OSStatus status = AudioOutputUnitStop(iOUnit);
    return [self checkStatus:status];
}

#pragma mark - Log
- (BOOL)checkStatus:(OSStatus)status error:(NSString *)error {
    if (status != 0) {
        if (error) {
            NSLog(@"ACCAudioPlayer Error:(%@)%@", @(status), error);
        } else {
            NSLog(@"ACCAudioPlayer Error:(%@)", @(status));
        }
        return  NO;
    }
    return  YES;
}
- (BOOL)checkStatus:(OSStatus)status {
    if (status != 0) {
        NSLog(@"checkStatus Error: %@", @(status));
        return  NO;
    }
    return  NO;
}

@end
