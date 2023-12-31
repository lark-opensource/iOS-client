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

#import "BDWebKitDefine.h"
#import "BDWebKitMainFrameModel.h"
#import "BDWebKitSettingsManger.h"
#import "BDWebKitUtil.h"
#import "BDWebKitVersion.h"
#import "BDWebViewDebugKit.h"
#import "BDWebViewUAManager.h"
#import "NSObject+BDWRuntime.h"
#import "WKUserContentController+BDWHelper.h"
#import "WKWebView+BDPrivate.h"

FOUNDATION_EXPORT double BDWebKitVersionNumber;
FOUNDATION_EXPORT const unsigned char BDWebKitVersionString[];