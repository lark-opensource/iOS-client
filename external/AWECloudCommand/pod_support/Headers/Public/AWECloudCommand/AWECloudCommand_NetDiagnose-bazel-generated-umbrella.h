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

#import "AWECloudCommandNetDiagnoseAddressInfo.h"
#import "AWECloudCommandNetDiagnoseConnect.h"
#import "AWECloudCommandNetDiagnoseDownSpeed.h"
#import "AWECloudCommandNetDiagnoseManager.h"
#import "AWECloudCommandNetDiagnoseRoute.h"
#import "AWECloudCommandNetDiagnoseSimplePing.h"
#import "AWECloudCommandNetDiagnoseTraceRoute.h"
#import "AWECloudCommandNetDiagnoseUpSpeed.h"

FOUNDATION_EXPORT double AWECloudCommandVersionNumber;
FOUNDATION_EXPORT const unsigned char AWECloudCommandVersionString[];