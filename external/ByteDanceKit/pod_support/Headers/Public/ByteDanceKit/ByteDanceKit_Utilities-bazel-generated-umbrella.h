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

#import "BTDNetworkUtilities.h"
#import "BTDPingServices.h"
#import "BTDReachability.h"
#import "BTDSimplePing.h"
#import "BTDkeyChainStorage.h"

FOUNDATION_EXPORT double ByteDanceKitVersionNumber;
FOUNDATION_EXPORT const unsigned char ByteDanceKitVersionString[];