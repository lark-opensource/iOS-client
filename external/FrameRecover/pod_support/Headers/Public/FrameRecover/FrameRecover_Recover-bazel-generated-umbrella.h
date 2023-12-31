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

#import "FrameRecover.h"
#import "HMDFrameRecoverExceptionData.h"
#import "HMDFrameRecoverMachData.h"
#import "HMDFrameRecoverManager+Log.h"
#import "HMDFrameRecoverManager.h"
#import "HMDFrameRecoverPublicMacro.h"
#import "HMDFrameRecoverQuery.h"
#import "HMDMachRecoverDeclaration.h"
#import "HMDMachRestartableDeclaration.h"

FOUNDATION_EXPORT double FrameRecoverVersionNumber;
FOUNDATION_EXPORT const unsigned char FrameRecoverVersionString[];