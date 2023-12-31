//
//  bef_effect_photo_face_detect.h
//
//  Copyright © 2018 bytedance. All rights reserved.
//

#ifndef _BEF_EFFECT_PHOTO_FACE_DETECT_H_
#define _BEF_EFFECT_PHOTO_FACE_DETECT_H_

#include "bef_effect_public_define.h"

// Config when creating detect handle
#define  BEF_PHOTO_E_INVALIDARG -1              ///< Invalid parameter
#define  BEF_PHOTO_E_HANDLE -2                  ///< Handle error
#define  BEF_PHOTO_E_OUTOFMEMORY -3             ///< Out of memory
#define  BEF_PHOTO_E_FAIL -4                    ///< Internal error
#define  BEF_PHOTO_E_DELNOTFOUND -5             ///< Missing definition
#define  BEF_PHOTO_E_INVALID_PIXEL_FORMAT -6    ///< Unsupported image format

//***************************** begin Create-Config *****************/
// Config when creating handle
#define BEF_PHOTO_INIT_LARGE_MODEL 0x00100000           ///< Initialization parameters, more accurate
#define BEF_PHOTO_INIT_SMALL_MODEL 0x00200000           ///< Initialization parameters, faster
//**************************** end of Create-Config *****************/

//***************************** begin Mode-Config ******************/
#define BEF_PHOTO_MOBILE_DETECT_MODE_VIDEO  0x00020000  ///< Video detection
#define BEF_PHOTO_MOBILE_DETECT_MODE_IMAGE  0x00040000  ///< Image detection
//***************************** enf of Mode-Config *****************/

//***************************** Begin Config-106 point and action **/
// for 106 key points detect
// NOTE open mouth, shadke head, nod, raise esybrows detection is enabled by default
#define BEF_PHOTO_MOBILE_FACE_DETECT      0x00000001
// Face action
#define BEF_PHOTO_MOBILE_EYE_BLINK        0x00000002  // Blink
#define BEF_PHOTO_MOBILE_MOUTH_AH         0x00000004  // Open mouth
#define BEF_PHOTO_MOBILE_HEAD_YAW         0x00000008  // Shake head
#define BEF_PHOTO_MOBILE_HEAD_PITCH       0x00000010  // nod
#define BEF_PHOTO_MOBILE_BROW_JUMP        0x00000020  // Raise eyebrows
#define BEF_PHOTO_MOBILE_MOUTH_POUT       0x00000040  // Duck face / pouts lips

#define BEF_PHOTO_MOBILE_DETECT_FULL      0x0000007F  // Detect all the above features

#define BEF_MOBILE_FACE_240_DETECT \
0x00000100  // Second-level key points: eyebrows, eyes, mouth
#define BEF_MOBILE_FACE_280_DETECT \
0x00000900  // Second-level key points: eyebrows, eyes, mouth, iris

typedef void* bef_effect_photo_face_detect_handle_t;
/**
 * @brief Create face detection handle
 * @param [in] config Config of face detect algorithm, should be BEF_PHOTO_INIT_LARGE_MODEL or BEF_PHOTO_INIT_SMALL_MODEL
 * @param [out] handle Created face detect handle
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_photo_face_detect_create(unsigned long long config, const char* strModeDir, bef_effect_photo_face_detect_handle_t *handle);

/**
 * @brief Create handle
 * 
 * @param handle 
 * @return BEF_SDK_API bef_effect_photo_detect_create_handle 
 */
BEF_SDK_API bef_effect_result_t bef_effect_photo_detect_create_handle(bef_effect_photo_face_detect_handle_t *handle);

/**
 * @brief Create handle
 *
 * @param handle
 * @return BEF_SDK_API bef_effect_photo_detect_create_handle
 */
bef_effect_result_t bef_effect_photo_detect_create_handle_with_gpdevice(bef_effect_photo_face_detect_handle_t *handle, gpdevice_handle gpdevice);

/**
 * @brief Initialize using resource finder
 * 
 * @param handle Face detection handle
 * @param resource_finder Resource finder
 * @param config e.g. TT_INIT_SMALL_MODEL|TT_MOBILE_DETECT_FULL|TT_MOBILE_DETECT_MODE_IMAGE）
 * @return BEF_SDK_API bef_Effect_photo_detect_init_with_resource_finder 
 */
BEF_SDK_API bef_effect_result_t bef_effect_photo_detect_init_with_resource_finder(bef_effect_photo_face_detect_handle_t handle, bef_resource_finder resource_finder,unsigned long long config);
/**
 * @brief Get the list of models required by the current face algorithm
 * 
 * @param outResourceNames List of required models
 * @param outLength Model list length
 * @return BEF_SDK_API bef_effect_photo_face_detect_pick_resources 
 */
BEF_SDK_API bef_effect_result_t bef_effect_photo_face_detect_pick_resources(const char*** outResourceNames,int* outLength);

/**
 * @brief Do face detect
 * @param [in] handle Created face detect handle
 * @param [in] imageTexture Image Texture ID
 * @param [in] pixel_format Pixel format of input image
 * @param [in] image_width  Image width
 * @param [in] image_height Image height
 * @param [in] image_stride Image stride in each row
 * @param [in] orientation Image orientation
 * @param [in] detect_config Config of face detect, for example, BEF_PHOTO_MOBILE_FACE_DETECT | BEF_PHOTO_MOBILE_EYE_BLINK
 * @param [in] p_face_info Data results of face detection
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_photo_face_detect(
  bef_effect_photo_face_detect_handle_t handle,
  unsigned int imageTexture,
  bef_pixel_format pixel_format,
  int image_width,
  int image_height,
  int image_stride,
  bef_rotate_type orientation,
  unsigned long long detect_config,
  bef_face_info *p_face_info
);

/**
 * @brief Face detection, return data results and face screenshots
 * @param [in] handle Created face detect handle
 * @param [in] imageTexture Image Texture ID
 * @param [in] pixel_format Pixel format of input image
 * @param [in] image_width  Image width
 * @param [in] image_height Image height
 * @param [in] image_stride Image stride in each row
 * @param [in] orientation Image orientation
 * @param [in] detect_config Config of face detect, for example, BEF_PHOTO_MOBILE_FACE_DETECT | BEF_PHOTO_MOBILE_EYE_BLINK
 * @param [in] p_face_image_infos Image and data results of face detection
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_photo_face_detect_and_clip(
                                                  bef_effect_photo_face_detect_handle_t handle,
                                                  unsigned int imageTexture,
                                                  bef_pixel_format pixel_format,
                                                  int image_width,
                                                  int image_height,
                                                  int image_stride,
                                                  bef_rotate_type orientation,
                                                  unsigned long long detect_config,
                                                  bef_photo_face_image_info_st *p_face_image_infos
                                                  );

/**
 * @brief Face detection, return data results and face screenshots
 * @param [in] handle Created face detect handle
 * @param [in] imageDeviceTexture Image Texture ID
 * @param [in] pixel_format Pixel format of input image
 * @param [in] image_width  Image width
 * @param [in] image_height Image height
 * @param [in] image_stride Image stride in each row
 * @param [in] orientation Image orientation
 * @param [in] detect_config Config of face detect, for example, BEF_PHOTO_MOBILE_FACE_DETECT | BEF_PHOTO_MOBILE_EYE_BLINK
 * @param [in] p_face_image_infos Image and data results of face detection
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_photo_face_detect_and_clip_device_texture(
                                                  bef_effect_photo_face_detect_handle_t handle,
                                                  device_texture_handle imageDeviceTexture,
                                                  bef_pixel_format pixel_format,
                                                  int image_width,
                                                  int image_height,
                                                  int image_stride,
                                                  bef_rotate_type orientation,
                                                  unsigned long long detect_config,
                                                  bef_photo_face_image_info_st *p_face_image_infos
                                                  );

bef_effect_result_t bef_effect_set_photo_render_api(bef_effect_photo_face_detect_handle_t handle, bef_render_api_type api);

BEF_SDK_API bef_effect_result_t
bef_effect_photo_face_detect_filter_policy(
                                  bef_effect_photo_face_detect_handle_t handle,
                                  bef_face_filter_policy_st filter_policy
                                  );

BEF_SDK_API void bef_effect_photo_face_detect_clear_textures(bef_effect_photo_face_detect_handle_t handle);

typedef enum {
  // Set how many frames to perform face detection every time (default is 24 when there is a face, 8 when there is no face), the larger the value, the lower the CPU usage, but the longer it takes to detect a new face.
  BEF_PHOTO_FACE_PARAM_FACE_DETECT_INTERVAL = 1, // default 30
  // Set the maximum number of faces that can be detected (default value N=10). Track the detected faces of N people until the number of faces is less than N and then continue to detect. The larger the value, the longer it will take.
  BEF_PHOTO_FACE_PARAM_MAX_FACE_NUM = 2, // default 10
  BEF_PHOTO_FACE_PARAM_MIN_DETECT_LEVEL = 3, // Dynamic adjustment can detect the size of the face. The video mode is forced to 4, and the picture mode can be set to 8 to detect smaller faces. The higher the detection level, the smaller the face can be detected. Value range: 4～10
  BEF_PHOTO_FACE_PARAM_BASE_SMOOTH_LEVEL = 4, //base debounce parameters[1-30]
  BEF_PHOTO_FACE_PARAM_EXTRA_SMOOTH_LEVEL = 5, //extra debounce parameters[1-30]
} bef_photo_face_detect_type;


/**
 * @brief Set face detect parameter based on type
 * @param [in] handle Created face detect handle
 * @param [in] type Face detect type that needs to be set, check bef_face_detect_type for the detailed
 * @param [in] value Type value, check bef_photo_face_detect_type for the detailed
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_photo_face_detect_setparam(
  bef_effect_photo_face_detect_handle_t handle,
  bef_photo_face_detect_type type,
  float value
);

BEF_SDK_API bef_effect_result_t bef_effect_photo_face_detect_set_output_size(bef_effect_photo_face_detect_handle_t handle, int size);

/**
 * @param [in] handle Destroy the created face detect handle
 */
BEF_SDK_API void
bef_effect_photo_face_detect_destroy(
  bef_effect_photo_face_detect_handle_t handle
);

#endif // _BEF_EFFECT_PHOTO_FACE_DETECT_H_
