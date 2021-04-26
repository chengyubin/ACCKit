//
//  ACCTimer.h
//  ACCKit
//
//  Created by CCyber on 2019/1/11.
//

#import <Foundation/Foundation.h>
#import "ACCDisposeObject.h"
#import "ACCTimerConfiguration.h"
NS_ASSUME_NONNULL_BEGIN

@class ACCTimer;
@protocol ACCTimerDelegate<NSObject>
- (void)timerDidInvalidate:(ACCTimer *)timer;
@end


@interface ACCTimer : NSObject<ACCDisposeObject>

- (instancetype)initWithConfiguration:(ACCTimerConfiguration * _Nullable)configuration
                                block:(void (^)(ACCTimer *timer))block
                             delegate:(id<ACCTimerDelegate>)delegate;

@property (nonatomic, readonly) NSInteger count;

@property (nonatomic, copy) NSString *key;

///default 0.1s
@property (nonatomic) NSInteger leeway;

/// invalidate current timer
- (void)invalidate;
- (void)suspend;
- (void)resume;
@end


NS_ASSUME_NONNULL_END
