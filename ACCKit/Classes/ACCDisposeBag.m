//
//  ACCDisposeBag.m
//  ACCKit
//
//  Created by CCyber on 2021/4/25.
//

#import "ACCDisposeBag.h"
@interface ACCDisposeBag()

@property (strong, nonatomic) NSPointerArray * disposeObjects;

@end
@implementation ACCDisposeBag
- (void)addDisposeObject:(id<ACCDisposeObject>)disposeObject {
    @synchronized(self) {
        [self.disposeObjects addPointer:(__bridge void * _Nullable)(disposeObject)];
    }
}


- (void)dealloc{
    @synchronized(self) {
        for (id<ACCDisposeObject> disposeObject in self.disposeObjects.allObjects) {
            if ([disposeObject respondsToSelector:@selector(dispose)]) {
                [disposeObject dispose];
            }
        }
    }
}

#pragma mark - Lazy load
- (NSPointerArray *)disposeObjects {
    if (!_disposeObjects) {
        _disposeObjects = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _disposeObjects;
}

@end
