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

#import "BDXLazyLoadProxy.h"
#import "BDXLynxKit.h"
#import "BDXLynxKitUtils.h"
#import "BDXLynxResourceProvider.h"
#import "BDXLynxView.h"

FOUNDATION_EXPORT double BDXLynxKitVersionNumber;
FOUNDATION_EXPORT const unsigned char BDXLynxKitVersionString[];
