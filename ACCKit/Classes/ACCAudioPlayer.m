//
//  ACCAudioPlayer.m
//  ACCKit
//
//  Created by CCyber on 2021/4/13.
//

#import "ACCAudioPlayer.h"
#import <TPCircularBuffer/TPCircularBuffer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
@interface ACCAudioPlayer()
{
    AudioComponentInstance iOUnit;
    AudioComponentInstance mixerUnit;

    TPCircularBuffer *buffer;
}

@property (nonatomic) UInt32 sampleRate;
@property (nonatomic) UInt32 channelsPerFrame;
@property (nonatomic) UInt32 bitsPerChannel;

@property (nonatomic) UInt32 dataByteSizeNeedPreCallback;

@end

@implementation ACCAudioPlayer


- (instancetype)initWithSampleRate:(int)sampleRate channelsPerFrame:(int)channelsPerFrame bitsPerChannel:(int)bitsPerChannel {
    if (self = [super init]) {
        _sampleRate = sampleRate;
        _channelsPerFrame = channelsPerFrame;
        _bitsPerChannel = bitsPerChannel;
        [self initPlayer];
    }
    return self;
}

- (void)dealloc {
    if (iOUnit) {
        AudioComponentInstanceDispose(iOUnit);
    }
    if (mixerUnit) {
        AudioComponentInstanceDispose(mixerUnit);
    }
}

- (void)initPlayer {
    _enable = YES;
    buffer = malloc(sizeof(TPCircularBuffer));
    TPCircularBufferInit(buffer, _sampleRate*_channelsPerFrame*_bitsPerChannel/8);
    BOOL result = YES;
    result &= [self configIOUnit];
    result &= [self configMixerUnit];
    
    //make connection, mixunit bus0 output to iounit bus0 input
    AudioUnitConnection connection;
    connection.sourceAudioUnit    = mixerUnit;
    connection.sourceOutputNumber = 0;
    connection.destInputNumber    = 0;
    
    OSStatus status = AudioUnitSetProperty(iOUnit,
                                           kAudioUnitProperty_MakeConnection,
                                           kAudioUnitScope_Input,
                                           0,
                                           &connection,
                                           sizeof(connection));
    result &= [self checkStatus:status error:@"make connection failed"];
    
    NSLog(@"ACCAudioPlayer:初始化%@",result?@"成功":@"失败");
}

- (BOOL)configIOUnit {
    BOOL result = YES;
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
    result &= [self checkStatus:status error:@"iOUnit AudioUnitInitialize failed"];

    
    //bus0 应用输出到硬件
    AudioUnitElement bus0 = 0;
    {
        // Enable IO for playing（kAudioUnitScope_Input ==> recording）
        // flag 1 means start, 0 means stop
        uint32_t flag = 1;
        status = AudioUnitSetProperty(iOUnit,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Output, //【播放必定选kAudioUnitScope_Output!!!】
                                      bus0,
                                      &flag,
                                      sizeof(flag));
        result &= [self checkStatus:status error:@"iOUnit kAudioOutputUnitProperty_EnableIO failed"];
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

    //Describe format 参数可以根据项目需要自行调整
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate       = _sampleRate;
    audioFormat.mBitsPerChannel   = _bitsPerChannel;
    audioFormat.mChannelsPerFrame = _channelsPerFrame;
    audioFormat.mFormatID         = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket  = 1;
    audioFormat.mBytesPerFrame    = audioFormat.mChannelsPerFrame * audioFormat.mBitsPerChannel/8;
    audioFormat.mBytesPerPacket   = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket;
    
    //设置输入音频的format
    status = AudioUnitSetProperty(mixerUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &audioFormat,
                                  sizeof(audioFormat));
    result &= [self checkStatus:status error:@"mixerUnit kAudioUnitProperty_StreamFormat failed"];
    
    Float64 sampleRate = _sampleRate;
    
    status = AudioUnitSetProperty(mixerUnit,
                                  kAudioUnitProperty_SampleRate,
                                  kAudioUnitScope_Output,
                                  0,
                                  &audioFormat,
                                  sizeof(sampleRate));
    
    result &= [self checkStatus:status error:@"mixerUnit kAudioUnitProperty_StreamFormat failed"];

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
    callbackStruct.inputProc = (AURenderCallback)on_Audio_Playback;//自己命名一个回调函数
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(mixerUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  0,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    result &= [self checkStatus:status error:@"mixerUnit kAudioUnitProperty_SetRenderCallback failed"];
    return result;
}

static OSStatus on_Audio_Playback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  uint32_t inBusNumber,
                                  uint32_t inNumberFrames,
                                  AudioBufferList *ioData) {
    
    ACCAudioPlayer *instance = (__bridge ACCAudioPlayer *)inRefCon;
    /*----------------------------------------------------------------------
     |   1.根据buffer.mDataByteSize大小需求，给buffer.mData赋值相应大小的数据内容;|
     |   2.若无数据，则把数据填写为0，默认正在播放无声音频；                        |
     |       UInt16 *frameBuffer = buffer.mData;                           |
     |       for (int j = 0; j < inNumberFrames; j++) {                    |
     |           frameBuffer[j] = 0;                                       |
     |       }                                                             |
     ----------------------------------------------------------------------*/
    for (int i=0; i < ioData->mNumberBuffers; i++) {
        AudioBuffer buffer = ioData->mBuffers[i];
        UInt16 *frameBuffer = buffer.mData;
        UInt32 byteSize = buffer.mDataByteSize;
        
        //默认播放静音
        memset(frameBuffer, 0, byteSize);
        
        uint32_t availableBytes = 0;
        void *bufferTail = TPCircularBufferTail(instance->buffer, &availableBytes);
        
        UInt32 len = 0;
        len = (byteSize > availableBytes ? availableBytes : byteSize);
        memcpy(frameBuffer, bufferTail, len);
        TPCircularBufferConsume(instance->buffer, len);
        
        //回调通知本次播放数据是否足够
        if (instance.willPlaybackCallback) {
            instance.willPlaybackCallback(availableBytes >= byteSize);
        }

        //将每次buffer所需的数据大小缓存起来，用作本地buffer的长度
        instance->_dataByteSizeNeedPreCallback = byteSize;

    }

    return noErr;
}

- (BOOL)start {
    OSStatus status;
    BOOL result = YES;
    status = AudioUnitInitialize(mixerUnit);
    result &= [self checkStatus:status error:@"mixerUnit AudioUnitInitialize failed"];
    status = AudioUnitInitialize(iOUnit);
    result &= [self checkStatus:status error:@"iOUnit AudioUnitInitialize failed"];
    
    status = AudioOutputUnitStart(iOUnit);
    result &= [self checkStatus:status error:@"iOUnit AudioOutputUnitStart failed"];
    return result;
}
- (BOOL)stop {
    OSStatus status;
    BOOL result = YES;

    status = AudioOutputUnitStop(iOUnit);
    result &= [self checkStatus:status error:@"iOUnit AudioOutputUnitStop failed"];
    
    status = AudioUnitUninitialize(mixerUnit);
    result &= [self checkStatus:status error:@"mixerUnit AudioUnitUninitialize failed"];
    status = AudioUnitUninitialize(iOUnit);
    result &= [self checkStatus:status error:@"iOUnit AudioUnitUninitialize failed"];
    return result;
}

- (BOOL)isBufferDataEnough {
    uint32_t fill;
    TPCircularBufferTail(buffer, &fill);
    
    //buffer长度默认是10ms音频数据的长度
    int bufferLength = _sampleRate*_channelsPerFrame*_bitsPerChannel/8*0.1;
    if (_dataByteSizeNeedPreCallback > 0) {
        bufferLength = _dataByteSizeNeedPreCallback;
    }
    if (fill > bufferLength) {
        return YES;
    }
    return NO;
}

- (void)appendPCM:(const void *)data size:(uint)size {
    TPCircularBufferProduceBytes(buffer, data, (uint32_t)size);
}

#pragma mark - Utils
-(void)setVolume:(double)volume {
    //设置mixerUnit输出的音量
    OSStatus status = AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, volume, 0);
    [self checkStatus:status error:@"mixerUnit kMultiChannelMixerParam_Volume failed"];
}

- (void)setMixerUnitEnable:(BOOL)enable {
    //设置mixerUnit输入的enable
    int enableInt = enable?1:0;
    
    OSStatus status = AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 0, enableInt, 0);
    [self checkStatus:status error:@"mixerUnit kMultiChannelMixerParam_Enable failed"];
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    [self setMixerUnitEnable:enable];
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
@end
