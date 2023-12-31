/**
 * @file bef_swing_segment_custom_api.h
 * @author tangli (tangli.19960727@bytedance.com)
 * @brief
 * @version 0.1
 * @date 2022-8-5
 *
 * @copyright Copyright (c) 2022
 *
 */

#ifndef bef_swing_segment_custom_api_h
#define bef_swing_segment_custom_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h"


/**
 * @brief set segment order, use to sort custom and feature segment in video segment
 * @param segmentHandle instance of custom segment
 * @param order order of custom segment, default value is 0
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_custom_set_order(bef_swing_segment_t* segmentHandle,
                                    int order);

/**
 * @brief get segment order
 * @param segmentHandle instance of custom segment
 * @param order [out] order of custom segment
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_custom_get_order(bef_swing_segment_t* segmentHandle,
                                    int* order);

/**
 * @brief set render callback for custom segment
 * @param segmentHandle  instance of custom segment
 * @param timestamp time stamp of current frame, in microsecond
 * @param input/output texture-related info
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_custom_render_callback(void *userData,
        bef_swing_segment_t *segmentHandle,
        bef_swing_custom_render_call_back callBack);


#endif /* bef_swing_segment_custom_api_h */
