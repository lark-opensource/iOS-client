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

#import "Godzippa.h"
#import "GodzippaDefines.h"
#import "NSData+Godzippa.h"
#import "NSFileManager+Godzippa.h"

FOUNDATION_EXPORT double GodzippaVersionNumber;
FOUNDATION_EXPORT const unsigned char GodzippaVersionString[];
