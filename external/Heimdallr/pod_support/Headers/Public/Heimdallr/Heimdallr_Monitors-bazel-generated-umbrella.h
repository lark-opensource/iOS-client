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

#import "HMDBatteryMonitor.h"
#import "HMDBatteryMonitorRecord.h"
#import "HMDCPUMonitor.h"
#import "HMDCPUMonitorRecord.h"
#import "HMDDiskMonitor.h"
#import "HMDDiskMonitorRecord.h"
#import "HMDFPSMonitor.h"
#import "HMDFPSMonitorRecord.h"
#import "HMDFluencyDisplayLink.h"
#import "HMDFrameDropMonitor.h"
#import "HMDFrameDropRecord.h"
#import "HMDMemoryMonitor.h"
#import "HMDMemoryMonitorRecord.h"
#import "HMDMonitor.h"
#import "HMDMonitorCallbackObject.h"
#import "HMDMonitorConfig.h"
#import "HMDMonitorCurve.h"
#import "HMDMonitorCurve2.h"
#import "HMDMonitorCustomSwitch.h"
#import "HMDMonitorRecord+DBStore.h"
#import "HMDMonitorRecord.h"
#import "HMDPerformanceAggregate.h"

FOUNDATION_EXPORT double HeimdallrVersionNumber;
FOUNDATION_EXPORT const unsigned char HeimdallrVersionString[];