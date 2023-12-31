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

#import "HMDTTMonitor+AppLog.h"
#import "HMDTTMonitor+CodeCoverage.h"
#import "HMDTTMonitor+CustomTag.h"
#import "HMDTTMonitor+FrequenceDetect.h"
#import "HMDTTMonitor+Sample.h"
#import "HMDTTMonitor.h"
#import "HMDTTMonitorUserInfo.h"

FOUNDATION_EXPORT double HeimdallrVersionNumber;
FOUNDATION_EXPORT const unsigned char HeimdallrVersionString[];