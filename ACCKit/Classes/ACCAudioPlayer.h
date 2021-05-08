//
//  ACCAudioPlayer.h
//  ACCKit
//
//  Created by CCyber on 2021/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// 使用前请设置 AVAudioSession的category为AVAudioSessionCategoryPlayAndRecord或AVAudioSessionCategoryPlayback
@interface ACCAudioPlayer : NSObject

/// 初始化
/// @param sampleRate 输入采样率
/// @param channelsPerFrame 输入channel数量
/// @param bitsPerChannel 输入位数
- (instancetype)initWithSampleRate:(int)sampleRate
                  channelsPerFrame:(int)channelsPerFrame
                    bitsPerChannel:(int)bitsPerChannel;

//播放前回调，isDataEnough表示是否有足够数据送给audiounit
@property (nonatomic, copy, nullable) void(^willPlaybackCallback)(BOOL isDataEnough) ;
@property (nonatomic) BOOL enable;

- (BOOL)start;
- (BOOL)stop;
- (void)appendPCM:(const void *)data size:(uint)size;

//本地buffer数据是否足够下一次audiounit播放
- (BOOL)isBufferDataEnough;

#pragma mark - Utils
-(void)setVolume:(double)volume;

@end

NS_ASSUME_NONNULL_END
