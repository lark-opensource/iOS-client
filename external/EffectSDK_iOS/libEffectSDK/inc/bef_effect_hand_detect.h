//
//  bef_effect_face_detect.h
//
//  Copyright © 2018 bytedance. All rights reserved.
//

#ifndef _BEF_EFFECT_HAND_DETECT_H_
#define _BEF_EFFECT_HAND_DETECT_H_

#include "bef_effect_public_define.h"


/**
 * @brief Create a handle for hand detection
 * @param [out] handle Created hand detect handle
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_hand_detect_create(
    unsigned int max_hands_num,
    bef_hand_sdk_handle *handle
);

/**
 * @brief Perform detection
 * @param [in] handle Created hand detect handle
 * @param [in] image Image base address
 * @param [in] pixel_format Pixel format of input image
 * @param [in] image_width  Image width
 * @param [in] image_height Image height
 * @param [in] image_stride Image stride in each row
 * @param [in] orientation Image orientation
 * @param [in] detection_config Currently only HAND_MODEL_GESTURE_CLS and HAND_MODEL_KEY_POINT are optional
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_hand_detect(
  bef_hand_sdk_handle handle,
  const unsigned char *image,
  bef_pixel_format pixel_format,
  int image_width,
  int image_height,
  int image_stride,
  bef_rotate_type orientation,
  unsigned long long detection_config,
  bef_hand_info *p_hand_info
);


/**
 * @param [in] handle Destroy the created face detect handle
 */
BEF_SDK_API void
bef_effect_hand_detect_destroy(
  bef_hand_sdk_handle handle
);


#endif // _BEF_EFFECT_FACE_DETECT_H_
