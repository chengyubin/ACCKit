//
//  ACCTimerConfiguration.m
//  ACCKit
//
//  Created by CCyber on 2021/4/25.
//

#import "ACCTimerConfiguration.h"
#define kConfigurationDefaultLeeway 0.1
@interface ACCTimerConfiguration()

@property (nonatomic, readwrite, strong) NSDate *_fireDate;

@property (nonatomic, readwrite) NSTimeInterval _interval;

@property (nonatomic, readwrite, copy, nullable) NSTimeInterval(^_dynamicInterval)(NSInteger count);

@property (nonatomic, readwrite) BOOL _repeats;

@property (nonatomic, readwrite) NSTimeInterval _leeway;

@property (nonatomic, readwrite) dispatch_queue_t _dispatch_queue;

@property (nonatomic, readwrite, strong, nullable) NSObject *_lifeTimeTracker;
@end

@implementation ACCTimerConfiguration
- (instancetype)init {
    self = [super init];
    if (self) {
        __fireDate = [NSDate date];
        __interval = 0;
        __repeats = NO;
        __leeway = kConfigurationDefaultLeeway;
        __dispatch_queue = dispatch_get_main_queue();
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ACCTimerConfiguration *copy = [[[self class] allocWithZone:zone] init];
    copy._fireDate = self._fireDate;
    copy._interval = self._interval;
    copy._dynamicInterval = self._dynamicInterval;
    copy._repeats = self._repeats;
    copy._leeway = self._leeway;
    copy._dispatch_queue = self._dispatch_queue;
    copy._lifeTimeTracker = self._lifeTimeTracker;
    return copy;
}

+ (ACCTimerConfiguration *)defaultConfiguration {
    return [ACCTimerConfiguration new];
}

- (ACCTimerConfiguration *)fireDate:(NSDate *)fireDate {
    __fireDate = fireDate;
    return self;
}
- (ACCTimerConfiguration *)interval:(NSTimeInterval)interval {
    NSCAssert(__dynamicInterval == nil, @"ACCTimerConfiguration: can't use interval after use dynamicInterval");
    __interval = interval;
    return self;
}

- (ACCTimerConfiguration *)dynamicInterval:(NSTimeInterval(^)(NSInteger count))dynamicInterval {
    NSCAssert(__interval == 0, @"ACCTimerConfiguration: can't use dynamicInterval after use interval");
    __dynamicInterval = [dynamicInterval copy];
    return self;
}

- (ACCTimerConfiguration *)repeats:(BOOL)repeats {
    __repeats = repeats;
    return self;
}
- (ACCTimerConfiguration *)leeway:(NSInteger)leeway {
    __leeway = leeway;
    return self;
}
- (ACCTimerConfiguration *)dispatchAt:(dispatch_queue_t)dispatch_queue {
    __dispatch_queue = dispatch_queue;
    return self;
}
- (ACCTimerConfiguration *)freeWith:(NSObject *)lifeTimeTracker {
    __lifeTimeTracker = lifeTimeTracker;
    return self;
}
@end
