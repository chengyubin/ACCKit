//
//  ACCTimerManager.m
//  ACCKit
//
//  Created by CCyber on 2019/1/11.
//

#import "ACCTimerManager.h"
#import "ACCTimer.h"
#import "ACCTimerOperator+Private.h"
@interface ACCTimerManager()<ACCTimerDelegate>
@property (nonatomic) dispatch_queue_t timerQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ACCTimer *> *timerDictionary;

@end


@implementation ACCTimerManager
+ (instancetype)getInstance {
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[ACCTimerManager alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timerQueue = dispatch_queue_create("ACCTimerManager.Timer", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Class Create Api - Operate via ACCTimerOperator
+ (ACCTimerOperator *)onceTimerWithDelay:(NSTimeInterval)delay block:(dispatch_block_t)block {
    return [ACCTimerManager onceTimerWithDelay:delay block:block freeWith:nil];
}

+ (ACCTimerOperator *)onceTimerWithDelay:(NSTimeInterval)delay block:(dispatch_block_t)block freeWith:(NSObject * _Nullable)lifeTimeTrigger {
    ACCTimerConfiguration *configuration = [[[ACCTimerConfiguration defaultConfiguration] fireDate:[NSDate dateWithTimeIntervalSinceNow:delay]] freeWith:lifeTimeTrigger];
    return [[ACCTimerManager getInstance] scheduledTimerWithKey:nil configuration:configuration block:^(NSInteger count, BOOL *stop) {
        [block invoke];
    }];
}

+ (ACCTimerOperator *)scheduledTimerWithFireDate:(NSDate *)date timeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSInteger count, BOOL *stop))block {
    return [ACCTimerManager scheduledTimerWithFireDate:date timeInterval:interval repeats:repeats block:block freeWith:nil];
}

+ (ACCTimerOperator *)scheduledTimerWithFireDate:(NSDate *)date timeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSInteger count, BOOL *stop))block freeWith:(NSObject *_Nullable)lifeTimeTrigger{
    ACCTimerConfiguration *configuration = [[[[[ACCTimerConfiguration defaultConfiguration] fireDate:date] interval:interval] repeats:repeats] freeWith:lifeTimeTrigger];

    return [[ACCTimerManager getInstance] scheduledTimerWithKey:nil configuration:configuration block:block];
}


+ (ACCTimerOperator *)scheduledTimerWithConfiguration:(ACCTimerConfiguration *)configuration block:(void (^)(NSInteger count, BOOL *stop))block {
    return [[ACCTimerManager getInstance] scheduledTimerWithKey:nil configuration:configuration block:block];
}

#pragma mark - Class Create Api - Operate via key
+ (BOOL)onceTimerWithKey:(NSString *)key delay:(NSTimeInterval)delay block:(dispatch_block_t)block {
    return [ACCTimerManager onceTimerWithKey:key delay:delay block:block freeWith:nil];
}

+ (BOOL)onceTimerWithKey:(NSString *)key delay:(NSTimeInterval)delay block:(dispatch_block_t)block freeWith:(NSObject *_Nullable)lifeTimeTrigger {
    ACCTimerConfiguration *configuration = [[[ACCTimerConfiguration defaultConfiguration] fireDate:[NSDate dateWithTimeIntervalSinceNow:delay]] freeWith:lifeTimeTrigger];
    return [[ACCTimerManager getInstance] scheduledTimerWithKey:key configuration:configuration block:^(NSInteger count, BOOL *stop) {
        [block invoke];
    }] != nil;
}

+ (BOOL)scheduledTimerWithKey:(NSString *)key fireDate:(NSDate *)date timeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSInteger count, BOOL *stop))block{
    return [ACCTimerManager scheduledTimerWithKey:key fireDate:date timeInterval:interval repeats:repeats block:block freeWith:nil];
}

+ (BOOL)scheduledTimerWithKey:(NSString *)key fireDate:(NSDate *)date timeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSInteger count, BOOL *stop))block freeWith:(NSObject *_Nullable)lifeTimeTrigger{
    ACCTimerConfiguration *configuration = [[[[[ACCTimerConfiguration defaultConfiguration] fireDate:date] interval:interval] repeats:repeats] freeWith:lifeTimeTrigger];

    return [[ACCTimerManager getInstance] scheduledTimerWithKey:key configuration:configuration block:block] != nil;
}

+ (BOOL)scheduledTimerWithKey:(NSString *)key configuration:(ACCTimerConfiguration *)configuration block:(void (^)(NSInteger count, BOOL *stop))block {
    return [[ACCTimerManager getInstance] scheduledTimerWithKey:key configuration:configuration block:block] != nil;
}


#pragma mark - Class Destory Api
+ (void)invalidateAllTimer {
    [[ACCTimerManager getInstance] invalidateAllTimer];
}

+ (void)invalidateTimerForKey:(NSString *)key {
    [[ACCTimerManager getInstance] invalidateTimerForKey:key];

}
+ (BOOL)isTimerExistForKey:(NSString *)key {
    return [[ACCTimerManager getInstance] isTimerExistForKey:key];
}

+ (NSArray<ACCTimerOperator *> *)allTimerOperator {
    return [[ACCTimerManager getInstance] allTimerOperator];
}

#pragma mark - Instance Api
- (void)invalidateAllTimer {
    
    [[self.timerDictionary allValues] enumerateObjectsUsingBlock:^(ACCTimer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj invalidate];
    }];
}

- (void)invalidateTimerForKey:(NSString *)key {
    ACCTimer *timer = [self.timerDictionary objectForKey:key];
    if (timer) {
        [timer invalidate];
    }
}

- (BOOL)isTimerExistForKey:(NSString *)key {
    if ([self.timerDictionary objectForKey:key]) {
        return YES;
    }
    return NO;
}

- (NSArray<ACCTimerOperator *> *)allTimerOperator {
    NSMutableArray *allTimerOperator = [NSMutableArray new];
    NSArray<ACCTimer *> *timers = [self.timerDictionary allValues].copy;
    [timers enumerateObjectsUsingBlock:^(ACCTimer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ACCTimerOperator *operator = [[ACCTimerOperator alloc] initWithTimerKey:obj.key];
        [allTimerOperator addObject:operator];
    }];
    return allTimerOperator;
}
#pragma mark - Utils
+ (NSString *)keyForObject:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    NSString *key = [NSString stringWithFormat:@"%p",object];
    return key;
}

- (NSString *)registerTimer:(ACCTimer *)timer forKey:(NSString *)key {
    NSString *finalKey;
    if (timer) {
        finalKey = key?key:[ACCTimerManager keyForObject:timer];
        timer.key = finalKey;
        [self.timerDictionary setObject:timer forKey:finalKey];
    }
    return finalKey;
}

- (void)unregisterTimerForKey:(NSString *)key {
    [self.timerDictionary removeObjectForKey:key];
//    NSLog(@"timer:%@ did unregistered",key);
}

#pragma mark - Getter
- (NSMutableDictionary<NSString *, ACCTimer *> *)timerDictionary {
    if (!_timerDictionary) {
        _timerDictionary = [NSMutableDictionary new];
    }
    return _timerDictionary;
}

#pragma mark - ACCTimerDelegate
- (void)timerDidInvalidate:(ACCTimer *)timer {
//    NSLog(@"timer:%@ did invalidated",timer.key);
    [self unregisterTimerForKey:timer.key];
}

#pragma mark - 1.0.2 Version
- (ACCTimerOperator *)scheduledTimerWithKey:(NSString *)key configuration:(ACCTimerConfiguration *)configuration block:(void (^)(NSInteger count, BOOL *stop))block {
    if (!block) {
        return nil;
    }
    if (key && [self isTimerExistForKey:key]) {
        return nil;
    }
    
    ACCTimer *timer = [[ACCTimer alloc] initWithConfiguration:configuration block:^(ACCTimer * _Nonnull timer) {
        BOOL stop = NO;
        block(timer.count, &stop);
        if (stop) {
            [timer invalidate];
        }
    } delegate:self];
    [timer resume];
    
    ACCTimerOperator *operator = [[ACCTimerOperator alloc] initWithTimerKey:[self registerTimer:timer forKey:key]];

    return operator;
}



@end
