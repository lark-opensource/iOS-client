//
//  intfloat.h
//  network-1
//
//  Created by thq on 17/2/19.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef intfloat_h
#define intfloat_h

#include <stdint.h>
#include "attributes.h"

union av_intfloat32 {
    uint32_t i;
    float    f;
};

union av_intfloat64 {
    uint64_t i;
    double   f;
};

/**
 * Reinterpret a 32-bit integer as a float.
 */
static av_always_inline float av_int2float(uint32_t i)
{
    union av_intfloat32 v;
    v.i = i;
    return v.f;
}

/**
 * Reinterpret a float as a 32-bit integer.
 */
static av_always_inline uint32_t av_float2int(float f)
{
    union av_intfloat32 v;
    v.f = f;
    return v.i;
}

/**
 * Reinterpret a 64-bit integer as a double.
 */
static av_always_inline double av_int2double(uint64_t i)
{
    union av_intfloat64 v;
    v.i = i;
    return v.f;
}

/**
 * Reinterpret a double as a 64-bit integer.
 */
static av_always_inline uint64_t av_double2int(double f)
{
    union av_intfloat64 v;
    v.f = f;
    return v.i;
}

#endif /* intfloat_h */
