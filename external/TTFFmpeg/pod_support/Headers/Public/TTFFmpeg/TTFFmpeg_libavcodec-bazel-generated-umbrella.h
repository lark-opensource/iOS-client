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

#import "libavcodec/arm/mathops.h"
#import "libavcodec/avcodec.h"
#import "libavcodec/avdct.h"
#import "libavcodec/avfft.h"
#import "libavcodec/bsf.h"
#import "libavcodec/bytestream.h"
#import "libavcodec/config.h"
#import "libavcodec/d3d11va.h"
#import "libavcodec/dirac.h"
#import "libavcodec/dv_profile.h"
#import "libavcodec/dxva2.h"
#import "libavcodec/get_bits.h"
#import "libavcodec/golomb.h"
#import "libavcodec/internal.h"
#import "libavcodec/jni.h"
#import "libavcodec/mathops.h"
#import "libavcodec/mediacodec.h"
#import "libavcodec/parser.h"
#import "libavcodec/put_bits.h"
#import "libavcodec/qsv.h"
#import "libavcodec/thread.h"
#import "libavcodec/ttexport.h"
#import "libavcodec/vaapi.h"
#import "libavcodec/vda.h"
#import "libavcodec/vda_vt_internal.h"
#import "libavcodec/vdpau.h"
#import "libavcodec/version.h"
#import "libavcodec/videotoolbox.h"
#import "libavcodec/vlc.h"
#import "libavcodec/vorbis_parser.h"
#import "libavcodec/x86/mathops.h"
#import "libavcodec/xvmc.h"

FOUNDATION_EXPORT double TTFFmpegVersionNumber;
FOUNDATION_EXPORT const unsigned char TTFFmpegVersionString[];