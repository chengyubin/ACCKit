#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "ACCKit.h"
#import "ACCSensorMonitor.h"
#import "ACCTimer.h"
#import "ACCTimerManager.h"

FOUNDATION_EXPORT double ACCKitVersionNumber;
FOUNDATION_EXPORT const unsigned char ACCKitVersionString[];

