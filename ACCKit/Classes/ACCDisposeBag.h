//
//  ACCDisposeBag.h
//  ACCKit
//
//  Created by CCyber on 2021/4/25.
//

#import <Foundation/Foundation.h>
#import "ACCDisposeObject.h"
NS_ASSUME_NONNULL_BEGIN

@interface ACCDisposeBag : NSObject

- (void)addDisposeObject:(id<ACCDisposeObject>)disposeObject;

@end

NS_ASSUME_NONNULL_END
