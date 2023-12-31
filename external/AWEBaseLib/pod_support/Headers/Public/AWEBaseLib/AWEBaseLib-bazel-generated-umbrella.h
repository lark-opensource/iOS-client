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

#import "AWEDTAdapter.h"
#import "AWEMacros.h"
#import "AWESafeAssertMacro.h"
#import "AWESingletonMacros.h"
#import "AWESwiftierOCMacros.h"
#import "UIDevice+AWEAdditions.h"

FOUNDATION_EXPORT double AWEBaseLibVersionNumber;
FOUNDATION_EXPORT const unsigned char AWEBaseLibVersionString[];