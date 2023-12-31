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

#import "BDXBridgePublishEventMethod+BDXBridgeIMP.h"
#import "BDXBridgePublishEventMethod.h"
#import "BDXBridgeSubscribeEventMethod+BDXBridgeIMP.h"
#import "BDXBridgeSubscribeEventMethod.h"
#import "BDXBridgeUnsubscribeEventMethod+BDXBridgeIMP.h"
#import "BDXBridgeUnsubscribeEventMethod.h"

FOUNDATION_EXPORT double BDXBridgeKitVersionNumber;
FOUNDATION_EXPORT const unsigned char BDXBridgeKitVersionString[];