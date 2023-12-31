//
// Created by 吕晴阳 on 2020/12/17.
//

#ifndef BEF_EFFECT_IMGPROC_H
#define BEF_EFFECT_IMGPROC_H

#include "bef_framework_public_geometry_define.h"
#include "bef_effect_public_define.h"

typedef enum
{
    /** nearest neighbor interpolation */
    BEF_INTER_NEAREST       = 0,
    /** bilinear interpolation */
    BEF_INTER_LINEAR        = 1,

    /** inverse transformation */
    BEF_WARP_INVERSE_MAP    = 16
} bef_interpolation_flags;


/**
 * @brief Correcting perspective of an image.
 * @param src  input image.
 * @param srcPoints coordinates of quadrangle vertices in the source image.
 * @param dst output image that has the size dstWidth*dstHeight and the same type as src. Memory is allocated by sdk and need to be
 * release through bef_effect_release_image. *dst == null when error occurred.
 * @param dstWidth width of the output image.
 * @param dstHeight height of the output image.
 * @param interpolationFlags combination of interpolation methods (#BEF_INTER_NEAREST or #BEF_INTER_LINEAR) and the
 * optional flag #BEF_WARP_INVERSE_MAP, that sets M as the inverse transformation (\f$\texttt{dst}\rightarrow\texttt{src}\f$ ).
 * @sa bef_effect_release_image
 */
BEF_SDK_API void bef_effect_correct_perspective(const bef_image* src, const bef_fpoint* srcPoints,
                                                bef_image** dst, int dstWidth, int dstHeight, int interpolationFlags);

/**
 * @brief Release image.
 * @param img image allocated by sdk.
 */
BEF_SDK_API void bef_effect_release_image(bef_image* img);


/**
 * @brief Calculating aspect ratio of perspective transform destination image.
 * @param points  coordinates of quadrangle vertices in the source image.
 * @param imgWidth width of the source image.
 * @param imgHeight height of the source image.
 * @return original width/height ratio.
 */
BEF_SDK_API float bef_effect_calculate_aspect_ratio(const bef_fpoint* points, int imgWidth, int imgHeight);

#endif //BEF_EFFECT_IMGPROC_H
