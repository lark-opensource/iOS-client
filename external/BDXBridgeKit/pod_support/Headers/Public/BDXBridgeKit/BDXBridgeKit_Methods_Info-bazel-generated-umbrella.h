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

#import "BDXBridgeGetAppInfoMethod+BDXBridgeIMP.h"
#import "BDXBridgeGetAppInfoMethod.h"
#import "BDXBridgeGetSettingsMethod+BDXBridgeIMP.h"
#import "BDXBridgeGetSettingsMethod.h"

FOUNDATION_EXPORT double BDXBridgeKitVersionNumber;
FOUNDATION_EXPORT const unsigned char BDXBridgeKitVersionString[];