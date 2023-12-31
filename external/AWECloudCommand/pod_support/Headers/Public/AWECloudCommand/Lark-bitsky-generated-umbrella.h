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

#import "AWECloudCommandCache.h"
#import "AWECloudCommandCustom.h"
#import "AWECloudCommandMacros.h"
#import "AWECloudCommandManager.h"
#import "AWECloudCommandModel.h"
#import "AWECloudCommandNetwork.h"
#import "AWECloudCommandStat.h"
#import "AWECloudCommandUpload.h"
#import "AWECloudCommandNetDiagnoseAddressInfo.h"
#import "AWECloudCommandNetDiagnoseConnect.h"
#import "AWECloudCommandNetDiagnoseDownSpeed.h"
#import "AWECloudCommandNetDiagnoseManager.h"
#import "AWECloudCommandNetDiagnoseRoute.h"
#import "AWECloudCommandNetDiagnoseSimplePing.h"
#import "AWECloudCommandNetDiagnoseTraceRoute.h"
#import "AWECloudCommandNetDiagnoseUpSpeed.h"
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
