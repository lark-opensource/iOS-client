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

#import "TTHMDLeaksFinderConfig.h"
#import "TTHMDLeaksFinderDetector.h"
#import "TTHMDLeaksFinderRecord.h"
#import "TTHMDLeaskFinderTracker.h"

FOUNDATION_EXPORT double TTMLeaksFinderVersionNumber;
FOUNDATION_EXPORT const unsigned char TTMLeaksFinderVersionString[];