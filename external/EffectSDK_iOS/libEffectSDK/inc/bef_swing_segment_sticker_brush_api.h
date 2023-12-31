/**
 * @file bef_swing_segment_sticker_brush_api.h
 * @author zhaolintong (zhaolintong@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2022-4-21
 *
 * @copyright Copyright (c) 2022
 *
 */

#ifndef bef_swing_segment_sticker_brush_api_h
#define bef_swing_segment_sticker_brush_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h"

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_load_brush_with_param(
    bef_swing_segment_t* segmentHandle,
    const char *brushStickerParams);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_load_brush_from_draft(
    bef_swing_segment_t* segmentHandle,
    const char* dstPath);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_set_brush_resource(
    bef_swing_segment_t* segmentHandle,
    const char *path,
    char **outParams);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_set_brush_resource_data(
    bef_swing_segment_t* segmentHandle,
    const char *path,
    const char *resourceId,
    char **outParams);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_set_texture_cache_path(
    bef_swing_segment_t* segmentHandle,
    const char* cachePath);


BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_get_texture_cache_total_mem_size(
    bef_swing_segment_t* segmentHandle,
    unsigned int* totalMemCache);


BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_get_texture_cache_total_cache_size(
    bef_swing_segment_t* segmentHandle,
    unsigned int* totalCacheSize);


BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_set_brush_params(
    bef_swing_segment_t* segmentHandle,
    const char* params);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_begin_brush(bef_swing_segment_t* segmentHandle);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_end_brush(bef_swing_segment_t* segmentHandle);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_undo_brush(bef_swing_segment_t* segmentHandle);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_redo_brush(bef_swing_segment_t* segmentHandle);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_clear_brush(bef_swing_segment_t* segmentHandle);

BEF_SDK_API  bef_effect_result_t bef_swing_segment_sticker_add_stroke_to_brush_sticker(
    bef_swing_segment_t* segmentHandle,
    bef_InfoSticker_texture* mask,
    bef_BoundingBox_2d* bbox,
    int flipMode);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_make_brush_sticker_to_snapshot(
    bef_swing_segment_t* segmentHandle,
    bef_info_sticker_brush_sticker_state* outState);

// same as bef_info_sticker_get_brush_state_fix_coord
BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_get_brush_state(
    bef_swing_segment_t* segmentHandle,
    bef_info_sticker_brush_sticker_state* outState,
    bool bboxCalculatedByPixel);

// texture save api, must use amazing-engine context. save brush texture to png file.
/**
 * @param segmentHandle         instance of swing segment
 * @param pngPath               png path
 * @param pFunc                 call back func
 * @return                      if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_brush_save_texture_to_png(
    bef_swing_segment_t* segmentHandle,
    const char* pngPath,
    bef_brush2d_save_png_callback pFunc,
    void* userData);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_brush_save_strokes_to_resource(
    bef_swing_segment_t* segmentHandle,
    const char* resourcePath,
    bef_brush2d_save_png_callback pFunc,
    void* userData);

// texture save api, must use amazing-engine context. save brush texture to png file.
/**
 * @param segmentHandle         instance of swing segment
 * @param error                 state of saveing texture, true is succ, false if fail.
 * @return                      if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_brush_get_texture_saving_state(
    bef_swing_segment_t* segmentHandle,
    bool* error);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_brush_get_visible_resource_list(
    bef_swing_segment_t* segmentHandle,
    char* resourceList
);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_brush_get_resource_list(
    bef_swing_segment_t* segmentHandle,
    char** resourceList,
    bool ignore_erased
);

BEF_SDK_API bef_effect_result_t bef_swing_segment_sticker_release_brush_resource_list(
    bef_swing_segment_t* segmentHandle,
    char* resourceList
);

#endif /* bef_swing_segment_sticker_brush_api_h */
