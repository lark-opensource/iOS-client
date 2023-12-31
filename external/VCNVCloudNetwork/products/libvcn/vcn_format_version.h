//
//  vcn_format_version.h
//  network-1
//
//  Created by thq on 17/2/19.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef vcn_format_version_h
#define vcn_format_version_h

#include "vcn_util_version.h"

// Major bumping may affect Ticket5467, 5421, 5451(compatibility with Chromium)
// Also please add any ticket numbers that you believe might be affected here
#define LIBAVFORMAT_VERSION_MAJOR  57
#define LIBAVFORMAT_VERSION_MINOR  56
#define LIBAVFORMAT_VERSION_MICRO 101

#define LIBAVFORMAT_VERSION_INT AV_VERSION_INT(LIBAVFORMAT_VERSION_MAJOR, \
LIBAVFORMAT_VERSION_MINOR, \
LIBAVFORMAT_VERSION_MICRO)
#define LIBAVFORMAT_VERSION     AV_VERSION(LIBAVFORMAT_VERSION_MAJOR,   \
LIBAVFORMAT_VERSION_MINOR,   \
LIBAVFORMAT_VERSION_MICRO)
#define LIBAVFORMAT_BUILD       LIBAVFORMAT_VERSION_INT

#define LIBAVFORMAT_IDENT       "Lavf" AV_STRINGIFY(LIBAVFORMAT_VERSION)

/**
 * FF_API_* defines may be placed below to indicate public API that will be
 * dropped at a future version bump. The defines themselves are not part of
 * the public API and may change, break or disappear at any time.
 *
 * @note, when bumping the major version it is recommended to manually
 * disable each FF_API_* in its own commit instead of disabling them all
 * at once through the bump. This improves the git bisect-ability of the change.
 *
 */
#ifndef FF_API_LAVF_BITEXACT
#define FF_API_LAVF_BITEXACT            (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif
#ifndef FF_API_LAVF_FRAC
#define FF_API_LAVF_FRAC                (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif
#ifndef FF_API_LAVF_CODEC_TB
#define FF_API_LAVF_CODEC_TB            (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif
#ifndef FF_API_URL_FEOF
#define FF_API_URL_FEOF                 (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif
#ifndef FF_API_LAVF_FMT_RAWPICTURE
#define FF_API_LAVF_FMT_RAWPICTURE      (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif
#ifndef FF_API_COMPUTE_PKT_FIELDS2
#define FF_API_COMPUTE_PKT_FIELDS2      (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif
#ifndef FF_API_OLD_OPEN_CALLBACKS
#define FF_API_OLD_OPEN_CALLBACKS       (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif
#ifndef FF_API_LAVF_AVCTX
#define FF_API_LAVF_AVCTX               (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif
#ifndef FF_API_NOCONST_GET_SIDE_DATA
#define FF_API_NOCONST_GET_SIDE_DATA    (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif
#ifndef FF_API_HTTP_USER_AGENT
#define FF_API_HTTP_USER_AGENT          (LIBAVFORMAT_VERSION_MAJOR < 58)
#endif

#ifndef FF_API_R_FRAME_RATE
#define FF_API_R_FRAME_RATE            1
#endif

#endif /* vcn_format_version_h */
