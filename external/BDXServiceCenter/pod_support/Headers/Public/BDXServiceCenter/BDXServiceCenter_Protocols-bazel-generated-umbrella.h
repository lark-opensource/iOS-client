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

#import "BDXContainerProtocol.h"
#import "BDXKitProtocol.h"
#import "BDXLynxKitProtocol.h"
#import "BDXMonitorProtocol.h"
#import "BDXOptimizeProtocol.h"
#import "BDXPageContainerProtocol.h"
#import "BDXPopupContainerProtocol.h"
#import "BDXResourceLoaderProtocol.h"
#import "BDXRouterProtocol.h"
#import "BDXSchemaProtocol.h"
#import "BDXServiceProtocol.h"
#import "BDXViewContainerProtocol.h"
#import "BDXWebKitProtocol.h"

FOUNDATION_EXPORT double BDXServiceCenterVersionNumber;
FOUNDATION_EXPORT const unsigned char BDXServiceCenterVersionString[];