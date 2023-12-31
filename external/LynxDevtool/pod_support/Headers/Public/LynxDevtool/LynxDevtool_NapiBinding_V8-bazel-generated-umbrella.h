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

#import "jsbridge/napi/napi_runtime_proxy_v8.h"
#import "jsbridge/napi/shim/shim_napi_env_v8.h"

FOUNDATION_EXPORT double LynxDevtoolVersionNumber;
FOUNDATION_EXPORT const unsigned char LynxDevtoolVersionString[];