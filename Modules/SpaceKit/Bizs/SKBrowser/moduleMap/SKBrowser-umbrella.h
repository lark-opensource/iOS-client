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
#import "pngstruct.h"
#import "pnginfo.h"
#import "pnglibconf.h"
#import "pngpriv.h"

#import "DetectImageHelper.h"

FOUNDATION_EXPORT double PrivateLibPNGVersionNumber;
FOUNDATION_EXPORT const unsigned char PrivateLibPNGVersionString[];

