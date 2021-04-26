//
//  NSObject+ACCKit_Private.m
//  ACCKit
//
//  Created by CCyber on 2021/4/25.
//

#import "NSObject+ACCKit_Private.h"
#import <objc/runtime.h>

static const char acckit_disposeContext;

@implementation NSObject (ACCKit_Private)

- (ACCDisposeBag *)acc_disposeBag{
    ACCDisposeBag * bag = objc_getAssociatedObject(self, &acckit_disposeContext);
    if (!bag) {
        bag = [[ACCDisposeBag alloc] init];
        objc_setAssociatedObject(self, &acckit_disposeContext, bag, OBJC_ASSOCIATION_RETAIN);
    }
    return bag;
}



@end
