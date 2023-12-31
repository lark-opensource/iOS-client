#ifndef MOBILECV2_YUV_CVT_HPP
#define MOBILECV2_YUV_CVT_HPP
#include "mobilecv2/core.hpp"
namespace mobilecv2
{

 /*
 *   YUV -> RGB
 *   R = Y + 1.375  *(V-128)
 *   G = Y - 0.34375*(U-128)  - 0.703125*(V-128)
 *   B = Y - 1.734374*(U-128)
 */

/*
 *   RGB -> YUV
 *   Y = 16  + 0.2578*R + 0.5078*G + 0.1016*B
 *   U = 128 - 0.1484*R - 0.2891*G + 0.4375*B
 *   V = 128 + 0.4375*R - 0.3672*G - 0.0703*B
 */

/**
 * NV12 to RGBA format convert
 * @author  
 * @param src_y Y data address of source image
 * @param src_stride_y  Stride of Y data
 * @param src_uv  UV data address of source image
 * @param src_stride_uv Stride of UV data
 * @param dst_rgba  Data address of destination image
 * @param dst_stride_rgba Stride of destination data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int nv12_to_rgba(uint8_t *src_y, int src_stride_y, uint8_t *src_uv, int src_stride_uv,
                      uint8_t *dst_rgba, int dst_stride_rgba, int width, int height);

/**
 * NV12 to RGBA format convert(simple version)
*/
    CV_EXPORTS_W int nv12_to_rgba(uint8_t *src_y, uint8_t *dst_rgba, int width, int height);

/**
 * NV21 to RGBA format convert
 * @author  
 * @param src_y Y data address of source image
 * @param src_stride_y  Stride of Y data
 * @param src_uv  UV data address of source image
 * @param src_stride_uv Stride of UV data
 * @param dst_rgba  Data address of destination image
 * @param dst_stride_rgba Stride of destination data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int
    nv21_to_rgba(uint8_t *src_y, int src_stride_y, uint8_t *src_uv, int src_stride_uv,
                      uint8_t *dst_rgba, int dst_stride_rgba, int width, int height);
/**
 * NV21 to RGBA format convert(simple version)
*/

    CV_EXPORTS_W int nv21_to_rgba(uint8_t *src_y, uint8_t *dst_rgba, int width, int height);

/**
 * I420 to RGBA format convert
 * @author  
 * @param src_y Y data address of source image
 * @param src_stride_y  Stride of Y data
 * @param src_uv  U data address of source image
 * @param src_stride_uv Stride of U data
 * @param src_uv  V data address of source image
 * @param src_stride_v Stride of V data
 * @param dst_rgba  Data address of destination image
 * @param dst_stride_rgba Stride of destination data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int
    i420_to_rgba(uint8_t *src_y, int src_stride_y, uint8_t *src_u, int src_stride_u,
                      uint8_t *src_v, int src_stride_v,
                      uint8_t *dst_rgba, int dst_stride_rgba, int width, int height);
/**
 * I420 to RGBA format convert(simple version)
*/
    CV_EXPORTS_W int i420_to_rgba(uint8_t *src_y, uint8_t *dst_rgba, int width, int height);

/**
 * RGBA to NV12 format convert
 * @author  
 * @param src_rgba Data address of source image
 * @param src_stride_rgba Stride of source data
 * @param dst_y Adress of destination image's Y data
 * @param dst_stride_y Stride of Y data
 * @param dst_uv  Address of destination image's UV data
 * @param dst_stride_uv Stride of UV data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int
    rgba_to_nv12(const uint8_t *src_rgba, int src_stride_rgba, uint8_t *dst_yuv,
                      int dst_stride_y,
                      uint8_t *dst_uv, int dst_stride_uv, int width, int height);


/**
 * RGBA to NV12 format convert(simple version)
*/
    CV_EXPORTS_W int
    rgba_to_nv12(const uint8_t *src_rgba, uint8_t *dst_yuv, int width, int height);

/**
 * RGBA to NV21 format convert
 * @author  
 * @param src_rgba Data address of source image
 * @param src_stride_rgba Stride of source data
 * @param dst_y Adress of destination image's Y data
 * @param dst_stride_y Stride of Y data
 * @param dst_uv  Address of destination image's UV data
 * @param dst_stride_uv Stride of UV data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int
    rgba_to_nv21(const uint8_t *src_rgba, int src_stride_rgba, uint8_t *dst_yuv,
                      int dst_stride_y,
                      uint8_t *dst_uv, int dst_stride_uv, int width, int height);


/**
 * RGBA to NV21 format convert(simple version)
*/

    CV_EXPORTS_W int
    rgba_to_nv21(const uint8_t *src_rgba, uint8_t *dst_yuv, int width, int height);

/**
 * RGBA to I420 format convert
 * @author  
 * @param src_rgba Data address of source image
 * @param src_stride_rgba Stride of source data
 * @param dst_y Adress of destination image's Y data
 * @param dst_stride_y Stride of Y data
 * @param dst_u  Address of destination image's U data
 * @param dst_stride_u Stride of U data
 * @param dst_v  Address of destination image's V data
 * @param dst_stride_v Stride of V data
 * @param width Image width
 * @param height Image height
 */


  CV_EXPORTS_W int
  rgba_to_i420(const uint8_t *src_rgba, int src_stride_rgba, uint8_t *dst_y,
                      int dst_stride_y,
                      uint8_t *dst_u, int dst_stride_u, uint8_t *dst_v, int dst_stride_v, int width,
                      int height);
/**
 * RGBA to I420 format convert(simple version)
*/

    CV_EXPORTS_W int
    rgba_to_i420(const uint8_t *src_rgba, uint8_t *dst_yuv, int width, int height);



/**
 * NV12 to BGRA format convert
 * @author  
 * @param src_y Y data address of source image
 * @param src_stride_y  Stride of Y data
 * @param src_uv  UV data address of source image
 * @param src_stride_uv Stride of UV data
 * @param dst_bgra  Data address of destination image
 * @param dst_stride_bgra Stride of destination data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int nv12_to_bgra(uint8_t *src_y, int src_stride_y, uint8_t *src_uv, int src_stride_uv,
                      uint8_t *dst_bgra, int dst_stride_bgra, int width, int height);

/**
 * NV12 to BGRA format convert(simple version)
*/
    CV_EXPORTS_W int nv12_to_bgra(uint8_t *src_y, uint8_t *dst_bgra, int width, int height);

/**
 * NV21 to BGRA format convert
 * @author  
 * @param src_y Y data address of source image
 * @param src_stride_y  Stride of Y data
 * @param src_uv  UV data address of source image
 * @param src_stride_uv Stride of UV data
 * @param dst_bgra  Data address of destination image
 * @param dst_stride_bgra Stride of destination data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int
    nv21_to_bgra(uint8_t *src_y, int src_stride_y, uint8_t *src_uv, int src_stride_uv,
                      uint8_t *dst_bgra, int dst_stride_bgra, int width, int height);
/**
 * NV21 to BGRA format convert(simple version)
*/

    CV_EXPORTS_W int nv21_to_bgra(uint8_t *src_y, uint8_t *dst_bgra, int width, int height);


/**
 * I420 to BGRA format convert
 * @author  
 * @param src_y Y data address of source image
 * @param src_stride_y  Stride of Y data
 * @param src_uv  U data address of source image
 * @param src_stride_uv Stride of U data
 * @param src_uv  V data address of source image
 * @param src_stride_v Stride of V data
 * @param dst_bgra  Data address of destination image
 * @param dst_stride_bgra Stride of destination data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int
    i420_to_bgra(uint8_t *src_y, int src_stride_y, uint8_t *src_u, int src_stride_u,
                      uint8_t *src_v, int src_stride_v,
                      uint8_t *dst_bgra, int dst_stride_bgra, int width, int height);
/**
 * I420 to BGRA format convert(simple version)
*/
    CV_EXPORTS_W int i420_to_bgra(uint8_t *src_y, uint8_t *dst_bgra, int width, int height);

/**
 * BGRA to NV12 format convert
 * @author  
 * @param src_bgra Data address of source image
 * @param src_stride_bgra Stride of source data
 * @param dst_y Adress of destination image's Y data
 * @param dst_stride_y Stride of Y data
 * @param dst_uv  Address of destination image's UV data
 * @param dst_stride_uv Stride of UV data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int
    bgra_to_nv12(const uint8_t *src_bgra, int src_stride_bgra, uint8_t *dst_yuv,
                      int dst_stride_y,
                      uint8_t *dst_uv, int dst_stride_uv, int width, int height);


/**
 * BGRA to NV12 format convert(simple version)
*/
    CV_EXPORTS_W int
    bgra_to_nv12(const uint8_t *src_bgra, uint8_t *dst_yuv, int width, int height);

/**
 * BGRA to NV21 format convert
 * @author  
 * @param src_bgra Data address of source image
 * @param src_stride_bgra Stride of source data
 * @param dst_y Adress of destination image's Y data
 * @param dst_stride_y Stride of Y data
 * @param dst_uv  Address of destination image's UV data
 * @param dst_stride_uv Stride of UV data
 * @param width Image width
 * @param height Image height
 */

    CV_EXPORTS_W int
    bgra_to_nv21(const uint8_t *src_bgra, int src_stride_bgra, uint8_t *dst_yuv,
                      int dst_stride_y,
                      uint8_t *dst_uv, int dst_stride_uv, int width, int height);


/**
 * BGRA to NV21 format convert(simple version)
*/

    CV_EXPORTS_W int
    bgra_to_nv21(const uint8_t *src_bgra, uint8_t *dst_yuv, int width, int height);

/**
 * BGRA to I420 format convert
 * @author  
 * @param src_bgra Data address of source image
 * @param src_stride_bgra Stride of source data
 * @param dst_y Adress of destination image's Y data
 * @param dst_stride_y Stride of Y data
 * @param dst_u  Address of destination image's U data
 * @param dst_stride_u Stride of U data
 * @param dst_v  Address of destination image's V data
 * @param dst_stride_v Stride of V data
 * @param width Image width
 * @param height Image height
 */


  CV_EXPORTS_W int
  bgra_to_i420(const uint8_t *src_bgra, int src_stride_bgra, uint8_t *dst_y,
                      int dst_stride_y,
                      uint8_t *dst_u, int dst_stride_u, uint8_t *dst_v, int dst_stride_v, int width,
                      int height);
/**
 * BGRA to I420 format convert(simple version)
*/

    CV_EXPORTS_W int
    bgra_to_i420(const uint8_t *src_bgra, uint8_t *dst_yuv, int width, int height);

/**
 * NV21 Resize
*/

    CV_EXPORTS_W void NV21Scale(uint8_t* src, int src_width, int src_height, uint8_t* dst, int dst_width, int dst_height);

/**
 * NV12 Resize
*/
    CV_EXPORTS_W void NV12Scale(uint8_t* src, int src_width, int src_height, uint8_t* dst, int dst_width, int dst_height);

/**
 * I420 Resize
*/
    CV_EXPORTS_W void I420Scale(uint8_t* src, int src_width, int src_height, uint8_t* dst, int dst_width, int dst_height);

}


#endif
