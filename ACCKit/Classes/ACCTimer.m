//
//  ACCTimer.m
//  ACCKit
//
//  Created by CCyber on 2019/1/11.
//

#import "ACCTimer.h"
#import "NSObject+ACCKit_Private.h"
#define kDefaultLeeway 0.1

@interface ACCTimer()
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, readwrite) NSInteger count;
@property (nonatomic, weak) id<ACCTimerDelegate> delegate;

@end

@implementation ACCTimer

- (instancetype)initWithConfiguration:(ACCTimerConfiguration * _Nullable)configuration
                                block:(void (^)(ACCTimer *timer))block
                             delegate:(id<ACCTimerDelegate>)delegate {
    if (self = [super init]) {
        configuration = [configuration copy];
        self.delegate = delegate;
        //create timer
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, configuration._dispatch_queue);
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, MAX(0, [configuration._fireDate timeIntervalSinceNow]) * NSEC_PER_SEC);

        __weak __typeof(self) weakSelf = self;
        
        BOOL repeats = configuration._repeats;
        NSTimeInterval leeway = configuration._leeway;
        
        if (configuration._dynamicInterval) {
            dispatch_source_set_timer(timer, time, DISPATCH_TIME_FOREVER, leeway * NSEC_PER_SEC);

            NSTimeInterval(^dynamicInterval)(NSInteger count) = configuration._dynamicInterval;
            dispatch_source_set_event_handler(timer, ^{
                __typeof(weakSelf) self = weakSelf;
                //count increase
                ++self.count;
                //perfrom block action
                block(self);
                                
                //invalidate non repeated timer after first action block triggered
                if (!repeats) {
                    [self invalidate];
                    
                }
                //otherwise, set next trigger time interval
                else {
                    NSTimeInterval nextTimerInterval = MAX(0, dynamicInterval(self.count));
                    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, nextTimerInterval * NSEC_PER_SEC);
                    dispatch_source_set_timer(self.timer, time, DISPATCH_TIME_FOREVER, leeway * NSEC_PER_SEC);
                }
            });
            
        } else {
            dispatch_source_set_timer(timer, time, configuration._interval * NSEC_PER_SEC, leeway * NSEC_PER_SEC);
            
            dispatch_source_set_event_handler(timer, ^{
                __typeof(weakSelf) self = weakSelf;
                //count increase
                ++self.count;
                //perfrom block action
                block(self);
                //invalidate non repeated timer after first action block triggered
                if (!repeats) {
                    [self invalidate];
                }
            });
        }
        self.timer = timer;
        if (configuration._lifeTimeTracker) {
            [self freeWith:configuration._lifeTimeTracker];
        }
    }
    return self;
}

- (void)invalidate {
    dispatch_source_cancel(self.timer);
    self.timer = nil;
    if ([self.delegate respondsToSelector:@selector(timerDidInvalidate:)]) {
        [self.delegate timerDidInvalidate:self];
    }
}

- (void)suspend {
    dispatch_suspend(self.timer);
}

- (void)resume {
    dispatch_resume(self.timer);
}

- (void)freeWith:(NSObject *)lifeTimeTracker {
    [lifeTimeTracker.acc_disposeBag addDisposeObject:self];
}

- (void)dispose {
    [self invalidate];
}

@end
