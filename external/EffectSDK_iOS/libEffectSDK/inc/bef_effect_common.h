//
//  bef_effect_common.h
//  byted-effect-sdk
//
//  Created by byte_dance on 01/09/2017.
//  Copyright © 2017 byte_dance. All rights reserved.
//

#ifndef bef_effect_common_h
#define bef_effect_common_h

#include "bef_effect_public_define.h"

/**
 * @brief Create effect handle, support filters, beauty, 2D stickers
 * @param [out] handle Effect handle
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */

BEF_SDK_API bef_effect_result_t
bef_effect_create(
  bef_effect_handle_t *handle/*, bool bUseAmazing*/
);

/**
 * @brief Initialize effect handle.
 * @param [in] handle Created effect handle
 * @param [in] width  Texture width
 * @param [in] height Texture height
 * @param str_mode_dir Absolute path of the directory where the algorithm model file is located, if not, pass ""
 * @param device_name  ""
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
// TODO remove device_name param
BEF_SDK_API bef_effect_result_t
bef_effect_init(
  bef_effect_handle_t handle,
  int width,
  int height,
  const char* str_mode_dir,
  const char* device_name
);

/**
 * @brief Add feature into effect, support filters, beauty, 2D stickers
 * @param [in] handle  Effect handle
 * @param [in] feature_types   Feature type
 * @param [out] feature_handle Feature handle
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_add_feature(
  bef_effect_handle_t handle,
  const char* feature_types,
  bef_feature_handle_t* feature_handle
);

/**
 * @brief Delete feature handle
 * @param [in] handle Feature handle
 */
BEF_SDK_API void
bef_effect_delete_feature(
  bef_feature_handle_t handle
);

/**
 * @brief Get feature handle
 * 
 * @param handle Effect handle
 * @param feature_types Feature types
 * @param feature_handle Feature handle
 * @return BEF_SDK_API bef_effect_get_feature 
 */
BEF_SDK_API bef_effect_result_t
bef_effect_get_feature(
                         bef_effect_handle_t handle,
                         const char* feature_types,
                         bef_feature_handle_t* feature_handle
                         );

/**
 * @brief Get feature pointer by feature handle
 */
bef_effect_result_t
byted_get_feature_pointer_by_handle(
                       bef_feature_handle_t handle,
                       void** feature_handle
                            );


/**
 * @brief Set frame size.
 * @param [in] handle Effect handle
 * @param [in] width  Texture width
 * @param [in] height Texture height
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_set_width_height(
  bef_effect_handle_t handle,
  int width,
  int height
);

/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param [in] handle     Effect handle
 * @param [in] srcTexture source texture
 * @param [in] dstTexture destination texture
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_process_texture(
  bef_effect_handle_t handle,
  unsigned int src_texture,
  unsigned int dst_texture,
  double timestamp
);

/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param [in] handle     Effect handle
 * @param [in] srcDeviceTexture source texture
 * @param [in] dstDeviceTexture destination texture
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_process_texture_device_texture(
  bef_effect_handle_t handle,
  device_texture_handle src_device_texture,
  device_texture_handle dst_device_texture,
  double timestamp
);

/**
 * @brief Destroy effect handle
 */
BEF_SDK_API void
bef_effect_destroy(
  bef_effect_handle_t handle
);

/**
 * @brief Set device rotation, which is used to operate geometries.
 * @param handle      Effect handle that  initialized
 * @param quaternion  device quaternion
 * @return            if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
// TODO bef_effect_sticker_set_device_rotation -> bef_effect_set_device_rotation
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_set_device_rotation(
  bef_effect_handle_t handle,
  float *quaternion,
                                       double timestamp
);

/**
 * @brief Set camera orientation, which is used for detection.
 * @param handle      Effect handle that  initialized
 * @param orientation  Camera clock wise
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_sticker_set_orientation(
  bef_effect_handle_t handle,
  bef_rotate_type orientation
);

/**
 * @brief Set camera toward
 * @param handle        Effect handle that  initialized
 * @param position      Camera positin
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_set_camera_device_position(
  bef_effect_handle_t handle,
  bef_camera_position position
);

/**
 * @param [in] handle Created feature handle
 * @param [in] bef_intensity_type ref: bef_effect_base_define.h
 * @param [in] intensity Intensity, range in [0, 1]
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_set_param(
  bef_feature_handle_t handle,
  bef_intensity_type type,
  float intensity
);


#endif /* bef_effect_common_h */
