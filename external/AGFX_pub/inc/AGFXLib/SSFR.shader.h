//
//  SSFR.shader.h
//  Pods
//
//  Created by lixiaoqi on 2020/4/22.
//
#if 0

#ifndef SSFR_shader_h
#define SSFR_shader_h
static const char* get_depth_vs_metal = R"(
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
struct VertexInput
{
    float4 aVertex [[attribute(0)]];
};
struct VertexOutput
{
    float4 viewPos;
    float4 projPos;
    float4 gl_Position [[position]];
    float pointsize[[point_size]];
};
struct VertexContext
{
    thread VertexInput& in;
    thread VertexOutput& out;
    constant float4x4& projMatrix;
    constant float4x4& viewMatrix;

    constant float& s_h;
    constant float& p_t;
    constant float& p_n;
    constant float& r;
    
    void main()
    {
        float4 pos;
        pos.x = in.aVertex.x / 2.0;
        pos.y = in.aVertex.z / 2.0 - 1.0;
        pos.z = in.aVertex.y / 2.0;
        pos.w = 1.0;
        out.viewPos = viewMatrix * pos;
        float dist = length(out.viewPos.xyz);
        out.gl_Position = projMatrix * out.viewPos;
        out.projPos = out.gl_Position;
        out.pointsize = r*p_n*s_h / (-out.viewPos.z * p_t);
    }
};
vertex VertexOutput vertexShader(VertexInput in [[stage_in]],
                                constant float4x4& projMatrix [[buffer(0)]],
                                constant float4x4& viewMatrix [[buffer(1)]],
                                constant float& s_h [[buffer(2)]],
                                constant float& p_t [[buffer(3)]],
                                constant float& p_n [[buffer(4)]],
                                constant float& r [[buffer(5)]],
                                constant float& p_f [[buffer(6)]]
                                )
{
    VertexOutput out;
    VertexContext
    {
        .in = in,
        .out = out,
        .projMatrix = projMatrix,
        .viewMatrix = viewMatrix,
        .s_h = s_h,
        .p_t = p_t,
        .p_n = p_n,
        .r = r,
    }.main();
    return out;
}
)";

// color order is BGRA
static const char* get_depth_fs_metal = R"(
#include <metal_stdlib>
using namespace metal;

struct FragmentInput
{
    float4 viewPos;
    float4 projPos;
};
struct FragmentOutput
{
    float4 FragColor [[color(0)]]; // TODO the target attached is single channel, float texture
    float depth_out [[depth(any)]];
};

float linearize(float d, float p_f, float p_n) {
    float f = p_f, n = p_n;
    return 2 * f * n / (d * (f - n) - (f + n));
}

// [[early_fragment_tests]]
fragment FragmentOutput fragmentShader(
                                        FragmentInput in [[stage_in]],
                                        float4 pix_pos [[position]],
                                        float2 gl_PointCoord [[point_coord]],
                                        constant float4x4& projMatrix [[buffer(0)]],
                                        constant float4x4& viewMatrix [[buffer(1)]],
                                        constant float& s_h [[buffer(2)]],
                                        constant float& p_t [[buffer(3)]],
                                        constant float& p_n [[buffer(4)]],
                                        constant float& r [[buffer(5)]],
                                        constant float& p_f [[buffer(6)]]
                                       )
{
    
    FragmentOutput out;

    float x = 2 * gl_PointCoord.x - 1;
    float y = 2 * gl_PointCoord.y - 1;
    float pho = x * x + y * y;
    float z = sqrt(1 - pho);
    if (pho > 1.0) {
        out.FragColor = float4(0.0, 0.0, 0.0, 1.0);
        out.depth_out = 1.0f;
        return out;
    }
    float4 nviewPos = float4(in.viewPos.xyz + float3(x, y, z) * r, 1);
    float4 nclipPos = projMatrix * nviewPos;
    float nz_ndc = nclipPos.z / nclipPos.w;
    out.depth_out = 0.5 * (1.0 * nz_ndc + 1.0 + 0.0); //gl_DepthRange
    out.FragColor.r = -nviewPos.z;
    out.FragColor.g = 1.0;
    //out.FragColor.r = 0.5;
    return out;
}

)";

// same as getDepth
static const char* get_thick_vs_metal = R"(
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
struct VertexInput
{
    float4 aVertex [[attribute(0)]];
};
struct VertexOutput
{
    float4 viewPos;
    float4 projPos;
    float4 gl_Position [[position]];
    float pointsize[[point_size]];
};
vertex VertexOutput vertexShader(VertexInput in [[stage_in]],
                                constant float4x4& projMatrix [[buffer(0)]],
                                constant float4x4& viewMatrix [[buffer(1)]],
                                constant float& s_h [[buffer(2)]],
                                constant float& p_t [[buffer(3)]],
                                constant float& p_n [[buffer(4)]],
                                constant float& r [[buffer(5)]],
                                constant float& p_f [[buffer(6)]]
                                )
{
    VertexOutput out;
    float4 pos;
    pos.x = in.aVertex.x / 2.0;
    pos.y = in.aVertex.z / 2.0 - 1.0;
    pos.z = in.aVertex.y / 2.0;
    pos.w = 1.0;
    out.viewPos = viewMatrix * pos;
    float dist = length(out.viewPos.xyz);
    out.gl_Position = projMatrix * out.viewPos;
    out.projPos = out.gl_Position;
    out.pointsize = r*p_n*s_h / (-out.viewPos.z * p_t);
    return out;
}
)";

// color order is BGRA
static const char* get_thick_fs_metal = R"(
#include <metal_stdlib>
using namespace metal;

struct FragmentInput
{
    float4 viewPos;
    float4 projPos;
};
struct FragmentOutput
{
    float4 FragColor [[color(0)]];
};

// [[early_fragment_tests]]
fragment FragmentOutput fragmentShader(
                                        FragmentInput in [[stage_in]],
                                        float4 pix_pos [[position]],
                                        float2 gl_PointCoord [[point_coord]],
                                        constant float4x4& projMatrix [[buffer(0)]],
                                        constant float4x4& viewMatrix [[buffer(1)]],
                                        constant float& s_h [[buffer(2)]],
                                        constant float& p_t [[buffer(3)]],
                                        constant float& p_n [[buffer(4)]],
                                        constant float& r [[buffer(5)]],
                                        constant float& p_f [[buffer(6)]]
                                       )
{
    
    FragmentOutput out;

    float x = 2 * gl_PointCoord.x - 1;
    float y = 2 * gl_PointCoord.y - 1;
    float pho = x * x + y * y;
    float z = sqrt(1 - pho);
    if (pho > 1.0) {
        out.FragColor = float4(0.0);
        return out;
    }
    float3 lightDir = float3(0, 0, 1);
    out.FragColor.r = 2.0 * r*dot(float3(x, y, z), lightDir);
    //out.FragColor.r = out.FragColor.r * 0.5;
    return out;
}

)";

static const char* smooth_depth_vs_metal = R"(
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
struct VertexInput
{
    float4 aVertex [[attribute(0)]];
};
struct VertexOutput
{
    float2 vTex;
    float4 gl_Position [[position]];
    		
    float2 blurCoordinates0;	
    float2 blurCoordinates1;	
    float2 blurCoordinates2;	
    float2 blurCoordinates3;	
    float2 blurCoordinates4;	
    float2 blurCoordinates5;	
    float2 blurCoordinates6;	
    float2 blurCoordinates7;	
    float2 blurCoordinates8;	
    float2 blurCoordinates9;	
    float2 blurCoordinates10;
};
struct VertexContext	
{	
    thread VertexInput& in;	
    thread VertexOutput& out;	
    constant float& texelWidthOffset;	
    constant float& texelHeightOffset;	
    	
    void main()	
    {	
        (out.vTex = ((in.aVertex.xy * 0.5) + 0.5));	
        out.gl_Position = in.aVertex;	
        out.gl_Position.z = 0.0;	
        out.gl_Position.w = 1.0;	
        float2 singleStepOffset;	
        singleStepOffset.x = texelWidthOffset;	
        singleStepOffset.y = texelHeightOffset;	
        out.blurCoordinates0 = out.vTex;	
        out.blurCoordinates1 = singleStepOffset * 1.0;	
        out.blurCoordinates2 = out.vTex + singleStepOffset * 1.0;	
        out.blurCoordinates3 = out.vTex - singleStepOffset * 2.0;	
        out.blurCoordinates4 = out.vTex + singleStepOffset * 2.0;	
        out.blurCoordinates5 = out.vTex - singleStepOffset * 3.0;	
        out.blurCoordinates6 = out.vTex + singleStepOffset * 3.0;	
        out.blurCoordinates7 = out.vTex - singleStepOffset * 4.0;	
        out.blurCoordinates8 = out.vTex + singleStepOffset * 4.0;	
        out.blurCoordinates9 = out.vTex - singleStepOffset * 5.0;	
        out.blurCoordinates10 = out.vTex + singleStepOffset * 5.0;	
    }	
};
vertex VertexOutput vertexShader(VertexInput in [[stage_in]],	
                                constant float& p_n [[buffer(0)]],	
                                constant float& p_f [[buffer(1)]],	
                                constant float& d_w [[buffer(2)]],	
                                constant float& d_h [[buffer(3)]],	
                                constant int& kernel_r [[buffer(4)]],	
                                constant float& blur_r [[buffer(5)]],	
                                constant float& blur_z [[buffer(6)]],	
                                constant int& blur_option [[buffer(7)]],	
                                constant float& texelWidthOffset [[buffer(8)]],	
                                constant float& texelHeightOffset [[buffer(9)]]	
                                )	
{	
    VertexOutput out;	
    VertexContext	
    {	
        .in = in,	
        .out = out,	
        .texelWidthOffset = texelWidthOffset,	
        .texelHeightOffset = texelHeightOffset,	
    }.main();	
    return out;	
}
)";

// color order is BGRA
static const char* smooth_depth_fs_metal = R"(
#include <metal_stdlib>
using namespace metal;

template<typename T>
struct TSampler2D
{
    thread texture2d<T>& _texture2d;
    thread sampler& _sampler;
};
typedef TSampler2D<float> sampler2D;

template <typename T>
vec<T,4> texture(thread TSampler2D<T>& sampler2d, float2 texcoord)
{
    return sampler2d._texture2d.sample(sampler2d._sampler, texcoord);
}

struct FragmentInput
{
    float2 vTex;
    float2 blurCoordinates0;	
    float2 blurCoordinates1;	
    float2 blurCoordinates2;	
    float2 blurCoordinates3;	
    float2 blurCoordinates4;	
    float2 blurCoordinates5;	
    float2 blurCoordinates6;	
    float2 blurCoordinates7;	
    float2 blurCoordinates8;	
    float2 blurCoordinates9;	
    float2 blurCoordinates10;
};
struct FragmentOutput
{
    float4 FragColor [[color(0)]];
};


[[early_fragment_tests]]
fragment FragmentOutput fragmentShader(
                                        FragmentInput in [[stage_in]],
                                        texture2d<float> zTex [[ texture(0) ]],
                                        constant float& p_n [[buffer(0)]],
                                        constant float& p_f [[buffer(1)]],
                                        constant float& d_w [[buffer(2)]],
                                        constant float& d_h [[buffer(3)]],
                                        constant int& kernel_r [[buffer(4)]],
                                        constant float& blur_r [[buffer(5)]],
                                        constant float& blur_z [[buffer(6)]],
	                                    constant int& blur_option [[buffer(7)]],	
                                        constant float& texelWidthOffset [[buffer(8)]],	
                                        constant float& texelHeightOffset [[buffer(9)]]
                                        )
{
    sampler textureSampler0 (mag_filter::nearest,
                                  min_filter::nearest);
    sampler2D _zTex{ zTex, textureSampler0 };

    FragmentOutput out;
    // x: sum of weighted intensity. y: sum of weights
    float2 sum = float2(0.0, 0.0);	
    // r channel: sum of weighted intensity.  g channel : sum of weights
    float2 value;	
    // the intensity of the non-offset pixel
    float2 value0;	
    // is the pixel out of the fluid region?
    float flag = 1.0;	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates0).xy;	
    value0 = value;	
    // filter out the pixels whose initial intensity is 0
    if (value.y == 0.0 && blur_option % 2 == 0) {	
        out.FragColor.r = 0.0;	
        out.FragColor.g = 0.0;	
        return out;	
    }	
    if (value.y < 0.01 || value.x / value.y < 0.5) {	
        flag = -1.0;	
    }	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 1.0;	
        sum.y += abs(value.y) * 1.0 * flag;	
    }	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates1).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.972604;	
        sum.y += abs(value.y) * 0.972604 * flag;	
    }	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates2).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.972604;	
        sum.y += abs(value.y) * 0.972604 * flag;	
    }	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates3).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.894839;	
        sum.y += abs(value.y) * 0.894839 * flag;	
    }
     value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates4).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.894839;	
        sum.y += abs(value.y) * 0.894839 * flag;	
    }	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates5).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.778801;	
        sum.y += abs(value.y) * 0.778801 * flag;	
    }	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates6).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.778801;	
        sum.y += abs(value.y) * 0.778801 * flag;	
    }	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates7).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.64118;	
        sum.y += abs(value.y) * 0.64118 * flag;	
    }	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates8).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.64118;	
        sum.y += abs(value.y) * 0.64118 * flag;	
    }	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates9).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.249352;	
        sum.y += abs(value.y) * 0.249352 * flag;	
    }	
    value = _zTex._texture2d.sample(_zTex._sampler, in.blurCoordinates10).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.249352;	
        sum.y += abs(value.y) * 0.249352 * flag;	
    }	

    // in the last step, we save the normalized result in the r channel
    if (blur_option == 4) {
        if (sum.y < 0.01) {	
            out.FragColor.r = 0.0;	
            out.FragColor.g = 0.0;	
        }	
        else {	
            out.FragColor.r = max(sum.x / sum.y, 0.0);	
            out.FragColor.g = sum.y;
        }	
    }	
    else {	
        if (sum.y < 0.01 && blur_option % 2 == 0) {	
            out.FragColor.r = 0.0;	
            out.FragColor.g = 0.0;	
        }	
        else {	
            out.FragColor.r = sum.x;	
            out.FragColor.g = sum.y;	
        }	
    }
    return out;
}

)";

static const char* restore_normal_vs_metal = R"(
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
struct VertexInput
{
    float4 aVertex [[attribute(0)]];
};
struct VertexOutput
{
    float2 vTex;
    float4 gl_Position [[position]];
};
vertex VertexOutput vertexShader(VertexInput in [[stage_in]])
{
    VertexOutput out;
    (out.vTex = ((in.aVertex.xy * 0.5) + 0.5));
    out.vTex.y = 1.0 - out.vTex.y;
    out.gl_Position = in.aVertex;
    out.gl_Position.z = 0.0;
    out.gl_Position.w = 1.0;
    return out;
}
)";

// color order is BGRA
static const char* restore_normal_fs_metal = R"(
#include <metal_stdlib>
using namespace metal;

template<typename T>
struct TSampler2D
{
    thread texture2d<T>& _texture2d;
    thread sampler& _sampler;
};
typedef TSampler2D<float> sampler2D;

template <typename T>
vec<T,4> texture(thread TSampler2D<T>& sampler2d, float2 texcoord)
{
    return sampler2d._texture2d.sample(sampler2d._sampler, texcoord);
}

struct FragmentInput
{
    float2 vTex;
};
struct FragmentOutput
{
    float4 FragColor [[color(0)]];
};

[[early_fragment_tests]]
fragment FragmentOutput fragmentShader(
                                        FragmentInput in [[stage_in]],
                                        texture2d<float> zTex [[ texture(0) ]],
                                        constant float& p_n [[buffer(0)]],
                                        constant float& p_f [[buffer(1)]],
                                        constant float& p_t [[buffer(2)]],
                                        constant float& p_r [[buffer(3)]],
                                        constant float& s_w [[buffer(4)]],
                                        constant float& s_h [[buffer(5)]],
                                        constant int& keep_edge [[buffer(6)]]
                                        )
{
    constexpr sampler textureSampler (mag_filter::nearest, // ***
                                  min_filter::nearest);
    FragmentOutput out;
    float f_x, f_y, c_x, c_y, c_x2, c_y2;
    /* global */
    f_x = p_n / p_r;
    f_y = p_n / p_t;
    c_x = 2 / (s_w * f_x);
    c_y = 2 / (s_h * f_y);
    c_x2 = c_x * c_x;
    c_y2 = c_y * c_y;
    float x = in.vTex.x, y = in.vTex.y;
    float dx = 1 / s_w, dy = 1 / s_h;
    float z = zTex.sample(textureSampler, float2(x, y)).r;
    float z2 = z * z;
    float dzdx = zTex.sample(textureSampler, float2(x + dx, y)).r - z;
    float dzdy = zTex.sample(textureSampler, float2(x, y + dy)).r - z;
    float dzdx2 = z - zTex.sample(textureSampler, float2(x - dx, y)).r;
    float dzdy2 = z - zTex.sample(textureSampler, float2(x, y - dy)).r;

    /* Skip silhouette */
    if (keep_edge == 1) {
        if (abs(dzdx2) < abs(dzdx)) dzdx = dzdx2;
        if (abs(dzdy2) < abs(dzdy)) dzdy = dzdy2;
    }
    float3 n = float3(-c_y * dzdx, -c_x * dzdy, c_x*c_y*z);
    /* revert n.z to positive for debugging */
    n.z = -n.z;
    float d = length(n);
    out.FragColor = float4(n / d, d);

    return out;
}

)";

static const char* shading_vs_metal = R"(
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
struct VertexInput
{
    float4 aVertex [[attribute(0)]];
};
struct VertexOutput
{
    float2 vTex;
    float4 gl_Position [[position]];
};
vertex VertexOutput vertexShader(VertexInput in [[stage_in]])
{
    VertexOutput out;
    (out.vTex = ((in.aVertex.xy * 0.5) + 0.5));
    out.vTex.y = 1.0 - out.vTex.y;
    out.gl_Position = in.aVertex;
    out.gl_Position.z = 0.0;
    out.gl_Position.w = 1.0;
    return out;
}
)";

// color order is BGRA
static const char* shading_metallic_fs_metal = R"(
#include <metal_stdlib>
using namespace metal;

template<typename T>
struct TSampler2D
{
    thread texture2d<T>& _texture2d;
    thread sampler& _sampler;
};
typedef TSampler2D<float> sampler2D;

template <typename T>
vec<T,4> texture(thread TSampler2D<T>& sampler2d, float2 texcoord)
{
    return sampler2d._texture2d.sample(sampler2d._sampler, texcoord);
}

struct FragmentInput
{
    float2 vTex;
};

struct FragmentOutput
{
    float4 FragColor [[color(0)]];
    float depth_out [[depth(any)]];
};

float2 calcSphericalTexCoordsFromDir(float3 reflDir){
    float m=2.0*sqrt(reflDir.x*reflDir.x+reflDir.y*reflDir.y+(reflDir.z)*(reflDir.z));
    float2 reflTexCoord=reflDir.xy/m+0.5;
    return reflTexCoord;
}

fragment FragmentOutput fragmentShader(
                                        FragmentInput      in             [[stage_in]],
                                        texture2d<float>   zTex           [[ texture(0) ]],
                                        texture2d<float>   normalDTex     [[ texture(1) ]],
                                        texture2d<float>   thickTex       [[ texture(2) ]],
                                        texture2d<float>   cameraTex      [[ texture(3) ]],
                                        texture2d<float>   reflectTex     [[ texture(4) ]],
                                        constant float4x4& iview          [[buffer(0)]],
                                        constant float&    p_n            [[buffer(1)]],
                                        constant float&    p_f            [[buffer(2)]],
                                        constant float&    p_t            [[buffer(3)]],
                                        constant float&    p_r            [[buffer(4)]],
                                        constant int&      shading_option [[buffer(5)]],
                                        constant float&    r0             [[buffer(6)]]
                                        )
{
    sampler textureSampler0 (mag_filter::nearest,
                                  min_filter::nearest);
    sampler textureSampler1 (mag_filter::linear,
                                  min_filter::linear);
    sampler2D _zTex{ zTex, textureSampler0 };
    sampler2D _normalDTex{ normalDTex, textureSampler0 };
    sampler2D _thickTex{ thickTex, textureSampler1 };
    sampler2D _cameraTex{ cameraTex, textureSampler1 };
    sampler2D _reflectTex{ reflectTex, textureSampler1 };

    FragmentOutput out;

    float3 n = texture(_normalDTex, in.vTex).xyz;    // normal
    float2 depth = texture(_zTex, in.vTex).xy;
    float zp = depth.x;
    float xp = in.vTex.x, yp = in.vTex.y;
    xp = (2 * xp - 1)*p_r*zp / p_n;
    yp = (2 * yp - 1)*p_t*zp / p_n;
    float3 p = float3(xp, yp, -zp);
    float3 e = normalize(-p);                        // V
    float fresnel = dot(e, n);                       // freshnel
    float3 refractionVec = refract(e, n, 0.5);       // refract vector

    float thickness = texture(_thickTex, in.vTex).x;
    float4 texColor = texture(_cameraTex, in.vTex);
    if (thickness <= 0.01) {
        out.FragColor = texColor;
        return out;
    }

    // reflect
    float3 reflectVec = reflect(e, n);
    reflectVec.z = -reflectVec.z;
    float2 reflectUV = calcSphericalTexCoordsFromDir(reflectVec);
    reflectUV = normalize(reflectUV) * 0.3 + float2(0.5);
    float4 reflectColor;
    if (thickness <= 0.01) {
        reflectUV = in.vTex;
        reflectColor = texture(_cameraTex, reflectUV);
    }
    else {
        reflectColor = texture(_reflectTex, reflectUV);  // _reflectTex
        reflectColor.rgb = 0.5 - 0.5 * cos(3.1415926 * reflectColor.rgb);  //1.0 / (1.0 + pow(15.0, -reflectColor.rgb - 0.5))
        reflectColor.rgb *= 1.35; // make it brighter
    }
    reflectColor.a = 1.0;

    float depth_weight = depth.y;
    float mix_factor = min(depth_weight, 3000.0) / 3000.0;
    mix_factor = 1.0 - cos(mix_factor * 1.57);
    reflectColor = mix(texColor, reflectColor, mix_factor);
    
    out.FragColor = reflectColor;

    return out;

}

)";

static const char* shading_fs_metal = R"(
#include <metal_stdlib>
using namespace metal;

/*
    shading water with camera texture
*/

template<typename T>
struct TSampler2D
{
    thread texture2d<T>& _texture2d;
    thread sampler& _sampler;
};
typedef TSampler2D<float> sampler2D;

template <typename T>
vec<T,4> texture(thread TSampler2D<T>& sampler2d, float2 texcoord)
{
    return sampler2d._texture2d.sample(sampler2d._sampler, texcoord);
}

struct FragmentInput
{
    float2 vTex;
};

struct FragmentOutput
{
    float4 FragColor [[color(0)]];
    float depth_out [[depth(any)]];
};

float2 calcSphericalTexCoordsFromDir(float3 reflDir){
    float m=2.0*sqrt(reflDir.x*reflDir.x+reflDir.y*reflDir.y+(reflDir.z)*(reflDir.z));
    float2 reflTexCoord=reflDir.xy/m+0.5;
 //   reflTexCoord.y = -reflTexCoord.y;
    return reflTexCoord;
}

float fit(float x) {
    if (x < 0.53) return 0.82 / tan(x / 0.65);
    if (x > 0.8034) return sqrt(1-pow(x,0.66));
    return -1.48335*(x-0.5301)+0.7721;
}

fragment FragmentOutput fragmentShader(
                                        FragmentInput      in             [[stage_in]],
                                        texture2d<float>   zTex           [[ texture(0) ]],
                                        texture2d<float>   normalDTex     [[ texture(1) ]],
                                        texture2d<float>   thickTex       [[ texture(2) ]],
                                        texture2d<float>   cameraTex      [[ texture(3) ]],
                                        texture2d<float>   reflectTex     [[ texture(4) ]],
                                        float2 gl_PointCoord [[point_coord]],
                                        constant float4x4& iview          [[buffer(0)]],
                                        constant float&    p_n            [[buffer(1)]],
                                        constant float&    p_f            [[buffer(2)]],
                                        constant float&    p_t            [[buffer(3)]],
                                        constant float&    p_r            [[buffer(4)]],
                                        constant int&      shading_option [[buffer(5)]],
                                        constant float&    r0             [[buffer(6)]]
                                        )
{
    sampler textureSampler0 (mag_filter::nearest,
                                  min_filter::nearest);
    sampler textureSampler1 (mag_filter::linear,
                                  min_filter::linear);
    sampler2D _zTex{ zTex, textureSampler0 };
    sampler2D _normalDTex{ normalDTex, textureSampler0 };
    sampler2D _thickTex{ thickTex, textureSampler1 };
    sampler2D _cameraTex{ cameraTex, textureSampler1 };
    sampler2D _reflectTex{ reflectTex, textureSampler1 };

    FragmentOutput out;

    float3 n = texture(_normalDTex, in.vTex).xyz;    // normal vector
    float2 depth = texture(_zTex, in.vTex).xy;
    float zp = depth.x;
    float xp = in.vTex.x, yp = in.vTex.y;
    xp = (2 * xp - 1)*p_r*zp / p_n;
    yp = (2 * yp - 1)*p_t*zp / p_n;
    float3 p = float3(xp, yp, -zp);
    float3 e = normalize(-p);                        // light direction V
    float fresnel = dot(e, n);                       // Fresnel angle
    float3 refractionVec = refract(e, n, 0.5);       // calculate the refraction vector, refractive index eta =0.5
    float3 N0 = float3(0.0, 0.0, 1.0);
    float2 _coord = in.vTex;
    float thickness = texture(_thickTex, in.vTex).x;
    float4 texColor = texture(_cameraTex, float2(_coord.x, 1.0 - _coord.y));
    int insideFlag = 0.0;

    // refract
    if (thickness <= 0.01) {
        out.FragColor = texColor;
        return out;
    }
    float cosin_alpha = clamp(abs(dot(e, n)), 0.0, 1.0);
    float uv_offset = fit(cosin_alpha) * 3.0;
    float3 offset_dir = normalize(cross(N0, cross(n, e)));
    float2 offset_xy = offset_dir.xy * uv_offset * 0.1;
    _coord = in.vTex + offset_xy;
    float4 refractColor = texture(_cameraTex, float2(_coord.x, 1.0 - _coord.y));
    if (thickness <= 0.01) {
        refractColor = texColor;
    }
    float depth_weight = depth.y;
    float mix_weight_sum = 2700.0;
    float mix_factor = min(depth_weight, mix_weight_sum) / mix_weight_sum;
    mix_factor = 1.0 - cos(mix_factor * 1.57);
    refractColor.a = 1.0;

    // reflect
    float3 reflectVec = reflect(e, n);
    reflectVec.z = -reflectVec.z;
    float2 reflectUV = calcSphericalTexCoordsFromDir(reflectVec) * 0.02 + in.vTex;
    float4 reflectColor;
    if (thickness <= 0.01) {
        reflectUV = in.vTex;
        reflectColor = texture(_cameraTex, float2(reflectUV.x, 1.0 - reflectUV.y));
    }
    else {
        reflectColor = texture(_reflectTex, reflectUV);  // _reflectTex
    }
    reflectColor.a = 1.0;

    // freshnel mixing
    float R = r0 + (1 - r0) * pow(clamp(1 - abs(dot(n, e)), 0.0, 1.0), 5);
    R = clamp(R * 2.5, 0.0, 1.0);
    float4 render_color =  mix(refractColor, reflectColor, R);
    render_color = mix(texColor, render_color, mix_factor);

    // specular
    float3 halfDir = normalize(float3(0.5, 0.75, -0.2) + e);
    render_color.rgb += float3(0.9) * pow(max(0.0, dot(n, halfDir)), 20.0) * 1.2;

    //float light = normalize(vec3(0.0,1.0,0.8));
    //color += vec3(specular(n,l,eye,60.0));

    out.FragColor = render_color * float4(0.9, 0.9, 0.99, 1.0);



    return out;

}
)";

static const char* shading_glass_vs_metal = R"(
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
struct VertexInput
{
    float4 aVertex [[attribute(0)]];
};
struct VertexOutput
{
    float2 vTex;
    float4 gl_Position [[position]];
};
vertex VertexOutput vertexShader(VertexInput in [[stage_in]])
{
    VertexOutput out;
    (out.vTex = ((in.aVertex.xy * 0.5) + 0.5));
    out.vTex.y = 1.0 - out.vTex.y;
    out.gl_Position = in.aVertex;
    out.gl_Position.z = 0.0;
    out.gl_Position.w = 1.0;
    return out;
}
)";

static const char* shading_glass_fs_metal = R"(
#include <metal_stdlib>
using namespace metal;

/*
    shading glasses with water
*/

template<typename T>
struct TSampler2D
{
    thread texture2d<T>& _texture2d;
    thread sampler& _sampler;
};
typedef TSampler2D<float> sampler2D;

template <typename T>
vec<T,4> texture(thread TSampler2D<T>& sampler2d, float2 texcoord)
{
    return sampler2d._texture2d.sample(sampler2d._sampler, texcoord);
}

struct FragmentInput
{
    float2 vTex;
};

struct FragmentOutput
{
    float4 FragColor [[color(0)]];
    float depth_out [[depth(any)]];
};

float fsqr(float x) {
    return x * x;
}

// reflected energy lobe - modified Shlick's approximation for the critical angle
//   of total internal reflection, cosAlpha = NoV
float getFresnelFactor(float cosAlpha, float cosAlphaCrit){
    return max(0.0, min( 1.0, pow(1.0 - (cosAlpha + cosAlphaCrit - 1.0) / cosAlphaCrit, 5.0)));
}

//cosine of refraction angle (NoR)
float getCosGamma(float cosAlpha, float N1, float N2){
    return sqrt(1.0 - N1*N1*(1.0-cosAlpha*cosAlpha)/(N2*N2));
}

//refracted ray length relative to incidence angle of 0 degrees and a unit shell thickness
float getRefractedRayLength(float cosAlpha, float N1, float N2){
    return 1.0 / getCosGamma(cosAlpha, N1, N2);
}

float3 getScatteringCoef(float3 T, float dist){
    return log(float3(1.0,1.0,1.0) / T) / dist;
}

float3 _getTransmittance(float3 scatteringCoef, float dist){
    return exp(-scatteringCoef*dist);
}

float3 getTransmittance(float3 t0, float D0, float dist){
    return _getTransmittance(getScatteringCoef(t0, D0), dist);
}

//http://iquilezles.org/www/articles/spherefunctions/spherefunctions.htm
float sphIntersect( float3 ro, float3 rd, float4 sph )
{
    float3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return -1.0;
    h = sqrt( h );
    return -b - h;
}

float2 calcSphericalTexCoordsFromDir(float3 reflDir){
    float m=2.0*sqrt(reflDir.x*reflDir.x+reflDir.y*reflDir.y+(reflDir.z)*(reflDir.z));
    float2 reflTexCoord=reflDir.xy/m+0.5;
    return reflTexCoord;
}

fragment FragmentOutput fragmentShader(
                                        FragmentInput      in             [[stage_in]],
                                        texture2d<float>   zTex           [[ texture(0) ]],
                                        texture2d<float>   normalDTex     [[ texture(1) ]],
                                        texture2d<float>   thickTex       [[ texture(2) ]],
                                        texture2d<float>   cameraTex      [[ texture(3) ]],
                                        texture2d<float>   reflectTex     [[ texture(4) ]],
                                        float2 gl_PointCoord [[point_coord]],
                                        constant float4x4& iview          [[buffer(0)]],
                                        constant float&    p_n            [[buffer(1)]],
                                        constant float&    p_f            [[buffer(2)]],
                                        constant float&    p_t            [[buffer(3)]],
                                        constant float&    p_r            [[buffer(4)]],
                                        constant int&      shading_option [[buffer(5)]],
                                        constant float&    r0             [[buffer(6)]]
                                        )
{
    sampler textureSampler0 (mag_filter::nearest,
                                  min_filter::nearest);
    sampler textureSampler1 (mag_filter::linear,
                                  min_filter::linear);
    sampler2D _zTex{ zTex, textureSampler0 };
    sampler2D _normalDTex{ normalDTex, textureSampler0 };
    sampler2D _thickTex{ thickTex, textureSampler1 };
    sampler2D _cameraTex{ cameraTex, textureSampler1 };
    sampler2D _reflectTex{ reflectTex, textureSampler1 };

    FragmentOutput out;

    float3 n = texture(_normalDTex, in.vTex).xyz;    // normal vector
    float2 depth = texture(_zTex, in.vTex).xy;
    float zp = depth.x;
    float xp = in.vTex.x, yp = in.vTex.y;
    xp = (2 * xp - 1)*p_r*zp / p_n;
    yp = (2 * yp - 1)*p_t*zp / p_n;
    float3 p = float3(xp, yp, -zp);
    float3 e = normalize(-p);                        // light direction V
    float fresnel = dot(e, n);                       // Fresnel angle
    float3 refractionVec = refract(e, n, 0.5);       // calculate the refraction vector, refractive index eta =0.5
    float3 N0 = float3(0.0, 0.0, 1.0);
    float2 _coord = in.vTex;
    float thickness = texture(_thickTex, in.vTex).x;
    float4 texColor = texture(_cameraTex, float2(_coord.x, 1.0 - _coord.y));
    int insideFlag = 0.0;
    const float rayScale = 1.23;

    /* glass effects */
    float2 uv = in.vTex * 2.0 - 1.0;
    uv.y *= 1.77778;
    float3 rayDir = normalize(float3(uv.x, uv.y, rayScale));  // controls the size of glass ball
    float3 eyePos = float3(0.0);
    const float3 spherePos = float3(-0.01, 0.0, 1.2);
    const float sphereRadius = 0.5;
    const float d0 = 0.1;//medium thickness
    const float n1 = 1.000292; //air
    const float n2 = 1.49; //plexiglass
    const float3 T0 = float3(0.9, 0.9, 0.9); //default transmittance for NoV = 1.0
    const float3 GAMMA = float3(3.2);    // controls the reflect effect
    const float3 ambientColor = float3(0.26, 0.28, 0.29);
    const float inscatterFactor = 0.3;
    const float RoVcrit = 1.2;
    const float reflect_intensity = 0.8;
    float3 lightColor = float3(0.9, 0.9, 0.9);

    float s = sphIntersect(eyePos, rayDir, float4(spherePos, sphereRadius));
    float s0 = sphIntersect(eyePos, normalize(float3(0.0, 0.0, rayScale)), float4(spherePos, sphereRadius));
    float3 N = normalize(eyePos + rayDir * s - spherePos);
    float NoV = dot(N, -rayDir);
    NoV = pow(NoV, 1.8);

    float3 col;
    if (s > 0.0) {
        insideFlag = 1.0;
        // initial color
        float2 envTex = in.vTex - float2(0.5);
        envTex = in.vTex + NoV * 0.15 * envTex;
        col = texture(_cameraTex, float2(envTex.x, 1.0 - envTex.y)).rgb;
        // transmitted light.
        float Ft = 1.0 - getFresnelFactor(NoV, RoVcrit); //energy lobe
        float d = d0 * getRefractedRayLength(NoV, n1, n2);
        float3 T = getTransmittance(pow(T0, GAMMA), d0, d);
        col *= T * Ft * (1.0-getFresnelFactor(NoV, 1.0));

        //magic approximation: inscattered light within shell thickness
        col += 1.2 * getTransmittance(pow(T0, GAMMA), d0, d*4.0) * ambientColor * clamp(1.0 - Ft, 0.0, 1.0) * pow(inscatterFactor, GAMMA.x);

        //reflected light
        const float specularLobeMin = 0.04;
        float Fr = specularLobeMin + (1.0-specularLobeMin) * getFresnelFactor(NoV, 1.0);
        Fr = reflect_intensity * pow(Fr, 0.6);
        float3 R = N * float3(NoV, NoV, NoV) * float3(2.0, 2.0, 2.0) + rayDir;
        col += pow(texture(_reflectTex, R.xy * 0.5 + 0.5).rgb, GAMMA) * Fr;

        col = pow(col, float3(1.0/GAMMA)) * 0.95;

        // specular
        float3 ball_norm = normalize(float3(uv * rayScale, clamp(1.0 - (s - s0) / (1.0 - s0), 0.0, 1.0)));
        float3 half_dir = normalize(float3(0.5, 0.75, -0.2) + float3(0.0, 0.0, 1.0));
        col += 0.3 * lightColor * T0 * pow(max(0.0, dot(ball_norm, half_dir)), 0.8);
    }
    else {
        col = texColor.rgb;
    }

    out.FragColor = float4(col, 1.0);

    return out;

}
)";

static const char* display_vs_metal = R"(
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
struct VertexInput
{
    float4 aVertex [[attribute(0)]];
};
struct VertexOutput
{
    float2 vTex;
    float4 gl_Position [[position]];
};
struct VertexContext
{
    thread VertexInput& in;
    thread VertexOutput& out;
    void main()
    {
        (out.vTex = ((in.aVertex.xy * 0.5) + 0.5));
        out.gl_Position = in.aVertex;
        out.gl_Position.z = 0.0;
        out.gl_Position.w = 1.0;
    }
};
vertex VertexOutput vertexShader(VertexInput in [[stage_in]])
{
    VertexOutput out;
    VertexContext
    {
        .in = in,
        .out = out,
    }.main();
    return out;
}
)";

// color order is BGRA
static const char* display_fs_metal = R"(
#include <metal_stdlib>
using namespace metal;

#define texturecube texture2d_array
template<typename T>
struct TSampler2D
{
    thread texture2d<T>& _texture2d;
    thread sampler& _sampler;
};
typedef TSampler2D<float> sampler2D;

template <typename T>
vec<T,4> texture(thread TSampler2D<T>& sampler2d, float2 texcoord)
{
    return sampler2d._texture2d.sample(sampler2d._sampler, texcoord);
}

struct FragmentInput
{
    float2 vTex;
};
struct FragmentOutput
{
    float4 FragColor [[color(0)]];
};

[[early_fragment_tests]]
fragment FragmentOutput fragmentShader(
                                       FragmentInput in [[stage_in]],
                                       texture2d<float> intputTexture [[ texture(0) ]])
{
    FragmentOutput out;
    constexpr sampler textureSampler (mag_filter::nearest,
                                      min_filter::nearest);

    float4 colorSample = intputTexture.sample (textureSampler, in.vTex);
    float ap = (colorSample.x );
    ap = ap/5.0;
    //ap = (ap - 0.8) * 5.0;
    colorSample = float4(ap, ap, ap, 1.0);
    out.FragColor = float4(colorSample.rgb, 1.0);
    return out;
}

)";

// http://stackoverflow.com/questions/1148309/inverting-a-4x4-matrix
Matrix4x4f _inverse(const Matrix4x4f& op)
{
    Matrix4x4f inv_mat;
    const float* m = op.m_Data;
    float* inv = inv_mat.m_Data;
    memset(inv, 0, 16 * sizeof(float));

    return inv_mat;
}

#endif /* SSFR_shader_h */

#endif
