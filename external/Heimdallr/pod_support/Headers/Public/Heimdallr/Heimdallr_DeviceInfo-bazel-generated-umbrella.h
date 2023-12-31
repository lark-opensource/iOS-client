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

#import "HMDDiskUsage.h"
#import "HMDInjectedInfo+LegacyDBOptimize.h"
#import "HMDInjectedInfo+MovingLine.h"
#import "HMDInjectedInfo+NetMonitorConfig.h"
#import "HMDInjectedInfo+NetworkSchedule.h"
#import "HMDInjectedInfo+PerfOptSwitch.h"
#import "HMDInjectedInfo.h"

FOUNDATION_EXPORT double HeimdallrVersionNumber;
FOUNDATION_EXPORT const unsigned char HeimdallrVersionString[];