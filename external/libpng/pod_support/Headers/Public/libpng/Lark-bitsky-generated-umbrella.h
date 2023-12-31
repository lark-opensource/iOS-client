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

#import "png.h"
#import "pngconf.h"
#import "pngdebug.h"
#import "pnglibconf.h"
#import "pngstruct.h"

FOUNDATION_EXPORT double libpngVersionNumber;
FOUNDATION_EXPORT const unsigned char libpngVersionString[];
