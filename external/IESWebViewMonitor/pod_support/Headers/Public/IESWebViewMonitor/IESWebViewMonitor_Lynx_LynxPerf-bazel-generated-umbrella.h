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

#import "IESLynxMonitor.h"
#import "IESLynxMonitorConfig.h"
#import "IESLynxPerformanceDictionary.h"
#import "LynxView+Monitor.h"

FOUNDATION_EXPORT double IESWebViewMonitorVersionNumber;
FOUNDATION_EXPORT const unsigned char IESWebViewMonitorVersionString[];