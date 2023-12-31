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

#import "BDXBridgeGetStorageInfoMethod+BDXBridgeIMP.h"
#import "BDXBridgeGetStorageInfoMethod.h"
#import "BDXBridgeGetStorageItemMethod+BDXBridgeIMP.h"
#import "BDXBridgeGetStorageItemMethod.h"
#import "BDXBridgeRemoveStorageItemMethod+BDXBridgeIMP.h"
#import "BDXBridgeRemoveStorageItemMethod.h"
#import "BDXBridgeSetStorageItemMethod+BDXBridgeIMP.h"
#import "BDXBridgeSetStorageItemMethod.h"
#import "BDXBridgeStorageManager.h"

FOUNDATION_EXPORT double BDXBridgeKitVersionNumber;
FOUNDATION_EXPORT const unsigned char BDXBridgeKitVersionString[];