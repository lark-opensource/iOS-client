//
//  ByteViewColroConversionParams.h
//  ByteViewRTCRenderer
//
//  Created by liujianlong on 2022/7/28.
//

#ifndef BYTEVIEW_MTL_COMMON_HPP
#define BYTEVIEW_MTL_COMMON_HPP

#include <simd/simd.h>

namespace byteview {

struct InputVertex {
    simd::float2 coord;
    simd::float2 tex_coord;
};

struct ColorConversionParams {
    simd::float3x3 matrix;
    simd::float3 offset;
};

}

#endif /* ByteViewColroConversionParams_h */
