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

#import "BDXBridge+BulletXMethod.h"
#import "BulletXBridgeDefines.h"
#import "BulletXXBridgeAutoRegister.h"

FOUNDATION_EXPORT double BulletXVersionNumber;
FOUNDATION_EXPORT const unsigned char BulletXVersionString[];