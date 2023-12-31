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

#import "STDefines.h"
#import "STHookInfo.h"
#import "STHookInfoPool.h"
#import "Stinger.h"
#import "StingerMacro.h"
#import "StingerParams.h"

FOUNDATION_EXPORT double StingerVersionNumber;
FOUNDATION_EXPORT const unsigned char StingerVersionString[];