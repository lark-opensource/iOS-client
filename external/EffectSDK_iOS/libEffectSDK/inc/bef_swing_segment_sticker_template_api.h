/**
 * @file bef_swing_segment_sticker_template_api.h
 * @author yankai.ff (yankai.ff@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2021-11-17
 * 
 * @copyright Copyright (c) 2021
 * 
 */

#ifndef bef_swing_segment_sticker_template_api_h
#define bef_swing_segment_sticker_template_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h" // BEF_SDK_API

/**
 * @brief set template depend resouce
 * @param segmentHandle instance of template segment
 * @param dependResource template segment depend resource
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_template_set_depend_resource(bef_swing_segment_t* segmentHandle,
                                                       const char* dependResource);

#endif /* bef_swing_segment_sticker_template_api_h */
