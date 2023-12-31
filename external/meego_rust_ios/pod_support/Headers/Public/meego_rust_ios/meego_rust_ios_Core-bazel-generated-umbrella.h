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

#import "meego_rust_ffi.h"

FOUNDATION_EXPORT double meego_rust_iosVersionNumber;
FOUNDATION_EXPORT const unsigned char meego_rust_iosVersionString[];