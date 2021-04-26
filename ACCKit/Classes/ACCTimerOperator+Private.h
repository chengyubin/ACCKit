//
//  ACCTimerOperator+Private.h
//  ACCKit
//
//  Created by CCyber on 2021/4/25.
//

#import "ACCTimerOperator.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCTimerOperator ()
- (instancetype)initWithTimerKey:(NSString *)timerKey;

@property (nonatomic, copy, readonly) NSString *timerKey;
@end

NS_ASSUME_NONNULL_END
