//
//  bef_effect_face_detect.h
//
//  Copyright © 2018 bytedance. All rights reserved.
//

#ifndef _BEF_EFFECT_FACE_DETECT_H_
#define _BEF_EFFECT_FACE_DETECT_H_

#include "bef_effect_public_define.h"

// Config when creating detect handle
#if BEF_EFFECT_AI_LABCV_TOBSDK
// TOB 与tob定义冲突，发现该宏值与AI_LAB定义不一致 暂时comment掉
//#define BEF_DETECT_LARGE_MODEL 0  // higher accuracy(More accurate)
//#define BEF_DETECT_SMALL_MODEL 1  // faster detection algorithm(Faster)
#else
#define BEF_DETECT_LARGE_MODEL 0  // higher accuracy(More accurate)
#define BEF_DETECT_SMALL_MODEL 1  // faster detection algorithm(Faster)
#endif
// Set detect mode
#define BEF_DETECT_MODE_VIDEO  0x00020000  // video detect
#define BEF_DETECT_MODE_IMAGE  0x00040000  // image detect

// Actioin definition
#define BEF_FACE_DETECT 0x00000001  // 106 key points face detect
#define BEF_EYE_BLINK   0x00000002  // eye blink
#define BEF_MOUTH_AH    0x00000004  // mouth open
#define BEF_HEAD_YAW    0x00000008  // shake head
#define BEF_HEAD_PITCH  0x00000010  // nod
#define BEF_BROW_JUMP   0x00000020  // wiggle eyebrow
#define BEF_MOUTH_POUT  0x00000040  // Duck face
#define BEF_DETECT_FULL 0x0000007F  // Detect all the above features

/**
 * @brief Create a face detection handle
 * @param [in] config Config of face detect algorithm, should be BEF_DETECT_LARGE_MODEL or BEF_DETECT_SMALL_MODEL
 * @param [out] handle Created face detect handle
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_face_detect_create(
  unsigned long long config,
  const char * strModeDir,
  bef_effect_handle_t *handle
);

/**
 * @brief Face Detection
 * @param [in] handle Created face detect handle
 * @param [in] image Image base address
 * @param [in] pixel_format Pixel format of input image
 * @param [in] image_width  Image width
 * @param [in] image_height Image height
 * @param [in] image_stride Image stride in each row
 * @param [in] orientation Image orientation, ref: bef_effect_base_define.h
 * @param [in] detect_config Config of face detect, for example, BEF_FACE_DETECT | BEF_DETECT_EYEBALL | BEF_BROW_JUMP
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_face_detect(
  bef_effect_handle_t handle,
  const unsigned char *image,
  bef_pixel_format pixel_format,
  int image_width,
  int image_height,
  int image_stride,
  bef_rotate_type orientation,
  unsigned long long detect_config,
  bef_face_info *p_face_info
);
#if BEF_EFFECT_AI_LABCV_TOBSDK
//typedef enum {
  // Set how many frames the tracker performs face detection every interval (the default value is 30 when there is a face, 10 when there is no face), the larger the value, the lower the CPU usage, but the longer it takes to detect a new face.
//  BEF_FACE_PARAM_FACE_DETECT_INTERVAL = 1, // default 30
  // Set the maximum number of faces that can be detected (default value N=10). Track the detected faces of N people until the number of faces is less than N and then continue to detect. The larger the value, the longer it will take.
//  BEF_FACE_PARAM_MAX_FACE_NUM = 2, // default 10
//} bef_face_detect_type;

#include "bef_effect_ai_face_detect.h"
#else
typedef enum {
  // Set how many frames the tracker performs face detection every interval (the default value is 30 when there is a face, 10 when there is no face), the larger the value, the lower the CPU usage, but the longer it takes to detect a new face.
  BEF_FACE_PARAM_FACE_DETECT_INTERVAL = 1, // default 30
  // Set the maximum number of faces that can be detected (default value N=10). Track the detected faces of N people until the number of faces is less than N and then continue to detect. The larger the value, the longer it will take.
  BEF_FACE_PARAM_MAX_FACE_NUM = 2, // default 10
} bef_face_detect_type;
#endif

/**
 * @brief Set face detect parameter based on type
 * @param [in] handle Created face detect handle
 * @param [in] type Face detect type that needs to be set, check bef_face_detect_type for the detailed
 * @param [in] value Type value, check bef_face_detect_type for the detailed
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_face_detect_setparam(
  bef_effect_handle_t handle,
  bef_face_detect_type type,
  float value
);

/**
 * @param [in] handle Destroy the created face detect handle
 */
BEF_SDK_API void
bef_effect_face_detect_destroy(
  bef_effect_handle_t handle
);


#endif // _BEF_EFFECT_FACE_DETECT_H_
