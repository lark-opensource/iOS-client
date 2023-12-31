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

#import "HMDTracker.h"
#import "HMDTrackerConfig.h"
#import "HMDTrackerRecord.h"
#import "Heimdallr+ExternalClean.h"
#import "Heimdallr+ManualControl.h"
#import "Heimdallr+ModuleCallback.h"
#import "Heimdallr+RoleStateChange.h"
#import "Heimdallr.h"
#import "HeimdallrLocalModule.h"
#import "HeimdallrModule.h"

FOUNDATION_EXPORT double HeimdallrVersionNumber;
FOUNDATION_EXPORT const unsigned char HeimdallrVersionString[];