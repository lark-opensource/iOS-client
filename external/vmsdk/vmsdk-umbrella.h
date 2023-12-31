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

#import "MonitorInfo.h"
#import "VmsdkMonitor.h"
#import "iOS/js_worker_ios.h"
#import "js_native_api.h"
#import "js_native_api_types.h"
#import "napi_env.h"
#import "napi_env_jsc.h"
#import "napi_module.h"
#import "napi_runtime.h"
#import "napi_state.h"

FOUNDATION_EXPORT double vmsdkVersionNumber;
FOUNDATION_EXPORT const unsigned char vmsdkVersionString[];
