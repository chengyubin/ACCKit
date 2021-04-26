//
//  ACCTimerManager.h
//  ACCKit
//
//  Created by CCyber on 2019/1/11.
//

#import <Foundation/Foundation.h>
#import "ACCTimerOperator.h"
#import "ACCTimerConfiguration.h"
NS_ASSUME_NONNULL_BEGIN

/// 自动管理timer生命周期
/// 独立timer线程

@interface ACCTimerManager : NSObject

#pragma mark - ACCTimerOperator Methods
/*一次性定时器快捷初始化方式
 @param delay 延迟
 @param block 执行函数块
 @param lifeTimeTrigger 可通过绑定lifeTimeTrigger，实现lifeTimeTrigger释放时，自动释放定时器
*/
+ (ACCTimerOperator *)onceTimerWithDelay:(NSTimeInterval)delay block:(dispatch_block_t)block;
+ (ACCTimerOperator *)onceTimerWithDelay:(NSTimeInterval)delay block:(dispatch_block_t)block freeWith:(NSObject *_Nullable)lifeTimeTrigger;

/*传统定时器初始化方式
 @param date 触发时间
 @param interval 定时器间隔
 @param repeats 是否循环
 @param block 执行函数块，参数count代表当前循环次数，可通过设置*stop为YES终止定时器
 @param lifeTimeTrigger 可通过绑定lifeTimeTrigger，实现lifeTimeTrigger释放时，自动释放定时器
*/
+ (ACCTimerOperator *)scheduledTimerWithFireDate:(NSDate *)date timeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSInteger count, BOOL *stop))block;
+ (ACCTimerOperator *)scheduledTimerWithFireDate:(NSDate *)date timeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSInteger count, BOOL *stop))block freeWith:(NSObject *_Nullable)lifeTimeTrigger;

/*定时器高技初始化方式
 @param configuration 定时器配置
 @param block 执行函数块，参数count代表当前循环次数，可通过设置*stop为YES终止定时器
*/
+ (ACCTimerOperator *)scheduledTimerWithConfiguration:(ACCTimerConfiguration *)configuration block:(void (^)(NSInteger count, BOOL *stop))block;


#pragma mark - Key Operate Methods
+ (void)onceTimerWithKey:(NSString *)key delay:(NSTimeInterval)delay block:(dispatch_block_t)block;
+ (void)onceTimerWithKey:(NSString *)key delay:(NSTimeInterval)delay block:(dispatch_block_t)block freeWith:(NSObject *)lifeTimeTrigger;

+ (void)scheduledTimerWithKey:(NSString *)key fireDate:(NSDate *)date timeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSInteger count, BOOL *stop))block;
+ (void)scheduledTimerWithKey:(NSString *)key fireDate:(NSDate *)date timeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSInteger count, BOOL *stop))block freeWith:(NSObject *_Nullable)lifeTimeTrigger;

+ (void)scheduledTimerWithKey:(NSString *)key configuration:(ACCTimerConfiguration *)configuration block:(void (^)(NSInteger count, BOOL *stop))block;

+ (void)invalidateTimerForKey:(NSString *)key;

+ (BOOL)isTimerExistForKey:(NSString *)key;


#pragma mark - Utils
/// Invalidate Timer Methods
+ (void)invalidateAllTimer;

+ (NSArray<ACCTimerOperator *> *)allTimerOperator;
@end

NS_ASSUME_NONNULL_END
