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

#import "BlockDeque.h"
#import "CountDownLatch.h"
#import "DownloadMutex.h"
#import "NLEModelDownloader.h"
#import "NLEModelDownloaderParams.h"
#import "NLEResourceDownloadCallback.h"
#import "NLEResourceListDownloadCallback.h"
#import "NLESingleResourceDownloadCallback.h"
#import "ResourceUtil.h"

FOUNDATION_EXPORT double NLEPlatformVersionNumber;
FOUNDATION_EXPORT const unsigned char NLEPlatformVersionString[];