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

#import "bvcparser.h"
#import "get_bits.h"
#import "golomb.h"

FOUNDATION_EXPORT double BVCParserVersionNumber;
FOUNDATION_EXPORT const unsigned char BVCParserVersionString[];
