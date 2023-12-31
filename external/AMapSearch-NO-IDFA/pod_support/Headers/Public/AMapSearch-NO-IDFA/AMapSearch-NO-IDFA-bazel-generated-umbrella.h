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

#import "AMapCommonObj.h"
#import "AMapNearbySearchManager.h"
#import "AMapNearbyUploadInfo.h"
#import "AMapSearchAPI.h"
#import "AMapSearchError.h"
#import "AMapSearchKit.h"
#import "AMapSearchObj.h"
#import "AMapSearchVersion.h"

FOUNDATION_EXPORT double AMapSearch_NO_IDFAVersionNumber;
FOUNDATION_EXPORT const unsigned char AMapSearch_NO_IDFAVersionString[];