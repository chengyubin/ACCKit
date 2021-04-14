//
//  ACCTimerManager.h
//  ACCKit
//
//  Created by CCyber on 2019/1/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 自动管理timer生命周期
/// 独立timer线程

@interface ACCTimerManager : NSObject

#pragma mark - Class API

/// 这个方法提供固定间隔的计时器
/// @param key 计时器key
/// @param after 延迟触发时间，单位秒
/// @param interval 时间间隔
/// @param block block
+ (BOOL)validateTimerForKey:(NSString *)key
                      after:(NSTimeInterval)after
                   interval:(NSTimeInterval)interval
                      block:(void(^)(NSInteger count))block;

/// 这个方法提供固定间隔的计时器
/// @param key 计时器key
/// @param fireDate 触发时间，小于或等于当前时间则立即触发
/// @param interval 时间间隔
/// @param block 通过block返回的值决定是否终止定时器，返回值YES则终止定时器；count为执行block的次数。
/// @return YES代表成功，NO代表失败
+ (BOOL)validateTimerForKey:(NSString *)key
                   fireDate:(NSDate *)fireDate
                   interval:(NSTimeInterval)interval
                      block:(BOOL(^)(NSInteger count))block;


/// 这个方法提供可自定义间隔的计时器
/// @param key 计时器key
/// @param fireDate 触发时间，小于或等于当前时间则立即触发
/// @param block 通过block返回的值决定下一次触发定时器的时间，返回值<=0则终止定时器；count为执行block的次数。
/// @return YES代表成功，NO代表失败
+ (BOOL)validateTimerForKey:(NSString *)key
                   fireDate:(NSDate *)fireDate
                      block:(NSTimeInterval(^)(NSInteger count))block;

/// Invalidate Timer Methods
+ (void)invalidateAllTimer;
+ (void)invalidateTimerForKey:(NSString *)key;

///
+ (BOOL)isTimerExistForKey:(NSString *)key;

#pragma mark - Utils

/// 生成一个绑定object的key，当object为NSString时则直接返回object
/// @param object object
+ (NSString *)keyForObject:(id)object;

#pragma mark - Deprecated Methods
+ (instancetype)getInstance;

- (BOOL)isRegisteredForKey:(NSString *)key NS_DEPRECATED_IOS(10_0, 10_0, "Use isTimerExistForKey: instead");


- (void)registerTimerForKey:(NSString *)key
                   fireDate:(NSDate *)fireDate
                   interval:(NSTimeInterval)interval
                     repeat:(BOOL)repeat
                  fireBlock:(dispatch_block_t)fireBlock NS_DEPRECATED_IOS(10_0, 10_0, "Use validateTimerForKey:after:interval:block instead");

- (void)unregisterTimerForKey:(NSString *)key NS_DEPRECATED_IOS(10_0, 10_0, "Use invalidateTimerForKey: instead");

@end

NS_ASSUME_NONNULL_END
