//
//  vcn_avutil.h
//  network-1
//
//  Created by thq on 17/2/19.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef vcn_avutil_h
#define vcn_avutil_h

/**
 * @brief Undefined timestamp value
 *
 * Usually reported by demuxer that work on containers that do not provide
 * either pts or dts.
 */

#define AV_NOPTS_VALUE          ((int64_t)UINT64_C(0x8000000000000000))
#define FF_LAMBDA_SHIFT 7
#define FF_LAMBDA_SCALE (1<<FF_LAMBDA_SHIFT)
#define FF_QP2LAMBDA 118 ///< factor to convert from H.263 QP to lambda
#define FF_LAMBDA_MAX (256*128-1)

/**
 * Internal time base represented as integer
 */
#define AV_TIME_BASE            1000000

#endif /* vcn_avutil_h */
