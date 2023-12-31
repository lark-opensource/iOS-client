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

#import "BDWebDefaultRequestDecorator.h"
#import "BDWebDefaultURLSchemaHandler.h"
#import "BDWebHTTPCachePolicy.h"
#import "BDWebInterceptor+Private.h"
#import "BDWebInterceptor.h"
#import "BDWebInterceptorPluginObject.h"
#import "BDWebRLMonitorHelper.h"
#import "BDWebRequestDecorator.h"
#import "BDWebRequestFilter.h"
#import "BDWebResourceMonitorEventType.h"
#import "BDWebURLProtocolTask.h"
#import "BDWebURLSchemeHandler.h"
#import "BDWebURLSchemeProtocolClass.h"
#import "BDWebURLSchemeTask.h"
#import "BDWebURLSchemeTaskHandler.h"
#import "BDWebURLSchemeTaskProxy.h"
#import "QNSURLSessionDemux.h"
#import "WKWebView+BDInterceptor.h"

FOUNDATION_EXPORT double BDWebKitVersionNumber;
FOUNDATION_EXPORT const unsigned char BDWebKitVersionString[];