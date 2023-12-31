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

#import "DYOpenAppDelegateInternalBridge.h"
#import "DYOpenInternalConstants.h"
#import "DYOpenNetworkManager.h"
#import "DYOpenSettingsInternalBridge.h"
#import "DYOpenTrackerInternalBridge.h"
#import "DouyinOpenSDKApplicationDelegate.h"
#import "DouyinOpenSDKConstants.h"
#import "DouyinOpenSDKErrorCode.h"
#import "DouyinOpenSDKObjects.h"
#import "NSBundle+DYOpen.h"
#import "UIImage+DYOpen.h"

FOUNDATION_EXPORT double DouyinOpenPlatformSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char DouyinOpenPlatformSDKVersionString[];