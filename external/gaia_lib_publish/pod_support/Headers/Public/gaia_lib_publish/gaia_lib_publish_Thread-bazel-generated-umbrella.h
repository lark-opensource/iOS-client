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

#import "Gaia/Thread/AMGThreadFactory.h"
#import "Gaia/Thread/AMGThreadWrapper.h"

FOUNDATION_EXPORT double gaia_lib_publishVersionNumber;
FOUNDATION_EXPORT const unsigned char gaia_lib_publishVersionString[];