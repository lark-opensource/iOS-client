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

#import "BDXService.h"
#import "BDXServiceCenter.h"
#import "BDXServiceDispatcher.h"
#import "BDXServiceManager+Register.h"
#import "BDXServiceManager.h"
#import "BDXServiceRegister.h"

FOUNDATION_EXPORT double BDXServiceCenterVersionNumber;
FOUNDATION_EXPORT const unsigned char BDXServiceCenterVersionString[];