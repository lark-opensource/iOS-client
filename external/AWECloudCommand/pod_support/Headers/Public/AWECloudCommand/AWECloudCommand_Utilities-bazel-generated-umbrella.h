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

#import "AWECloudBackgroundTaskUtility.h"
#import "AWECloudCPUUtility.h"
#import "AWECloudCommandMultiData.h"
#import "AWECloudCommandNetworkHandler.h"
#import "AWECloudCommandNetworkUtility.h"
#import "AWECloudCommandReachability.h"
#import "AWECloudControlDecode.h"
#import "AWECloudDiskUtility.h"
#import "AWECloudHardWireUtility.h"
#import "AWECloudMemoryUtility.h"
#import "NSData+AES.h"
#import "NSDictionary+AWECloudCommandUtil.h"
#import "NSString+AWECloudCommandUtil.h"

FOUNDATION_EXPORT double AWECloudCommandVersionNumber;
FOUNDATION_EXPORT const unsigned char AWECloudCommandVersionString[];