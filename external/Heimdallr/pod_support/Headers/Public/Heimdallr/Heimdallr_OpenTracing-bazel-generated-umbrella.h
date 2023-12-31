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

#import "HMDOTBridge.h"
#import "HMDOTConfig.h"
#import "HMDOTSpan.h"
#import "HMDOTSpanConfig.h"
#import "HMDOTTrace.h"
#import "HMDOTTraceConfig.h"
#import "HMDOTTraceDefine.h"

FOUNDATION_EXPORT double HeimdallrVersionNumber;
FOUNDATION_EXPORT const unsigned char HeimdallrVersionString[];