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

#import "NSData+DataDecorator.h"
#import "app_log_aes_e.h"

FOUNDATION_EXPORT double BDDataDecoratorVersionNumber;
FOUNDATION_EXPORT const unsigned char BDDataDecoratorVersionString[];