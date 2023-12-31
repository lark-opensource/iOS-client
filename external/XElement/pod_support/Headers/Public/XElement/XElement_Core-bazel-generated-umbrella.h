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

#import "BDXElementAdapter.h"
#import "BDXElementLivePlayerDelegate.h"
#import "BDXElementMonitorDelegate.h"
#import "BDXElementNetworkDelegate.h"
#import "BDXElementReportDelegate.h"
#import "BDXElementResourceManager.h"
#import "BDXElementToastDelegate.h"
#import "BDXElementVolumeDelegate.h"
#import "BDXHybridUI.h"
#import "LynxUI+BDXLynx.h"
#import "UIView+BDXElementNativeView.h"

FOUNDATION_EXPORT double XElementVersionNumber;
FOUNDATION_EXPORT const unsigned char XElementVersionString[];