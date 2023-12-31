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

#import "HMDCrashAppGroupURL.h"
#import "HMDCrashCallback.h"
#import "HMDCrashDetect.h"
#import "HMDCrashDirectory.h"
#import "HMDCrashDynamicSavedFiles.h"
#import "HMDCrashExtraDynamicData.h"
#import "HMDCrashGameScriptStack.h"
#import "HMDCrashKit.h"
#import "HMDCrashKitSwitch.h"
#import "HMDCrashLoadLaunch.h"
#import "HMDCrashLoadOption+Definition.h"
#import "HMDCrashLoadOption.h"
#import "HMDCrashLoadReport.h"

FOUNDATION_EXPORT double HeimdallrVersionNumber;
FOUNDATION_EXPORT const unsigned char HeimdallrVersionString[];