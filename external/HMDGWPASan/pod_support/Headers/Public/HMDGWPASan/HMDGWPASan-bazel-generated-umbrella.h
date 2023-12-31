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

#import "HMDGWPASanManager.h"
#import "HMDGWPASanPublicMacro.h"
#import "HMDGWPAsanDetection.h"
#import "HMDGWPAsanOption.h"
#import "HMDGWPAsanPublicDefine.h"

FOUNDATION_EXPORT double HMDGWPASanVersionNumber;
FOUNDATION_EXPORT const unsigned char HMDGWPASanVersionString[];