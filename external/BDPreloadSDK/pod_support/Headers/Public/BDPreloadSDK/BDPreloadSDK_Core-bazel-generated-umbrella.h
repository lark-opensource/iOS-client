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

#import "BDPreloadConfig.h"
#import "BDPreloadDebugView.h"
#import "BDPreloadManager.h"
#import "BDPreloadMonitor.h"
#import "BDPreloadUtil.h"
#import "NSOperation+BDPreloadTask.h"

FOUNDATION_EXPORT double BDPreloadSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char BDPreloadSDKVersionString[];