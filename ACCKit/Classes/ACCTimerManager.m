//
//  ACCTimerManager.m
//  ACCKit
//
//  Created by CCyber on 2019/1/11.
//

#import "ACCTimerManager.h"
#import "ACCTimer.h"
@interface ACCTimerManager()
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

- (BOOL)isRegisteredForKey:(NSString *)key {
    if ([self.timerDictionary objectForKey:key]) {
        return YES;
    }
    return NO;
}

- (void)registerTimerForKey:(NSString *)key fireDate:(NSDate *)fireDate interval:(NSTimeInterval)interval repeat:(BOOL)repeat fireBlock:(dispatch_block_t)fireBlock {
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.timerQueue);
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, [fireDate timeIntervalSinceNow] * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    __weak __typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        __typeof(weakSelf) strongSelf = weakSelf;

        [fireBlock invoke];
        if (!repeat) {
            [strongSelf unregisterTimerForKey:key];
        }
    });
    dispatch_resume(timer);
    
    ACCTimer *timerModel = [ACCTimer new];
    timerModel.timer = timer;
    [self.timerDictionary setObject:timerModel forKey:key];
}

- (void)unregisterTimerForKey:(NSString *)key {
    ACCTimer *timerModel = [self.timerDictionary objectForKey:key];
    if (timerModel) {
        dispatch_source_cancel(timerModel.timer);
        [self.timerDictionary removeObjectForKey:key];
    }
}


- (void)perform:(dispatch_block_t)block interval:(NSTimeInterval)interval repeatTimes:(NSInteger)repeatTimes until:(BOOL(^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) block();
        if (repeatTimes <= 0) {
            return ;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completion && !completion()) {
                [self perform:block interval:interval repeatTimes:repeatTimes-1 until:completion];
            }
        });
    });
}
////////////////////////////////////////////////////////////
///New API
////////////////////////////////////////////////////////////
#pragma mark - Class API
+ (BOOL)validateTimerForKey:(NSString *)key
                      after:(NSTimeInterval)after
                   interval:(NSTimeInterval)interval
                      block:(void(^)(NSInteger count))block {
    return [[ACCTimerManager getInstance] validateTimerForKey:key fireDate:[[NSDate date] dateByAddingTimeInterval:after] interval:interval block:^BOOL(NSInteger count) {
        if (block) {
            block(count);
        }
        return NO;
    }];
}

+ (BOOL)validateTimerForKey:(NSString *)key
                   fireDate:(NSDate *)fireDate
                   interval:(NSTimeInterval)interval
                      block:(BOOL(^)(NSInteger count))block {
    return [[ACCTimerManager getInstance] validateTimerForKey:key fireDate:fireDate interval:interval block:block];
}

+ (BOOL)validateTimerForKey:(NSString *)key
                   fireDate:(NSDate *)fireDate
                      block:(NSTimeInterval(^)(NSInteger count))block {
    return [[ACCTimerManager getInstance] validateTimerForKey:key fireDate:fireDate block:block];
}

+ (void)invalidateAllTimer {
    [[ACCTimerManager getInstance] invalidateAllTimer];
}

+ (void)invalidateTimerForKey:(NSString *)key {
    [[ACCTimerManager getInstance] invalidateTimerForKey:key];

}
+ (BOOL)isTimerExistForKey:(NSString *)key {
    return [[ACCTimerManager getInstance] isTimerExistForKey:key];
}

#pragma mark - Object API
- (BOOL)validateTimerForKey:(NSString *)key
                   fireDate:(NSDate *)fireDate
                   interval:(NSTimeInterval)interval
                      block:(BOOL(^)(NSInteger count))block {
    if (!key) {
        NSLog(@"%s: key is nil，validate timer failed",__func__);
        return NO;
    }
    
    if (!block) {
        NSLog(@"%s: block is nil，validate timer failed",__func__);
        return NO;
    }
    
    if ([self isTimerExistForKey:key]) {
        NSLog(@"%s: timer for key %@ existed",__func__, key);
        return NO;
    }
    ACCTimer *timerModel = [ACCTimer new];
    [self.timerDictionary setObject:timerModel forKey:key];

    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.timerQueue);
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, MAX(0, [fireDate timeIntervalSinceNow]) * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    __weak __typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        __typeof(weakSelf) strongSelf = weakSelf;
        NSInteger count = ++[strongSelf.timerDictionary objectForKey:key].count;
        
        //invalidate timer if block return YES
        if (block(count)) {
            [strongSelf invalidateTimerForKey:key];
        }
    });
    dispatch_resume(timer);
    
    timerModel.timer = timer;
        
    return YES;
}

- (BOOL)validateTimerForKey:(NSString *)key
                   fireDate:(NSDate *)fireDate
                      block:(NSTimeInterval(^)(NSInteger count))block {
    if (!key) {
        NSLog(@"%s: key is nil，validate timer failed",__func__);
        return NO;
    }
    
    if (!block) {
        NSLog(@"%s: block is nil，validate timer failed",__func__);
        return NO;
    }
    
    if ([self isTimerExistForKey:key]) {
        NSLog(@"%s: timer for key %@ existed",__func__, key);
        return NO;
    }
    ACCTimer *timerModel = [ACCTimer new];
    [self.timerDictionary setObject:timerModel forKey:key];

    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.timerQueue);
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, MAX(0, [fireDate timeIntervalSinceNow]) * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0.1 * NSEC_PER_SEC);
    __weak __typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        __typeof(weakSelf) strongSelf = weakSelf;
        NSInteger count = ++[strongSelf.timerDictionary objectForKey:key].count;
        
        //invalidate timer if block return YES
        NSTimeInterval nextTimerInterval = block(count);
        if (nextTimerInterval <= 0) {
            [strongSelf invalidateTimerForKey:key];
        } else {
            dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, MAX(0, nextTimerInterval) * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0.1 * NSEC_PER_SEC);
        }
    });
    dispatch_resume(timer);
    
    timerModel.timer = timer;
    return YES;
}

- (void)invalidateAllTimer {
    [[self.timerDictionary allKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self invalidateTimerForKey:obj];
    }];
}

- (void)invalidateTimerForKey:(NSString *)key {
    ACCTimer *timerModel = [self.timerDictionary objectForKey:key];
    if (timerModel) {
        dispatch_source_cancel(timerModel.timer);
        [self.timerDictionary removeObjectForKey:key];
    }
}

- (BOOL)isTimerExistForKey:(NSString *)key {
    if ([self.timerDictionary objectForKey:key]) {
        return YES;
    }
    return NO;
}

#pragma mark - Utils
+ (NSString *)keyForObject:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    NSString *key = [NSString stringWithFormat:@"%p",object];
    return key;
}

#pragma mark - Getter
- (NSMutableDictionary<NSString *, ACCTimer *> *)timerDictionary {
    if (!_timerDictionary) {
        _timerDictionary = [NSMutableDictionary new];
    }
    return _timerDictionary;
}

@end
