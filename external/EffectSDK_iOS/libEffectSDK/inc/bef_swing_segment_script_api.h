/**
 * @file bef_swing_segment_script_api.h
 * @author ninghualong (ninghualong@bytedance.com)
 * @brief
 * @version 0.1
 * @date 2022-05-27
 *
 * @copyright Copyright (c) 2022
 *
 */

#ifndef bef_swing_segment_script_api_h
#define bef_swing_segment_script_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h" // BEF_SDK_API

/**
 * @brief set sticker resolution type
 * @param segmentHandle instance of script segment
 * @param type bef_infoSticker_resolution_type
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_script_set_resolution_type(
    bef_swing_segment_t* segmentHandle, bef_InfoSticker_resolution_type type);

/**
 * @brief create layer for script segment
 * @param segmentHandle instance of segment
 * @param layerName name of layer, input name(using guid string as name)
 * @param layerParam layer param
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_script_create_layer(
    bef_swing_segment_t* segmentHandle, const char* layerName,
    const char* layerParam);

/**
 * @brief remove layer for script segment
 * @param segmentHandle instance of segment
 * @param layerName name of layer, input name(using guid string as name)
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_script_remove_layer(
    bef_swing_segment_t* segmentHandle, const char* layerName);

#endif /* bef_swing_segment_script_api_h */
