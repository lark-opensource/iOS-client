//
//  bef_effect_face_distortionV2.h
//  effect_sdk
//
//  Created by Saint Wang on 2018/9/26.
//

#ifndef bef_effect_face_distortionV2_h
#define bef_effect_face_distortionV2_h

#include "bef_effect_public_define.h"

typedef enum : int {
    VALUE_TYPE_TYPE,
    VALUE_TYPE_C_IDX1,
    VALUE_TYPE_C_IDX2,
    VALUE_TYPE_C_IDX3,
    VALUE_TYPE_C_LAMDA1,
    VALUE_TYPE_C_LAMDA2,
    VALUE_TYPE_RX_COORD,
    VALUE_TYPE_RX_IDX1,
    VALUE_TYPE_RX_IDX2,
    VALUE_TYPE_RX_SCALE,
    VALUE_TYPE_RY_COORD,
    VALUE_TYPE_RY_IDX1,
    VALUE_TYPE_RY_IDX2,
    VALUE_TYPE_RY_SCALE,
    VALUE_TYPE_ANGLE_TYPE,
    VALUE_TYPE_ANGLE_DIR_START_IDX,
    VALUE_TYPE_ANGLE_DIR_END_IDX,
    VALUE_TYPE_SCALE_X,
    VALUE_TYPE_SCALE_Y,
    VALUE_TYPE_RANGE_MIN,
    VALUE_TYPE_RANGE_MAX,
    VALUE_TYPE_SIGN_X,
    VALUE_TYPE_SIGN_Y,
    VALUE_TYPE_CURVE,
    VALUE_TYPE_T_IDX1,
    VALUE_TYPE_T_IDX2,
    VALUE_TYPE_T_IDX3,
    VALUE_TYPE_T_LAMDA1,
    VALUE_TYPE_T_LAMDA2,
    VALUE_TYPE_T_SCALE,
    VALUE_TYPE_EXT_S0_X,
    VALUE_TYPE_EXT_S0_Y,
    VALUE_TYPE_EXT_PX,
    VALUE_TYPE_EXT_PY,
    VALUE_TYPE_EXT_CURVE0_X,
    VALUE_TYPE_EXT_CURVE0_Y,
    VALUE_TYPE_EXT_CURVE1_X,
    VALUE_TYPE_EXT_CURVE1_Y
} bef_face_distortionV2_item_value_type;

/**
 * @brief           *** FOR STUDIO *** set FaceDistortionV2 value
 * @param handle    feature handle
 * @param index     distortion item index
 * @param valueType bef_face_distortionV2_item_value_type
 * @param value     value
 * @return          if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_face_distortionV2_set_value(bef_feature_handle_t handle, int index, int valueType, float value);

#endif /* bef_effect_face_distortionV2_h */
