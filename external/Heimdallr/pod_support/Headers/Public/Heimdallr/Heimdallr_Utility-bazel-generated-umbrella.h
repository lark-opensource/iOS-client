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

#import "HMDAppLaunchTool.h"
#import "HMDCPUUtilties.h"
#import "HMDFileTool.h"
#import "HMDISAHookOptimization.h"
#import "HMDJSONable.h"
#import "HMDMacroManager.h"
#import "HMDMemoryUsage.h"
#import "HMDPublicMacro.h"
#import "HMDUITrackerManagerSceneProtocol.h"
#import "HMDUITrackerTool.h"
#import "HeimdallrUtilities.h"
#import "NSArray+HMDTopN.h"
#import "NSDate+HMDAccurate.h"
#import "hmd_debug.h"

FOUNDATION_EXPORT double HeimdallrVersionNumber;
FOUNDATION_EXPORT const unsigned char HeimdallrVersionString[];