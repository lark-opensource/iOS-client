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

#import "BDXBridgeReportADLogMethod+BDXBridgeIMP.h"
#import "BDXBridgeReportADLogMethod.h"
#import "BDXBridgeReportALogMethod+BDXBridgeIMP.h"
#import "BDXBridgeReportALogMethod.h"
#import "BDXBridgeReportAppLogMethod+BDXBridgeIMP.h"
#import "BDXBridgeReportAppLogMethod.h"
#import "BDXBridgeReportMonitorLogMethod+BDXBridgeIMP.h"
#import "BDXBridgeReportMonitorLogMethod.h"

FOUNDATION_EXPORT double BDXBridgeKitVersionNumber;
FOUNDATION_EXPORT const unsigned char BDXBridgeKitVersionString[];