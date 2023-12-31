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

#import "BDDownloadManager+BDWebImage.h"
#import "BDDownloadManager+Private.h"
#import "BDDownloadManager.h"
#import "BDDownloadTask+Private.h"
#import "BDDownloadTask+WebImage.h"
#import "BDDownloadTask.h"
#import "BDDownloadTaskConfig.h"

FOUNDATION_EXPORT double BDWebImageVersionNumber;
FOUNDATION_EXPORT const unsigned char BDWebImageVersionString[];