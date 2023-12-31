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

#import "BDWebKitUtil+BlankDetect.h"
#import "BDWebViewBlankDetect.h"

FOUNDATION_EXPORT double BDWebKitVersionNumber;
FOUNDATION_EXPORT const unsigned char BDWebKitVersionString[];