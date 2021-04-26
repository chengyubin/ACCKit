//
//  ACCTimerOperator.m
//  ACCKit
//
//  Created by CCyber on 2021/4/25.
//

#import "ACCTimerOperator.h"
#import "ACCTimerOperator+Private.h"
#import "ACCTimerManager.h"

@implementation ACCTimerOperator
- (instancetype)initWithTimerKey:(NSString *)timerKey {
    if (self = [super init]) {
        _timerKey = [timerKey copy];
    }
    return self;
}

- (void)invalidate {
    [ACCTimerManager invalidateTimerForKey:self.timerKey];
}

- (BOOL)isTimerExist {
    return [ACCTimerManager isTimerExistForKey:self.timerKey];
}

@end
