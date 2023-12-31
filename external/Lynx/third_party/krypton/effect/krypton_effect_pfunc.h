// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_CANVAS_EFFECT_PFUNC_H
#define LYNX_CANVAS_EFFECT_PFUNC_H

#include "bef_effect_api.h"
#include "bef_effect_composer.h"
#include "bef_effect_javascript_binding.h"
#include "bef_effect_touch_api.h"
#include "bef_slam_api.h"
#include "bef_slam_camera_api.h"

namespace lynx {
namespace canvas {
namespace effect {

#define DEFINE_EFFECT_FUNCS                                                 \
  DEFINE_FUNC(bef_effect_add_log_to_local_func_with_key)                    \
  DEFINE_FUNC(bef_effect_get_sdk_version)                                   \
  DEFINE_FUNC(bef_effect_create)                                            \
  DEFINE_FUNC(bef_effect_onPause)                                           \
  DEFINE_FUNC(bef_effect_send_msg)                                          \
  DEFINE_FUNC(bef_effect_onResume)                                          \
  DEFINE_FUNC(bef_effect_destroy)                                           \
  DEFINE_FUNC(bef_effect_init_with_resource_finder)                         \
  DEFINE_FUNC(bef_effect_init)                                              \
  DEFINE_FUNC(bef_effect_set_width_height)                                  \
  DEFINE_FUNC(bef_effect_set_device_rotation)                               \
  DEFINE_FUNC(bef_effect_set_orientation)                                   \
  DEFINE_FUNC(bef_effect_set_camera_device_position)                        \
  DEFINE_FUNC(bef_effect_set_beauty)                                        \
  DEFINE_FUNC(bef_effect_update_beauty)                                     \
  DEFINE_FUNC(bef_effect_set_reshape_face)                                  \
  DEFINE_FUNC(bef_effect_update_reshape_face)                               \
  DEFINE_FUNC(bef_effect_update_reshape_face_intensity)                     \
  DEFINE_FUNC(bef_effect_switch_color_filter_v2)                            \
  DEFINE_FUNC(bef_effect_set_color_filter_v2)                               \
  DEFINE_FUNC(bef_effect_update_color_filter)                               \
  DEFINE_FUNC(bef_effect_set_effect)                                        \
  DEFINE_FUNC(bef_effect_set_sticker)                                       \
  DEFINE_FUNC(bef_effect_process_texture)                                   \
  DEFINE_FUNC(bef_effect_algorithm_multi_texture_with_params)               \
  DEFINE_FUNC(bef_effect_process_texture_with_detection_data_and_timestamp) \
  DEFINE_FUNC(bef_effect_set_buildChain_flag)                               \
  DEFINE_FUNC(bef_effect_set_intensity)                                     \
  DEFINE_FUNC(bef_effect_set_max_memcache)                                  \
  DEFINE_FUNC(bef_effect_get_face_detect_result)                            \
  DEFINE_FUNC(bef_effect_get_skeleton_detect_result)                        \
  DEFINE_FUNC(bef_effect_get_hand_detect_result)                            \
  DEFINE_FUNC(bef_effect_use_TT_facedetect)                                 \
  DEFINE_FUNC(bef_effect_set_external_new_algorithm)                        \
  DEFINE_FUNC(bef_effect_config_ab_value)                                   \
  DEFINE_FUNC(bef_effect_composer_set_mode)                                 \
  DEFINE_FUNC(bef_effect_composer_set_nodes)                                \
  DEFINE_FUNC(bef_effect_composer_update_node)                              \
  DEFINE_FUNC(bef_effect_composer_reload_nodes)                             \
  DEFINE_FUNC(bef_effect_composer_append_nodes)                             \
  DEFINE_FUNC(bef_effect_composer_remove_nodes)                             \
  DEFINE_FUNC(bef_effect_process_touchEvent)                                \
  DEFINE_FUNC(bef_effect_process_scaleEvent)                                \
  DEFINE_FUNC(bef_effect_process_rotationEvent)                             \
  DEFINE_FUNC(bef_effect_process_pan_event)                                 \
  DEFINE_FUNC(bef_effect_process_long_press_event)                          \
  DEFINE_FUNC(bef_effect_process_double_click_event)                        \
  DEFINE_FUNC(bef_effect_process_touch_down_event)                          \
  DEFINE_FUNC(bef_effect_get_general_algorithm_result)                      \
  DEFINE_FUNC(bef_effect_process_touch_up_event)                            \
  DEFINE_FUNC(bef_effect_javascript_binding_engine)                         \
  DEFINE_FUNC(bef_effect_javascript_set_download_model_fuc)                 \
  DEFINE_FUNC(bef_effect_javascript_set_download_sticker_fuc)               \
  DEFINE_FUNC(bef_effect_javascript_set_resource_finder)                    \
  DEFINE_FUNC(bef_effect_javascript_set_gl_save_func)                       \
  DEFINE_FUNC(bef_effect_javascript_set_gl_restore_func)                    \
  DEFINE_FUNC(bef_effect_javascript_set_url_translate_func)                 \
  DEFINE_FUNC(bef_effect_javascript_set_get_texture_func)                   \
  DEFINE_FUNC(bef_effect_javascript_set_before_update_func)                 \
  DEFINE_FUNC(bef_effect_javascript_set_after_update_func)                  \
  DEFINE_FUNC(bef_effect_remove_log_to_local_func_with_key)

#if !TARGET_IPHONE_SIMULATOR
#define DEFINE_FUNC(name) extern decltype(::name) *name##_local;
DEFINE_EFFECT_FUNCS
#undef DEFINE_FUNC
#endif

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_CANVAS_EFFECT_PFUNC_H
