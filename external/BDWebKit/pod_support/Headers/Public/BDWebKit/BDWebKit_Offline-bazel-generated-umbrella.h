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

#import "BDPreloadCachedResponse+Falcon.h"
#import "BDWebOfflinePlugin.h"
#import "BDWebViewOfflineManager.h"
#import "BDWebViewOfflineStatusLogicControl.h"
#import "WKUserContentController+BDWebViewHookJS.h"
#import "WKWebView+BDOffline.h"

FOUNDATION_EXPORT double BDWebKitVersionNumber;
FOUNDATION_EXPORT const unsigned char BDWebKitVersionString[];