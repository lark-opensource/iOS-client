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

#import "OKApplicationInfo.h"
#import "OKStartUpFunction.h"
#import "OKStartUpScheduler.h"
#import "OKStartUpSchemeHandler.h"
#import "OKStartUpTask.h"
#import "OneKitApp.h"

FOUNDATION_EXPORT double OneKitVersionNumber;
FOUNDATION_EXPORT const unsigned char OneKitVersionString[];