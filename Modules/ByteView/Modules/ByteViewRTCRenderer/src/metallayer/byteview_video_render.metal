//
//  byteview_video_render.metal
//  ByteViewRTCRenderer
//
//  Created by liujianlong on 2022/7/28.
//

#include <metal_stdlib>
#include "byteview_mtl_common.hpp"

using namespace metal;
using namespace byteview;

namespace byteview {

    struct OutputVertex {
        float4 pos [[position]];
        float2 tex_coord;
    };
}

vertex OutputVertex byteview_vertex_shader(constant InputVertex *data [[buffer(0)]],
                                           unsigned int index [[vertex_id]]) {
    OutputVertex ret;
    ret.pos = float4(data[index].coord, 0.0, 1.0);
    ret.tex_coord = data[index].tex_coord;
    return ret;
}

fragment float4 byteview_rgb_fragment_shader(OutputVertex input [[stage_in]],
                                             constant bool &isARGB[[buffer(0)]],
                                             texture2d<float, access::sample> texture [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 color = texture.sample(s, input.tex_coord);
    if (isARGB) {
        return float4(color.g, color.b, color.a, color.r);
    }
    return color;
}

fragment float4 byteview_fragment_shader(OutputVertex input [[stage_in]],
                                         constant ColorConversionParams &colorConversion [[buffer(0)]],
                                         texture2d<float, access::sample> texture_y [[texture(0)]],
                                         texture2d<float, access::sample> texture_cbcr [[texture(1)]] ) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float3 ycbcr = float3(texture_y.sample(s, input.tex_coord).r, texture_cbcr.sample(s, input.tex_coord).rg);
    float3 rgb = colorConversion.matrix * (ycbcr + colorConversion.offset);
    return float4(rgb, 1.0);
}
