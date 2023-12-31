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

#import "EAccountCTEConfig.h"
#import "EAccountJSEventHandler.h"
#import "EAccountPreLoginConfigModel.h"
#import "EAccountSDK.h"

FOUNDATION_EXPORT double EAccountApiSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char EAccountApiSDKVersionString[];
