/**
 * @file bef_swing_segment_sticker_text_api.h
 * @author yuanzhihong (yuanzhihong@bytedance.com)
 * @brief
 * @version 0.1
 * @date 2021-11-25
 *
 * @copyright Copyright (c) 2021
 *
 */

#ifndef bef_swing_segment_sticker_text_api_h
#define bef_swing_segment_sticker_text_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h"

/**
 * @brief set text default params
 * @param segmentHandle instance of text segment
 * @param defaultParams text segment default params
     "default_params":
     {
     "pos_x":  0, // -1.0 ~ 1.0 Normalized coordinates, default: 0
     "pos_y":  0, // -1.0 ~ 1.0 Normalized coordinates, default:0
     "scale":  1.0, // >=0, default 1.0
     "rotate": 0.0, // Positive value counterclockwise, negative value clockwise, default 0.0
     "alpha":  1.0, // 0.0 ~ 1.0, default: 0
     "visible": true,  // Is it visible, true or false, default true
     "flip_x":  false,  // Whether to flip horizontally, true or false, default false
     "flip_y":  false   // Whether to flip vertically, true or false, default false
     }
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_text_set_default_params(bef_swing_segment_t* segmentHandle,
                                                  const char* defaultParams);

/**
 * @brief set rich text style by command
 * @param segmentHandle instance of text segment
 * @param inParam struct for rich text param
 * @param isSync is true means force type setting and then can use bef_swing_segment_sticker_get_rich_text synchronous get rich text param
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_rich_text(bef_swing_segment_t* segmentHandle, bef_info_sticker_edit_rich_text_param* inParam, bool isSync);

/**
 * @brief get rich text style by command
 * @param segmentHandle instance of text segment
 * @param inParam struct for rich text in param
 * @param outParam struct for rich text out param
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_rich_text(bef_swing_segment_t* segmentHandle, bef_info_sticker_edit_rich_text_param* inParam, bef_info_sticker_edit_rich_text_param** outParam);

/**
 * @brief release rich text out params memory, which provided by bef_swing_segment_sticker_get_rich_text
 * @param segmentHandle instance of text segment
 * @param outParam struct for rich text out param
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_release_rich_text_out_param(bef_swing_segment_t* segmentHandle, bef_info_sticker_edit_rich_text_param* outParam);

/**
 * @brief get letter segments of text string by ICU boundary analysis
 * @param inpuStr text string to do letter segment
 * @param segments result of string segment
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_get_letter_segments(const char* inputStr, char** segments);

/**
 * @brief release  letter segments memory, which provided by bef_swing_get_text_letter_segments
 * @param segments result of string segment
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_release_letter_segments(char* segments);

#endif /* bef_swing_segment_sticker_text_api_h */
