//
//  bef_effect_sticker.h
//
//  Copyright © 2018 bytedance. All rights reserved.

#ifndef _BEF_EFFECT_STICKER_H_
#define _BEF_EFFECT_STICKER_H_

#include "bef_effect_public_define.h"

/**
 * @brief Create sticker handle
 * @param [out] handle Created beautfy handle
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_create(
  bef_effect_handle_t *handle
);

/**
 * @param [in] handle Destroy the created sticker handle
 */
BEF_SDK_API void
bef_effect_sticker_destroy(
  bef_effect_handle_t handle
);

/**
 * @brief Initialize sticker setting
 * @param [in] handle Created sticker handle
 * @param [in] width  Texture width
 * @param [in] height Texture height
 * @param [in] resourceFinder Get the path of the model file
 * @param [in] str_device_name ""
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_init_with_resource_finder(
        bef_effect_handle_t handle,
        int width,
        int height,
        bef_resource_finder resourceFinder,
        const char* str_device_name
);


/**
 * @brief Initialize sticker setting
 * @param [in] handle Created sticker handle
 * @param [in] width  Texture width
 * @param [in] height Texture height
 * @param [in] str_resource_dir Resource folder
 * @param [in] str_device_name ""
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_init(
  bef_effect_handle_t handle,
  int width,
  int height,
  const char *str_resource_dir,
  const char* str_device_name
);

/**
 * @brief Set the width and height of input texture
 * @param [in] handle Created sticker handle
 * @param [in] width  Texture width
 * @param [in] height Texture height
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_set_width_height(
  bef_effect_handle_t handle,
  int width,
  int height
);

/**
 * @brief Set effect with a specified string.
 * @param [in] handle Created sticker handle
 * @param [in] str_type_path The absolute path of effect package.
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_set_effect(
  bef_effect_handle_t handle, unsigned int stickerId, const char *strPath, int* reqId, BEFError *error
);

/**
 * @breif  Draw srcTexture with effects to dstTexture.
 * @param [in] handle Created sticker handle
 * @param [in] src_texture source texture
 * @param [in] dst_texture distination texture
 * @param [in] timestamp
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_process_texture(
  bef_effect_handle_t handle,
  unsigned int src_texture,
  unsigned int dst_texture,
  double timestamp
);

/**
 * @brief Get detection mode ?
 * @param [in] handle Created sticker handle
 * @return Detection mode, reference bef_effect_base_define.h for detail.
 */
BEF_SDK_API bef_effect_remark*
bef_effect_sticker_get_remark(
  bef_effect_handle_t handle
);

/**
 * @brief Get detection mode
 * @param [in] handle Created sticker handle
 * @return Detection mode, reference bef_effect_base_define.h for detail.
 */
BEF_SDK_API bef_algorithm_requirement
bef_effect_sticker_get_requirment(
  bef_effect_handle_t handle
);

/**
 * @brief Set maximal memory cache value
 * @param [in] handle Created sticker handle
 * @param [in] max_mem_cache Maximal cache value in MB
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_set_max_memcache(
  bef_effect_handle_t handle,
  unsigned int max_mem_cache
);

/**
 * @brief
 * @param [in] handle Created sticker handle
 * @param [in] algo_flag
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_refresh_algorithm(
  bef_effect_handle_t handle,
  bef_algorithm_requirement algo_flag
);

/**
 * Demo:
 *      bef_effect_create
 *      bef_effect_init
 *      bef_effect_refresh_algorithm(BEF_REQUIREMENT_BODY)
 *      bef_effect_set_body_dance_mode(SkeletonDetectModeBeforeRecordingStart)
 *      bef_effect_algorithm(cameraFrameData, delta time)
 * ```
 *
 * @param [in] handle Created sticker handle
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_algorithm_texture(
  bef_effect_handle_t handle,
  unsigned int src_textureid,
  double timestamp
);

/**
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_algorithm_buffer(
  bef_effect_handle_t handle,
  int width,
  int height,
  const unsigned char* image_data,
  bef_pixel_format pixformat,
  double timestamp
);

// More API

#endif // _BEF_EFFECT_STICKER_H_
