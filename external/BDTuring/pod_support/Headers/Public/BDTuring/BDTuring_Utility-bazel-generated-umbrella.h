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

#import "BDTuringConfig.h"
#import "BDTuringDefine.h"
#import "BDTuringVerifyModel.h"
#import "BDTuringVerifyResult.h"

FOUNDATION_EXPORT double BDTuringVersionNumber;
FOUNDATION_EXPORT const unsigned char BDTuringVersionString[];