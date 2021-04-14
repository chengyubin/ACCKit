//
//  ACCTimer.h
//  ACCKit
//
//  Created by CCyber on 2019/1/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCTimer : NSObject
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic) NSInteger count;
@end


NS_ASSUME_NONNULL_END
