/**
 * @file bef_swing_segment_static_api.h
 * @author ninghualong (ninghualong@bytedance.com)
 * @brief
 * @version 0.1
 * @date 2022-05-27
 *
 * @copyright Copyright (c) 2022
 *
 */

#ifndef bef_swing_segment_static_api_h
#define bef_swing_segment_static_api_h
#pragma once

#include "bef_swing_define.h"

#include "bef_framework_public_base_define.h" // BEF_SDK_API

/**
 * @brief pre add sticker to get cotent.json
 * @param json json need have current sticker path, screen size and resolution type.
 * @param result output json for bef_swing_segment_script_standalone_init and cutom need
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_script_preload(
    const char * json, char ** result);

/**
 * @brief Initialize standalone instance
 * @param GUID
 * @param config
 * @return bef_effect_result_t
 */
BEF_SDK_API
bef_effect_result_t
bef_swing_segment_script_standalone_init(const char* GUID, uint32_t GUID_length,
                                         const char* config,
                                         uint32_t config_length);

/**
 * @brief set standalone instance params
 * @param GUID
 * @param Action
 * @param Result
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_script_standalone_set_params(
    const char* GUID, uint32_t GUID_length, const char* action_json,
    uint32_t action_length, char** result_json, uint32_t* result_length);

/**
 * @brief Get standalone instance params
 * @param GUID
 * @param result
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_script_standalone_get_params(
    const char* GUID, uint32_t GUID_length, char** result_json,
    uint32_t* result_length);

/**
 * @brief Release standalone instance
 * @param GUID
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_script_standalone_release(
    const char* GUID, uint32_t GUID_length);

/**
 * @brief Parse info sticker
 * @param inputParams Input params
 * @param outputParams Output params
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_get_info_sticker_data(const char* inputParams, char** outputParams);

/**
 * @brief 获取某个时间点所有关键帧属性的值
 * 返回格式参考：{ "p": [0, 0, 0], "r": 60, "s": 1.0 }
 * @param strJson [in] the json protocol of WHOLE motion system.
 * @param timestamp [in] current timestamp should in range of (startTime, endTime)
 * @param outValueStr [out] outPut config files contain protocol informations of timestamp
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_key_frame_get_value_static(const char* strJson,
                                     bef_swing_time_t timestamp, // 在s和e之间的时间
                                     char** outValueStr);

/**
 * @brief 通过三次贝塞尔插值, 给定输入p0, p1, p2, p3 -> Vector2f，给定输入百分比in_x(0~1)，输出out_y
 * @param p0_x [in] p0_x
 * @param p0_y [in] p0_y
 * @param p1_x [in] p1_x
 * @param p1_y [in] p1_y
 * @param p2_x [in] p2_x
 * @param p2_y [in] p2_y
 * @param p3_x [in] p3_x
 * @param p3_y [in] p3_y
 * @param in_x [int] input percentage betweem [0, 1]
 * @param out_y [out] output value
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_interpolation_cubic_bezier_static(float p0_x,
                                            float p0_y,
                                            float p1_x,
                                            float p1_y,
                                            float p2_x,
                                            float p2_y,
                                            float p3_x,
                                            float p3_y,
                                            float in_x,
                                            float* out_y);

/**
 * @brief set rich text style by command, static api
 * @param width screen size width
 * @param height screen size height
 * @param type bef_InfoSticker_resolution_type for different screen size scaling logic adaptation parameters
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_model_control_set_resolution_info(unsigned int width,
     unsigned int height,
     bef_InfoSticker_resolution_type type);

/**
 * @brief set rich text style by command, static api
 * @param textID unique identifier for text segment
 * @param inParam struct for rich text param
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_model_control_set_rich_text(const char* textID,
     bef_info_sticker_edit_rich_text_param* inParam);

/**
 * @brief get rich text style by command, static api
 * @param textID unique identifier for text segment
 * @param inParam struct for rich text param
 * @param outParam struct for rich text param
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_model_control_get_rich_text(const char* textID,
    bef_info_sticker_edit_rich_text_param* inParam,
    bef_info_sticker_edit_rich_text_param** outParam);

/**
 * @brief release outParam which provided by effect, static api
 * @param outParam struct for rich text param
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_model_control_release_rich_text_out_param(
    bef_info_sticker_edit_rich_text_param* outParam);

#endif /* bef_swing_segment_static_api_h */
