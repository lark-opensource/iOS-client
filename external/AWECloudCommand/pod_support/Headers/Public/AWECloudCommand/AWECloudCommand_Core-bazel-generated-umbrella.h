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

FOUNDATION_EXPORT double AWECloudCommandVersionNumber;
FOUNDATION_EXPORT const unsigned char AWECloudCommandVersionString[];