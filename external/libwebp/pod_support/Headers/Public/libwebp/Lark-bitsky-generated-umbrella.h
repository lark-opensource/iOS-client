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

#import "demux.h"
#import "mux.h"
#import "sharpyuv.h"
#import "decode.h"
#import "encode.h"
#import "format_constants.h"
#import "mux_types.h"
#import "types.h"

FOUNDATION_EXPORT double libwebpVersionNumber;
FOUNDATION_EXPORT const unsigned char libwebpVersionString[];
