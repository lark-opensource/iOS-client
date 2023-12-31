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

#import "NSData+TSASignature.h"
#import "NSDate+TSASignature.h"
#import "NSString+TSASignature.h"
#import "TTTopSignature.h"

FOUNDATION_EXPORT double TTTopSignatureVersionNumber;
FOUNDATION_EXPORT const unsigned char TTTopSignatureVersionString[];