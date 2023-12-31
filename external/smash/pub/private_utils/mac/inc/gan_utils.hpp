//
//  gan_utils.hpp
//  smash_algo-private_utils
//
//  Created by liqing on 2020/9/9.
//

#ifndef gan_utils_hpp
#define gan_utils_hpp

#include "internal_smash.h"
#include <mobilecv2/core.hpp>
#include "tt_common.h"

SMASH_NAMESPACE_OPEN
NAMESPACE_OPEN(private_utils)

void GetBestAffine(const std::vector<mobilecv2::Point2f> &srcpts, const std::vector<mobilecv2::Point2f> &dstpts, mobilecv2::Mat &affine);
void AddMarginToAffineMat(mobilecv2::Mat &affine_src, mobilecv2::Mat &affine_dst, int height, int width, float marginX, float marginY);
void AddOffsetToAffineMat(mobilecv2::Mat &affine_src, mobilecv2::Mat &affine_dst, const float offx, const float offy);

NAMESPACE_CLOSE(private_utils)
SMASH_NAMESPACE_CLOSE
#endif /* gan_utils_hpp */
