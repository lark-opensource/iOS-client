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

#import "AMapFoundationConst.h"
#import "AMapFoundationKit.h"
#import "AMapFoundationVersion.h"
#import "AMapServices.h"
#import "AMapURLSearch.h"
#import "AMapURLSearchConfig.h"
#import "AMapURLSearchType.h"
#import "AMapUtility.h"

FOUNDATION_EXPORT double AMapFoundation_NO_IDFAVersionNumber;
FOUNDATION_EXPORT const unsigned char AMapFoundation_NO_IDFAVersionString[];