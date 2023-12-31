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

#import "libavformat/avc.h"
#import "libavformat/avformat.h"
#import "libavformat/avio.h"
#import "libavformat/avio_internal.h"
#import "libavformat/config.h"
#import "libavformat/dash.h"
#import "libavformat/dv.h"
#import "libavformat/internal.h"
#import "libavformat/isom.h"
#import "libavformat/network.h"
#import "libavformat/os_support.h"
#import "libavformat/sample_aes.h"
#import "libavformat/ttexport.h"
#import "libavformat/url.h"
#import "libavformat/version.h"

FOUNDATION_EXPORT double TTFFmpegVersionNumber;
FOUNDATION_EXPORT const unsigned char TTFFmpegVersionString[];