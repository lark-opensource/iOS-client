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

#import "BDDownloadURLSessionManager.h"
#import "BDDownloadURLSessionTask+Private.h"
#import "BDDownloadURLSessionTask.h"

FOUNDATION_EXPORT double BDWebImageVersionNumber;
FOUNDATION_EXPORT const unsigned char BDWebImageVersionString[];