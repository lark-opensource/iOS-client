//
//  vcn_util_version.h
//  network-1
//
//  Created by thq on 17/2/19.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef vcn_util_version_h
#define vcn_util_version_h
#if !defined VCN_VERSION
#define VCN_VERSION    "ios5.1.1-net3" 
#endif
#define AV_NETWORK_VERSION VCN_VERSION

/* @file
* @ingroup lavu
* Libavutil version macros
*/


#include "macros.h"

/**
 * @addtogroup version_utils
 *
 * Useful to check and match library version in order to maintain
 * backward compatibility.
 *
 * The FFmpeg libraries follow a versioning sheme very similar to
 * Semantic Versioning (http://semver.org/)
 * The difference is that the component called PATCH is called MICRO in FFmpeg
 * and its value is reset to 100 instead of 0 to keep it above or equal to 100.
 * Also we do not increase MICRO for every bugfix or change in git master.
 *
 * Prior to FFmpeg 3.2 point releases did not change any lib version number to
 * avoid aliassing different git master checkouts.
 * Starting with FFmpeg 3.2, the released library versions will occupy
 * a separate MAJOR.MINOR that is not used on the master development branch.
 * That is if we branch a release of master 55.10.123 we will bump to 55.11.100
 * for the release and master will continue at 55.12.100 after it. Each new
 * point release will then bump the MICRO improving the usefulness of the lib
 * versions.
 *
#define AV_NETWORK_VERSION    "android_2.1.0_boringssl" 
 */

#define AV_VERSION_INT(a, b, c) ((a)<<16 | (b)<<8 | (c))
#define AV_VERSION_DOT(a, b, c) a ##.## b ##.## c
#define AV_VERSION(a, b, c) AV_VERSION_DOT(a, b, c)

/**
 * Extract version components from the full ::AV_VERSION_INT int as returned
 * by functions like ::avformat_version() and ::avcodec_version()
 */
#define AV_VERSION_MAJOR(a) ((a) >> 16)
#define AV_VERSION_MINOR(a) (((a) & 0x00FF00) >> 8)
#define AV_VERSION_MICRO(a) ((a) & 0xFF)

/**
 * @}
 */

/**
 * @defgroup lavu_ver Version and Build diagnostics
 *
 * Macros and function useful to check at compiletime and at runtime
 * which version of libavutil is in use.
 *
 * @{
 */

#define LIBAVUTIL_VERSION_MAJOR  55
#define LIBAVUTIL_VERSION_MINOR  34
#define LIBAVUTIL_VERSION_MICRO 101

#define LIBAVUTIL_VERSION_INT   AV_VERSION_INT(LIBAVUTIL_VERSION_MAJOR, \
LIBAVUTIL_VERSION_MINOR, \
LIBAVUTIL_VERSION_MICRO)
#define LIBAVUTIL_VERSION       AV_VERSION(LIBAVUTIL_VERSION_MAJOR,     \
LIBAVUTIL_VERSION_MINOR,     \
LIBAVUTIL_VERSION_MICRO)
#define LIBAVUTIL_BUILD         LIBAVUTIL_VERSION_INT

#define LIBAVUTIL_IDENT         "Lavu" AV_STRINGIFY(LIBAVUTIL_VERSION)

/**
 * @defgroup lavu_depr_guards Deprecation Guards
 * FF_API_* defines may be placed below to indicate public API that will be
 * dropped at a future version bump. The defines themselves are not part of
 * the public API and may change, break or disappear at any time.
 *
 * @note, when bumping the major version it is recommended to manually
 * disable each FF_API_* in its own commit instead of disabling them all
 * at once through the bump. This improves the git bisect-ability of the change.
 *
 * @{
 */

#ifndef FF_API_VDPAU
#define FF_API_VDPAU                    (LIBAVUTIL_VERSION_MAJOR < 56)
#endif
#ifndef FF_API_XVMC
#define FF_API_XVMC                     (LIBAVUTIL_VERSION_MAJOR < 56)
#endif
#ifndef FF_API_OPT_TYPE_METADATA
#define FF_API_OPT_TYPE_METADATA        (LIBAVUTIL_VERSION_MAJOR < 56)
#endif
#ifndef FF_API_DLOG
#define FF_API_DLOG                     (LIBAVUTIL_VERSION_MAJOR < 56)
#endif
#ifndef FF_API_VAAPI
#define FF_API_VAAPI                    (LIBAVUTIL_VERSION_MAJOR < 56)
#endif
#ifndef FF_API_FRAME_QP
#define FF_API_FRAME_QP                 (LIBAVUTIL_VERSION_MAJOR < 56)
#endif
#ifndef FF_API_PLUS1_MINUS1
#define FF_API_PLUS1_MINUS1             (LIBAVUTIL_VERSION_MAJOR < 56)
#endif
#ifndef FF_API_ERROR_FRAME
#define FF_API_ERROR_FRAME              (LIBAVUTIL_VERSION_MAJOR < 56)
#endif
#ifndef FF_API_CRC_BIG_TABLE
#define FF_API_CRC_BIG_TABLE            (LIBAVUTIL_VERSION_MAJOR < 56)
#endif
#ifndef FF_API_PKT_PTS
#define FF_API_PKT_PTS                  (LIBAVUTIL_VERSION_MAJOR < 56)
#endif


/**
 * @}
 * @}
 */



#endif /* vcn_util_version_h */
