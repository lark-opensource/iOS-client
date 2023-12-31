#include <string>
static const char *metal_predefine_lens_luma = R"(
#include <metal_stdlib>
using namespace metal;
)";
static const char *kernel_cvt_color_lens_luma = R"(
kernel void yuv2rgba_nv12(texture2d<float, access::read>  imgY [[texture(0)]],
                          texture2d<float, access::read>  imgUV [[texture(1)]],
                          texture2d<float, access::write>  imgDst [[texture(2)]],
                          constant int& width [[buffer(0)]],
                          constant int& height [[buffer(1)]],
                          uint2 gid [[thread_position_in_grid]])
{
    const int dx = gid.x << 1;
    const int dy = gid.y << 1;
    if(dx >= width || dy >= height) {
        return;
    }
    //const float f1_255 = 0.0039215686;

    float2 Y0 = {imgY.read(uint2(dx, dy)).x,  imgY.read(uint2(dx + 1, dy)).x};
    float2 Y1 = {imgY.read(uint2(dx, dy + 1)).x, imgY.read(uint2(dx + 1, dy + 1)).x};

    float2 UV = imgUV.read(uint2(dx >> 1, dy >> 1)).xy;

    float2 U = {UV.x, UV.x};
    float2 V = {UV.y, UV.y};

    // Y0 = (Y0 - (float2)0.062745f) * (float2)1.164f;
    // float2 R = Y0 + (V-(float2)0.501961f) * (float2)1.596f;
    // float2 G = Y0 - (V-(float2)0.501961f) * (float2)0.813f - (U-(float2)0.501961f) * (float2)0.391f;
    // float2 B = Y0 + (U-(float2)0.501961f) * (float2)2.018f;
    float2 R = Y0 + (float2)1.400f * V - (float2)0.7f;
    float2 G = Y0 - (float2)0.343f * U - (float2)0.711f * V + (float2)0.526f;
    float2 B = Y0 + (float2)1.765f * U - (float2)0.883f;

    float4 out0 = {R.x, G.x, B.x, 1.f};
    float4 out1 = {R.y, G.y, B.y, 1.f};

    imgDst.write(out0, uint2(dx,   dy));
    imgDst.write(out1, uint2(dx + 1, dy));

    // Y1 = (Y1 - (float2)0.062745f) * (float2)1.164f;
    // R = Y1 + (V-(float2)0.501961f) * (float2)1.596f;
    // G = Y1 - (V-(float2)0.501961f) * (float2)0.813f - (U-(float2)0.501961f) * (float2)0.391f;
    // B = Y1 + (U-(float2)0.501961f) * (float2)2.018f;
    R = Y1 + (float2)1.400f * V - (float2)0.7f;
    G = Y1 - (float2)0.343f * U - (float2)0.711f * V + (float2)0.526f;
    B = Y1 + (float2)1.765f * U - (float2)0.883f;

    out0 = float4(R.x, G.x, B.x, 1.f);
    out1 = float4(R.y, G.y, B.y, 1.f);

    imgDst.write(out0, uint2(dx,   dy + 1));
    imgDst.write(out1, uint2(dx + 1, dy + 1));
}
kernel void yuv2bgra_nv12(texture2d<float, access::read>  imgY [[texture(0)]],
                          texture2d<float, access::read>  imgUV [[texture(1)]],
                          texture2d<float, access::write>  imgDst [[texture(2)]],
                          constant int& width [[buffer(0)]],
                          constant int& height [[buffer(1)]],
                          uint2 gid [[thread_position_in_grid]])
{
    const int dx = gid.x << 1;
    const int dy = gid.y << 1;
    if(dx >= width || dy >= height) {
        return;
    }
    //const float f1_255 = 0.0039215686;

    float2 Y0 = {imgY.read(uint2(dx, dy)).x,  imgY.read(uint2(dx + 1, dy)).x};
    float2 Y1 = {imgY.read(uint2(dx, dy + 1)).x, imgY.read(uint2(dx + 1, dy + 1)).x};

    float2 UV = imgUV.read(uint2(dx >> 1, dy >> 1)).xy;

    float2 U = {UV.x, UV.x};
    float2 V = {UV.y, UV.y};

    // Y0 = (Y0 - (float2)0.062745f) * (float2)1.164f;
    // float2 R = Y0 + (V-(float2)0.501961f) * (float2)1.596f;
    // float2 G = Y0 - (V-(float2)0.501961f) * (float2)0.813f - (U-(float2)0.501961f) * (float2)0.391f;
    // float2 B = Y0 + (U-(float2)0.501961f) * (float2)2.018f;
    float2 R = Y0 + (float2)1.400f * V - (float2)0.7f;
    float2 G = Y0 - (float2)0.343f * U - (float2)0.711f * V + (float2)0.526f;
    float2 B = Y0 + (float2)1.765f * U - (float2)0.883f;

    float4 out0 = {B.x, G.x, R.x, 1.f};
    float4 out1 = {B.y, G.y, R.y, 1.f};

    imgDst.write(out0, uint2(dx,   dy));
    imgDst.write(out1, uint2(dx + 1, dy));

    // Y1 = (Y1 - (float2)0.062745f) * (float2)1.164f;
    // R = Y1 + (V-(float2)0.501961f) * (float2)1.596f;
    // G = Y1 - (V-(float2)0.501961f) * (float2)0.813f - (U-(float2)0.501961f) * (float2)0.391f;
    // B = Y1 + (U-(float2)0.501961f) * (float2)2.018f;
    R = Y1 + (float2)1.400f * V - (float2)0.7f;
    G = Y1 - (float2)0.343f * U - (float2)0.711f * V + (float2)0.526f;
    B = Y1 + (float2)1.765f * U - (float2)0.883f;

    out0 = float4(B.x, G.x, R.x, 1.f);
    out1 = float4(B.y, G.y, R.y, 1.f);

    imgDst.write(out0, uint2(dx,   dy + 1));
    imgDst.write(out1, uint2(dx + 1, dy + 1));
}
constant float3 rgb2y  = float3(0.299f, 0.587f, 0.114f);
constant float3 rgb2cb = float3(-0.168736f, -0.331264f, 0.5f);
constant float3 rgb2cr = float3(0.5f, -0.418688f, -0.081312f);
kernel void rgba2yuv_nv12(texture2d<float, access::read> imgSrc [[texture(0)]],
                           texture2d<float, access::write>  imgDstY [[texture(1)]],
                           texture2d<float, access::write>  imgDstUV [[texture(2)]],
                           constant int& width [[buffer(0)]],
                           constant int& height [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]])
{
    int x = gid.x << 1;
    int y = gid.y << 1;
    if(x >= width || y >= height) {
        return;
    }
    
    uint2 gid_tmp = uint2(x, y);
    float3 rgb00 = imgSrc.read(gid_tmp).xyz;
    gid_tmp.x = x + 1;
    float3 rgb01 = imgSrc.read(gid_tmp).xyz;
    gid_tmp.y = y + 1;
    float3 rgb11 = imgSrc.read(gid_tmp).xyz;
    gid_tmp = uint2(x, y + 1);
    float3 rgb10 = imgSrc.read(gid_tmp).xyz;

    float Y00 = dot(rgb00, rgb2y);
    float Y01 = dot(rgb01, rgb2y);
    float Y10 = dot(rgb10, rgb2y);
    float Y11 = dot(rgb11, rgb2y);
    float Cb  = dot(rgb00, rgb2cb) + 0.5f;
    float Cr  = dot(rgb00, rgb2cr) + 0.5f;
    
    imgDstY.write((float4)Y00, uint2(x, y));
    imgDstY.write((float4)Y01, uint2(x + 1, y));
    imgDstY.write((float4)Y10, uint2(x, y + 1));
    imgDstY.write((float4)Y11, uint2(x + 1, y + 1));
    float4 uv = float4(Cb, Cr, 1.f, 1.f);
    imgDstUV.write(uv, uint2(x/2, y/2));
}
kernel void bgra2yuv_nv12(texture2d<float, access::read> imgSrc [[texture(0)]],
                           texture2d<float, access::write>  imgDstY [[texture(1)]],
                           texture2d<float, access::write>  imgDstUV [[texture(2)]],
                           constant int& width [[buffer(0)]],
                           constant int& height [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]])
{
    int x = gid.x << 1;
    int y = gid.y << 1;
    if(x >= width || y >= height) {
        return;
    }
    
    uint2 gid_tmp = uint2(x, y);
    float3 rgb00 = imgSrc.read(gid_tmp).zyx;
    gid_tmp.x = x + 1;
    float3 rgb01 = imgSrc.read(gid_tmp).zyx;
    gid_tmp.y = y + 1;
    float3 rgb11 = imgSrc.read(gid_tmp).zyx;
    gid_tmp = uint2(x, y + 1);
    float3 rgb10 = imgSrc.read(gid_tmp).zyx;

    float Y00 = dot(rgb00, rgb2y);
    float Y01 = dot(rgb01, rgb2y);
    float Y10 = dot(rgb10, rgb2y);
    float Y11 = dot(rgb11, rgb2y);
    float Cb  = dot(rgb00, rgb2cb) + 0.5f;
    float Cr  = dot(rgb00, rgb2cr) + 0.5f;
    
    imgDstY.write((float4)Y00, uint2(x, y));
    imgDstY.write((float4)Y01, uint2(x + 1, y));
    imgDstY.write((float4)Y10, uint2(x, y + 1));
    imgDstY.write((float4)Y11, uint2(x + 1, y + 1));
    float4 uv = float4(Cb, Cr, 1.f, 1.f);
    imgDstUV.write(uv, uint2(x/2, y/2));
}
kernel void bgra2rgba(texture2d<float, access::read> imgSrc [[texture(0)]],
                           texture2d<float, access::write>  imgDst [[texture(1)]],
                           constant int& width [[buffer(0)]],
                           constant int& height [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]])
{
    int x = gid.x << 1;
    int y = gid.y << 1;
    if(x >= width || y >= height) {
        return;
    }
    uint2 gid_tmp = uint2(x, y);
    imgDst.write(imgSrc.read(gid_tmp).zyxw, gid_tmp);

    gid_tmp.x = x + 1;
    imgDst.write(imgSrc.read(gid_tmp).zyxw, gid_tmp);

    gid_tmp.y = y + 1;
    imgDst.write(imgSrc.read(gid_tmp).zyxw, gid_tmp);

    gid_tmp = uint2(x, y + 1);
    imgDst.write(imgSrc.read(gid_tmp).zyxw, gid_tmp);
}

)";
