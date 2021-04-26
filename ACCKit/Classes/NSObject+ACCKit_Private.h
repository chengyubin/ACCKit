//
//  NSObject+ACCKit_Private.h
//  ACCKit
//
//  Created by CCyber on 2021/4/25.
//

#import <Foundation/Foundation.h>
#import "ACCDisposeBag.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ACCKit_Private)
/**
 释放包
 */
@property (strong, nonatomic, readonly) ACCDisposeBag * acc_disposeBag;

@end

NS_ASSUME_NONNULL_END
