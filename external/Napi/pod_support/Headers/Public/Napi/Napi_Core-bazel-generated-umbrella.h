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

#import "js_native_api.h"
#import "js_native_api_types.h"
#import "napi.h"
#import "napi_module.h"
#import "napi_state.h"

FOUNDATION_EXPORT double NapiVersionNumber;
FOUNDATION_EXPORT const unsigned char NapiVersionString[];