//
//  ACCAudioRecorder.h
//  ACCKit
//
//  Created by CCyber on 2021/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 使用前请设置 AVAudioSession的category为AVAudioSessionCategoryPlayAndRecord或AVAudioSessionCategoryRecord
@interface ACCAudioRecorder : NSObject

//多channel情况下，data为合并后音频
@property (nonatomic, copy) void(^recordCallback)(const void *data, uint size);
@property (nonatomic) BOOL enable;

/// 初始化
/// @param sampleRate 输出采样率
/// @param channelsPerFrame 输出channel数量
/// @param bitsPerChannel 输出位数
- (instancetype)initWithSampleRate:(int)sampleRate
                  channelsPerFrame:(int)channelsPerFrame
                    bitsPerChannel:(int)bitsPerChannel;

- (BOOL)start;
- (BOOL)stop;

@end

NS_ASSUME_NONNULL_END
