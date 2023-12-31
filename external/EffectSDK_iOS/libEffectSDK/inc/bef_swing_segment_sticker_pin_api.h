/**
 * @file bef_swing_segment_sticker_pin_api.h
 * @author yankai.ff (yankai.ff@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2021-11-11
 * 
 * @copyright Copyright (c) 2021
 * 
 */

#ifndef bef_swing_segment_sticker_pin_api_h
#define bef_swing_segment_sticker_pin_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_info_sticker_api.h" // bef_InfoSticker_*

/**
 * @brief sticker pin set selected area
 * @param segmentHandle instance of stick segment
 * @param param selected area params
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_set_selected_area(bef_swing_segment_t* segmentHandle,
                                                bef_InfoSticker_pin_selected_area_param* param);

/**
 * @brief sticker pin begin
 * @param segmentHandle instance of stick segment
 * @param param pin params(if param->initBuff.buff is empty, readPixels from EffectSDK, else, readPixels from external)
 * @param inputTextureId seek frame inputTexture, use before sticker texture to readPixels
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_begin(bef_swing_segment_t* segmentHandle,
                                    bef_swing_InfoSticker_pin_param* param,
                                    unsigned int inputTextureId);

/**
 * @brief sticker pin begin
 * @param segmentHandle instance of stick segment
 * @param param pin params(if param->initBuff.buff is empty, readPixels from EffectSDK, else, readPixels from external)
 * @param inputDeviceTex seek frame device texture handle, use before sticker texture to readPixels
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_begin_device_texture(bef_swing_segment_t* segmentHandle,
                                                   bef_swing_InfoSticker_pin_param* param,
                                                   device_texture_handle inputDeviceTex);

/**
 * @brief sticker pin end
 * @param segmentHandle instance of stick segment
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_end(bef_swing_segment_t* segmentHandle);

/**
 * @brief sticker pin cancel
 * @param segmentHandle instance of stick segment
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_cancel(bef_swing_segment_t* segmentHandle);

/**
 * @brief sticker pin set content info(video has black borders, set video content size)
 * @param segmentHandle instance of stick segment
 * @param info video content info
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_set_crop_content_info(bef_swing_segment_t* segmentHandle,
                                                    bef_InfoSticker_crop_content_info* info);

/**
 * @brief sticker pin get data
 * @param segmentHandle instance of stick segment
 * @param data The algorithm data using protobuf protocol may contain \0 in the middle, do not use string to read and write. The memory is released by the outside
 * @param size The size of data
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_get_data(bef_swing_segment_t* segmentHandle,
                                       void** data,
                                       int* size);

/**
 * @brief sticker pin set data
 * @param segmentHandle instance of stick segment
 * @param data The algorithm data using protobuf protocol may contain \0 in the middle, do not use string to read and write. The memory is released by the outside
 * @param size The size of data
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_set_data(bef_swing_segment_t* segmentHandle,
                                       const void* data,
                                       int size);

/**
 * @brief sticker pin set time
 * @param segmentHandle instance of sticker segment
 * @param timeStamp timeStamp for origin tracking, if timeStamp is -1.0 then not use that time , using seekFrame timeStamp
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_set_time(bef_swing_segment_t* segmentHandle,
                                       bef_swing_time_t timeStamp);

/**
 * @brief sticker pin get state
 * @param segmentHandle instance of sticker segment
 * @param state Sticker pin status
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_pin_get_state(bef_swing_segment_t* segmentHandle,
                                        bef_InfoSticker_pin_state* state);

#endif /* bef_swing_segment_sticker_pin_api_h */
