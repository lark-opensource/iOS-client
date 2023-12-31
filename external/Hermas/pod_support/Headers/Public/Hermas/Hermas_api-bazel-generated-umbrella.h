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

#import "HMConfig.h"
#import "HMEngine.h"
#import "HMInstance.h"
#import "Hermas.h"

FOUNDATION_EXPORT double HermasVersionNumber;
FOUNDATION_EXPORT const unsigned char HermasVersionString[];