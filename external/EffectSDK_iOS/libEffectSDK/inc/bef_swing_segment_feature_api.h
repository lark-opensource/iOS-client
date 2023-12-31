/**
 * @file bef_swing_segment_feature_api.h
 * @author yankai.ff (yankai.ff@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2021-11-18
 * 
 * @copyright Copyright (c) 2021
 * 
 */

#ifndef bef_swing_segment_feature_api_h
#define bef_swing_segment_feature_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h" // BEF_SDK_API

/**
 * @brief set segment order, use to sort feature segment in video segment
 * @param segmentHandle instance of feature segment
 * @param order order of feature segment, default value is 0
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_feature_set_order(bef_swing_segment_t* segmentHandle,
                                    int order);

/**
 * @brief get segment order
 * @param segmentHandle instance of feature segment
 * @param order [out] order of feature segment
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_feature_get_order(bef_swing_segment_t* segmentHandle,
                                    int* order);

/**
 * @brief set time offset for feature segment
 * 
 * Actual renderig time is [start + start_offset, end - end_offset].
 * Offsets are 0 as default.
 * Only used by Jianying Pro.
 * 
 * @param segmentHandle instance of feature segment
 * @param start_offset absolute time start offset
 * @param end_offset absolute time end offset
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_feature_set_time_offset(bef_swing_segment_t* segmentHandle,
                                          bef_swing_time_t start_offset,
                                          bef_swing_time_t end_offset);


/**
 * @brief set user texture
 * @param segmentHandle instance of feature segment
 * @param userTextureId  user texture for SegmentFeature
 * @param userTextureWidth user texture width
 * @param userTextureHeight user texture height
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_feature_set_user_texture(bef_swing_segment_t* segmentHandle,
                                           const char* textureKey,
                                           unsigned int userTextureId,
                                           unsigned int userTextureWidth,
                                           unsigned int userTextureHeight);

/**
 * @brief set user texture
 * @param segmentHandle instance of feature segment
 * @param textureKey  key for texture
 * @param userTexture texture handle for segment feature
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_feature_set_user_device_texture(bef_swing_segment_t* segmentHandle,
                                                  const char* textureKey,
                                                  device_texture_handle userTexture);


#endif /* bef_swing_segment_feature_api_h */
