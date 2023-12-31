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

#import "LensCWrapper.h"
#import "LensConfigType.h"
#import "LensEngine.h"
#import "LensEngineExt.h"

FOUNDATION_EXPORT double lensVersionNumber;
FOUNDATION_EXPORT const unsigned char lensVersionString[];