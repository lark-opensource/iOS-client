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

#import "libavfilter/avfilter.h"
#import "libavfilter/avfiltergraph.h"
#import "libavfilter/buffersink.h"
#import "libavfilter/buffersrc.h"
#import "libavfilter/config.h"
#import "libavfilter/version.h"

FOUNDATION_EXPORT double TTFFmpegVersionNumber;
FOUNDATION_EXPORT const unsigned char TTFFmpegVersionString[];