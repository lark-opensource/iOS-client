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

#import "libswresample/config.h"
#import "libswresample/swresample.h"
#import "libswresample/version.h"

FOUNDATION_EXPORT double TTFFmpegVersionNumber;
FOUNDATION_EXPORT const unsigned char TTFFmpegVersionString[];