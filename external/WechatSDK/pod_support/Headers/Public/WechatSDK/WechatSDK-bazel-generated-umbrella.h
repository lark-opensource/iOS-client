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

#import "WXApi.h"
#import "WXApiObject.h"
#import "WechatAuthSDK.h"

FOUNDATION_EXPORT double WechatSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char WechatSDKVersionString[];