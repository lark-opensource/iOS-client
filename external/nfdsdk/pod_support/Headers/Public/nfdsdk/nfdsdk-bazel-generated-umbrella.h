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

#import "NFDKit+Scan.h"
#import "NFDKit.h"
#import "nfd_enum_code_gen.h"

FOUNDATION_EXPORT double nfdsdkVersionNumber;
FOUNDATION_EXPORT const unsigned char nfdsdkVersionString[];