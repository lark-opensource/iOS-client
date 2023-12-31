
#ifndef _BEF_EFFECT_VIDEO_AFTER_EFFECT_H_
#define _BEF_EFFECT_VIDEO_AFTER_EFFECT_H_

#include "bef_effect_public_define.h"
#include <stdbool.h>

// Error Code
#define BEF_RESULT_ALG_VIDEO_AFTER_EFFECT_LOAD_FAIL    -1 // Failed to load aftereffect model
#define BEF_RESULT_ALG_VIDEO_AFTER_EFFECT_CREATE_FAIL  -2 // Failed to create aftereffect algorithm instance
#define BEF_RESULT_ALG_VIDEO_AFTER_EFFECT_DO_FAIL      -4 // Failed to execute aftereffect algorithm

#define BEF_RESULT_ALG_FACE_LOAD_FAIL                  -5 // Failed to load face model
#define BEF_RESULT_ALG_FACE_CREATE_FAIL                -6 // Failed to create face algorithm instance

#define BEF_RESULT_ALG_FACE_ATTR_LOAD_FAIL             -7 // Failed to load faceattr model
#define BEF_RESULT_ALG_FACE_ATTR_CREATE_FAIL           -8 // Failed to create faceattr algorithm instance

#define BEF_RESULT_ALG_VIDEO_AFTER_EFFECT_INVALID_FUNC -9  // Invalid bef_effect_video_after_effect_func_type
#define BEF_RESULT_ALG_VIDEO_AFTER_EFFECT_INVALID_ARGS -10 // The args parameter of bef_effect_video_after_effect_do is illegal
#define BEF_RESULT_ALG_VIDEO_AFTER_EFFECT_INVALID_RET  -11 // The ret parameter of bef_effect_video_after_effect_do is illegal
#if BEF_EFFECT_AI_LABCV_TOBSDK
#if (defined(__ANDROID__) || defined(TARGET_OS_ANDROID)) && (BEF_EFFECT_ANDROID_WITH_JNI)
#include <jni.h>
BEF_SDK_API bef_effect_result_t
bef_video_after_effect_check_license(JNIEnv* env, jobject context, 
                                     const char* licensePath);
#else
BEF_SDK_API bef_effect_result_t
bef_video_after_effect_check_license(const char* licensePath);
#endif
#endif
/**
 * @brief   Create after_effect handle
 * @param   [in]  handle          Effect instance handle
 * @param   [in]  resource_finder bef_resource_finder for loading models
 * @param   [out] after_handle    after_effect algorithm handle
 * @param   [out] face_handle     face algorithm handle
 * @param   [out] attr_handle     face attr algorithm handle
 * @param   [in]  use_face_attr   Whether to use face attribute detection
 * @return  If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_video_after_effect_create(
                                     bef_effect_handle_t handle,
                                     bef_resource_finder resource_finder,
                                     bef_effect_handle_t* after_handle,
                                     bef_effect_handle_t* face_handle,
                                     bef_effect_handle_t* attr_handle,
                                     bool use_face_attr
                                     );

// bef_effect_video_after_effect_do completed in three steps:

// 1.Calculate the frame moment to be extracted(ms)
// Input parameters:
// bef_effect_video_after_effect_args:
//      func_type
//      video_duration_ms
//
// Output result:
// bef_effect_video_after_effect_result：
//      frame_time_num
//      frame_time_ptr


// 2. Calculate the score of a frame (the extracted frames must be called once)
// Input parameters:
// bef_effect_video_after_effect_args：
//      func_type           k_video_after_effect_func_calc_score
//      base
//      time_stamp_ms
//
// Output result:
// bef_effect_video_after_effect_result：
//      score
//      face_score
//      quality_score
//      sharpness_score
// score = (face_score * 0.5 + quality_score + sharpness_score * 0.3) / 1.8


// 3. Get recommended frames and scores
// Input parameters:
// bef_effect_video_after_effect_args：
//      func_type           k_video_after_effect_func_get_cover_infos
//
// Output result:
// bef_effect_video_after_effect_result：
//      cover_num
//      cover_time_ptr
//      cover_score_ptr

// func_type
typedef enum
{
    k_video_after_effect_func_get_frame_times,
    k_video_after_effect_func_calc_score,
    k_video_after_effect_func_get_cover_infos
}bef_effect_video_after_effect_func_type;

// Only required if func_type is k_video_after_effect_func_calc_score
typedef struct bef_effect_video_after_effect_image_arg_st
{
    const unsigned char *image;
    bef_pixel_format pixel_format;
    int image_width;
    int image_height;
    int image_stride;
    bef_rotate_type orientation;
}bef_effect_video_after_effect_image_arg;

typedef struct bef_effect_video_after_effect_args_st
{
    bef_effect_video_after_effect_func_type func_type;
    bef_effect_video_after_effect_image_arg base;
    int video_duration_ms;
    int time_stamp_ms;
}bef_effect_video_after_effect_args;

typedef struct bef_effect_video_after_effect_result_st
{
    // Corresponding func_type = k_video_after_effect_func_get_frame_times
    int frame_time_num;
    int* frame_time_ptr;    // The first address of the frame to be extracted, the memory is managed internally by the SDK and contains frame_time_num elements

    // Corresponding func_type = k_video_after_effect_func_calc_score
    float score;            // Final score
    float face_score;
    float quality_score;
    float sharpness_score;

    // Corresponding func_type = k_video_after_effect_func_get_cover_infos
    int cover_num;          // The number of covers to be extracted
    int* cover_time_ptr;    // The first address of the recommended frame, the memory is managed internally by the SDK and contains cover_num elements
    float* cover_score_ptr; // The first address of the recommended frame score array, the memory is managed internally by the SDK, and contains cover_num elements
}bef_effect_video_after_effect_result;


BEF_SDK_API bef_effect_result_t
bef_effect_video_after_effect_do(bef_effect_handle_t handle,
                                 bef_effect_handle_t face_handle,
                                 bef_effect_handle_t attr_handle,
                                 const bef_effect_video_after_effect_args* args,
                                 bef_effect_video_after_effect_result* ret
                                 );


/**
 * @param [in] handle       Destroy after_effect handle
 * @param [in] face_handle  Destroy face_handle
 * @param [in] attr_handle  Destroy attr_handle
 */
BEF_SDK_API void
bef_effect_video_after_effect_destroy(
                                      bef_effect_handle_t handle,
                                      bef_effect_handle_t face_handle,
                                      bef_effect_handle_t attr_handle
                                      );

#endif // _BEF_EFFECT_VIDEO_AFTER_EFFECT_H_
