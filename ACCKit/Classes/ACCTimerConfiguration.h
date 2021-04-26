//
//  ACCTimerConfiguration.h
//  ACCKit
//
//  Created by CCyber on 2021/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCTimerConfiguration : NSObject<NSCopying>

/// defaule [NSDate date]
@property (nonatomic, readonly, strong) NSDate *_fireDate;

///_interval and _dynamicInterval are alternative
///set _interval will disable _dynamicInterval
///set _dynamicInterval will disable _interval
/// default 0
@property (nonatomic, readonly) NSTimeInterval _interval;
/// default nil
@property (nonatomic, readonly, copy, nullable) NSTimeInterval(^_dynamicInterval)(NSInteger count);


/// default NO
@property (nonatomic, readonly) BOOL _repeats;


/// default 0.1
@property (nonatomic, readonly) NSTimeInterval _leeway;


/// default main queue
@property (nonatomic, readonly) dispatch_queue_t _dispatch_queue;


/// default nil
@property (nonatomic, readonly, strong, nullable) NSObject *_lifeTimeTracker;

+ (ACCTimerConfiguration *)defaultConfiguration;

- (ACCTimerConfiguration *)fireDate:(NSDate *)fireDate;
- (ACCTimerConfiguration *)interval:(NSTimeInterval)interval;
- (ACCTimerConfiguration *)dynamicInterval:(NSTimeInterval(^)(NSInteger count))dynamicInterval;
- (ACCTimerConfiguration *)repeats:(BOOL)repeats;
- (ACCTimerConfiguration *)leeway:(NSInteger)leeway;
- (ACCTimerConfiguration *)dispatchAt:(dispatch_queue_t)dispatch_queue;
- (ACCTimerConfiguration *)freeWith:(NSObject *)lifeTimeTracker;

@end

NS_ASSUME_NONNULL_END
