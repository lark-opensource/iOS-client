//
//  bef_effect_global_filter.h
//
//  Copyright © 2018 bytedance. All rights reserved.

#ifndef _BEF_EFFECT_GLOCAL_FILTER_H_
#define _BEF_EFFECT_GLOCAL_FILTER_H_

#include "bef_effect_public_define.h"

/**
 * @brief Set color filter with a specified string
 * @param [in] handle Created filter handle
 * @param [in] str_filter_type_path Filter type path
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_global_filter_set_color_filter(
  bef_feature_handle_t handle,
  const char *str_filter_path
);

/**
 * @brief Setting when sliding to left and right
 * @param [in] handle Created filter handle
 * @param [in] left_filter_path  Filter resource path when sliding to left
 * @param [in] right_filter_path Filter resource path when sliding to right
 * @param [in] position The borderline of left filter and right filter in x-axis, range in [0, 1]
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_global_filter_switch_color_filter(
  bef_feature_handle_t handle,
  const char *left_filter_path,
  const char *right_filter_path,
  float position
);


#endif // _BEF_EFFECT_GLOCAL_FILTER_H_
