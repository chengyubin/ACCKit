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
    AudioComponentInstance au_component;
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
    if (au_component) {
        AudioComponentInstanceDispose(au_component);
    }
}

- (void)initPlayer {
    _enable = YES;
    buffer = malloc(sizeof(TPCircularBuffer));
    TPCircularBufferInit(buffer, _sampleRate*_channelsPerFrame*_bitsPerChannel/8);

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
    status = AudioComponentInstanceNew(inputComponent, &au_component);         //实现这个部件单元
    [self checkStatus:status];
    
    
    //bus0 应用输出到硬件
    AudioUnitElement bus0 = 0;
    {
        // Enable IO for playing（kAudioUnitScope_Input ==> recording）
        // flag 1 means start, 0 means stop
        uint32_t flag = 1;
        status = AudioUnitSetProperty(au_component,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Output, //【播放必定选kAudioUnitScope_Output!!!】
                                      bus0,
                                      &flag,
                                      sizeof(flag));
        [self checkStatus:status];
        
        
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
        status = AudioUnitSetProperty(au_component,
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
        status = AudioUnitSetProperty(au_component,
                                      kAudioUnitProperty_SetRenderCallback,
                                      kAudioUnitScope_Global,
                                      bus0,
                                      &callbackStruct,
                                      sizeof(callbackStruct));
        [self checkStatus:status];

    }
   
    //设置好后，初始化音频组件！！！
    status = AudioUnitInitialize(au_component);
    [self checkStatus:status];
    
    NSLog(@"ACCAudioPlayer:初始化成功");
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
        if (instance.enable) {
            memcpy(frameBuffer, bufferTail, len);
        }
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

-(BOOL)didPlayerStart{
    OSStatus status = AudioOutputUnitStart(au_component);
    return [self checkStatus:status];
}

-(BOOL)didPlayerStop{
    OSStatus status = AudioOutputUnitStop(au_component);
    return [self checkStatus:status];
}

-(BOOL)didPlayerRelease{
    if ([self didPlayerStop] == NO) {
        return NO;
    }
    
    OSStatus status = AudioUnitUninitialize(au_component);
    return [self checkStatus:status];
}

- (BOOL)start {
    return [self didPlayerStart];
}
- (BOOL)stop {
    return [self didPlayerRelease];
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
    if (self.enable) {
        TPCircularBufferProduceBytes(buffer, data, (uint32_t)size);
    }
}

#pragma mark - Utils
-(void)setVolume:(double)volume {
    MPVolumeView *volumeView = [[MPVolumeView alloc]init];
    volumeView.showsVolumeSlider = YES;
    UISlider *volumeViewSlider = nil;
    if (volumeViewSlider == nil) {
        for (UIView *view in [volumeView subviews]) {
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
                volumeViewSlider = (UISlider *)view;
                break;
            }
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [volumeViewSlider setValue:volume animated:NO];
        [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    });
}

- (BOOL)checkStatus:(OSStatus)status {
    if (status != 0) {
        NSLog(@"checkStatus Error: %@", @(status));
        return  NO;
    }
    return  NO;
}

@end
