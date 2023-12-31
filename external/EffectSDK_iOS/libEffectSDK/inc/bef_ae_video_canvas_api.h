#ifndef BEF_AE_VIDEO_CANVAS_API_H
#define BEF_AE_VIDEO_CANVAS_API_H

#include "bef_effect_public_define.h"
#include <stdbool.h>

typedef void* bef_ae_engine_handle;
typedef void* bef_ae_video_canvas_handle;

#if BEF_EFFECT_AI_LABCV_TOBSDK
#if (defined(__ANDROID__) || defined(TARGET_OS_ANDROID)) && (BEF_EFFECT_ANDROID_WITH_JNI)
#include <jni.h>
BEF_SDK_API bef_effect_result_t
bef_ae_engine_check_license(JNIEnv* env, jobject context, bef_ae_engine_handle handle, const char* licensePath);
#else
BEF_SDK_API bef_effect_result_t
bef_ae_engine_check_license(bef_ae_engine_handle handle, const char* licensePath);
#endif

#if (defined(__ANDROID__) || defined(TARGET_OS_ANDROID)) && (BEF_EFFECT_ANDROID_WITH_JNI)
#include <jni.h>
BEF_SDK_API bef_effect_result_t
bef_ae_engine_check_license_buffer(JNIEnv* env, jobject context, bef_ae_engine_handle handle, const char* license_buffer, int buffer_len);
#else
BEF_SDK_API bef_effect_result_t
bef_ae_engine_check_license_buffer(bef_ae_engine_handle handle, const char* license_buffer, int buffer_len);
#endif
#endif

/**
 * @brief   Create a amazing engine handle, support multiple instances, each instance takes an additional 5M of memory
 * @param   [out] handle    bef_ae_engine_handle handle
 * @param   [in]  width     Background texture pixel width
 * @param   [in]  height    Background texture pixel height
 */ 
BEF_SDK_API bef_effect_result_t
bef_ae_engine_create(bef_ae_engine_handle* handle, unsigned int width, unsigned int height);

/**
 * @brief   Create a amazing engine handle, support multiple instances, each instance takes an additional 5M of memory
 * @param   [out] handle    bef_ae_engine_handle handle
 * @param   [in]  width     Background texture pixel width
 * @param   [in]  height    Background texture pixel height
 */
BEF_SDK_API bef_effect_result_t
bef_ae_engine_create_with_gpdevice(bef_ae_engine_handle* handle, unsigned int width, unsigned int height, gpdevice_handle gpdevice);

/**
 * @brief   Set whether to enable low memory mode (such as releasing temporary rt) [render thread]
 * @param   [out] handle     amazing engine handle
 * @param   [in]  enable     true: enable     false: disable
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_set_low_memory_mode_enabled(bef_ae_engine_handle engine_handle, bool enable);

/**
 * @brief   Create a video canvas handle
 * @param   [in] engine_handle     amazing engine handle
 * @param   [out] handle           bef_ae_video_canvas_handle handle
 */ 
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_create(
    bef_ae_engine_handle engine_handle,
    bef_ae_video_canvas_handle* handle);

/**
 * @brief   Update adapt scale [Render Thread]
 * @param   [in]  engine_handle     manager handle
 * @param   [in]  handle            video canvas handle
 * @param   [in]  scale             adapt scale
 * @return  Succeed            BEF_RESULT_SUC
 *          Failure           Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_update_adapt_scale(bef_ae_engine_handle engine_handle,
                                       bef_ae_video_canvas_handle handle,
                                       float scale);

/**
 * @brief   Update video and background information(draw video_tex to bg_tex according to additional translation, scaling, rotation and flip information)
 * @param   [in]  engine_handle     amazing engine handle
 * @param   [in]  handle            video canvas handle
 * @param   [in]  bg_tex            Background texture id(output texture)
 * @param   [in]  video_tex         Video texture id
 * @param   [in]  bg_width          Background texture pixel width
 * @param   [in]  bg_height         Background texture pixel height
 * @param   [in]  video_width       Video texture pixel width
 * @param   [in]  video_height      Video texture pixel height
 * @param   [in]  x                 [-1, 1]
 * @param   [in]  y                 [-1, 1]
 * @param   [in]  angle             [0, 90, 180, 270]
 * @param   [in]  scale             1.0 indicates no scale
 * @param   [in]  flip_x            horizontal flip [Flip and rotate]
 * @param   [in]  flip_y            vertical flip [Flip and rotate]
 * @param   [in]  alpha             1.0 means completely opaque
 * @param   [in]  time              timeline time
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_update(bef_ae_engine_handle engine_handle,
                        bef_ae_video_canvas_handle handle,
                        unsigned int bg_tex,
                        unsigned int video_tex,
                        unsigned int bg_width,
                        unsigned int bg_height,
                        unsigned int video_width,
                        unsigned int video_height,
                        float x,
                        float y,
                        float angle,
                        float scale,
                        bool flip_x,
                        bool flip_y,
                        float alpha,
                        float time);

/**
 * @brief   Update video and background information(draw video_tex to bg_tex according to additional translation, scaling, rotation and flip information)
 * @param   [in]  engine_handle     amazing engine handle
 * @param   [in]  handle            video canvas handle
 * @param   [in]  bg_device_tex            Background texture(output texture)
 * @param   [in]  video_device_tex         Video texture
 * @param   [in]  bg_width          Background texture pixel width
 * @param   [in]  bg_height         Background texture pixel height
 * @param   [in]  video_width       Video texture pixel width
 * @param   [in]  video_height      Video texture pixel height
 * @param   [in]  x                 [-1, 1]
 * @param   [in]  y                 [-1, 1]
 * @param   [in]  angle             [0, 90, 180, 270]
 * @param   [in]  scale             1.0 indicates no scale
 * @param   [in]  flip_x            horizontal flip [Flip and rotate]
 * @param   [in]  flip_y            vertical flip [Flip and rotate]
 * @param   [in]  alpha             1.0 means completely opaque
 * @param   [in]  time              timeline time
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_update_device_texture(bef_ae_engine_handle engine_handle,
                        bef_ae_video_canvas_handle handle,
                        device_texture_handle bg_device_tex,
                        device_texture_handle video_device_tex,
                        unsigned int bg_width,
                        unsigned int bg_height,
                        unsigned int video_width,
                        unsigned int video_height,
                        float x,
                        float y,
                        float angle,
                        float scale,
                        bool flip_x,
                        bool flip_y,
                        float alpha,
                        float time);

/**
 * @brief   Set up video animation resources
 * @param   [in]  engine_handle amazing engine handle
 * @param   [in]  handle        bef_ae_video_canvas_handle handle
 * @param   [in]  anim_path     The path of the download animation resource, pass nullptr to cancel the animation
 * @param   [in]  start_time    Animation start time
 * @param   [in]  end_time      Animation end time
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_set_anim(bef_ae_engine_handle engine_handle,
                     bef_ae_video_canvas_handle handle,
                    const char* anim_path,
                    float start_time,
                    float end_time);

/**
 * @brief   Set up video animation resources with animType
 * @param   [in]  engine_handle amazing engine handle
 * @param   [in]  handle        bef_ae_video_canvas_handle handle
 * @param   [in]  anim_path     The path of the download animation resource, pass nullptr to cancel the animation
 * @param   [in]  anim_type     Animation type: in/out/combo-->1/2/3
 * @param   [in]  start_time    Animation start time
 * @param   [in]  end_time      Animation end time
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_set_anim_with_type(bef_ae_engine_handle engine_handle,
                     bef_ae_video_canvas_handle handle,
                    const char* anim_path,
                    uint32_t anim_type,
                    float start_time,
                    float end_time);

/**
 * @brief   Set params into 3D animation, you should call bef_ae_video_canvas_set_anim firstly. Not suitable for 2D animation
 * @param   [in]  engine_handle amazing engine handle
 * @param   [in]  handle        bef_ae_video_canvas_handle handle
 * @param   [in]  key           key of jsonObject. Only support "3DParams" now
 * @param   [in]  jsonObject    config with json object format
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_set_anim_params(bef_ae_engine_handle engine_handle,
                                      bef_ae_video_canvas_handle handle,
                                      const char* key,
                                      const char* jsonObject);

/**
 * @brief   Set Mixed Mode Resources
 * @param   [in]  engine_handle amazing engine handle
 * @param   [in]  handle        bef_ae_video_canvas_handle handle
 * @param   [in]  blend_path    The path of the download mixed-mode resources, pass NULL to use normal overlay mode
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_set_blend(bef_ae_engine_handle engine_handle,
                              bef_ae_video_canvas_handle handle,
                              const char* blend_path);

/**
 * @brief   Destroy the video canvas handle
 * @param   [in]  engine_handle amazing engine handle
 * @param   [in]  handle        Video animation handle
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_destory(bef_ae_engine_handle engine_handle, 
                        bef_ae_video_canvas_handle handle);

/**
 * @brief   Destroy the amazing engine handle
 * @param   [in]  engine_handle amazing engine handle
 */
BEF_SDK_API bef_effect_result_t
bef_ae_engine_destroy(bef_ae_engine_handle engine_handle);


/* *********** keyframe ********** */
/*
{
"position": [0, 0],                // Pos, normalized, -1~1
"scale": 1,                        // Scale
"rotation": 0,                     // Rotation, degree, counterclockwise
"alpha": 1
}
*/

/**
 * @brief   Set key frame (Create or update) [Render Thread]
 * @param   [in]  engine_handle         manager handle
 * @param   [in]  handle                        canvas handle
 * @param   [in]  keyTime                      time(microsecond)
 * @param   [in]  valueJson                 key frame json(all prop)
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_set_key_frame(bef_ae_engine_handle engine_handle,
                                  bef_ae_video_canvas_handle handle,
                                  int64_t keyTime,
                                  const char *valueJson);

/**
 * @brief   Remove key frame [Render Thread]
 * @param   [in]  engine_handle        manager handle
 * @param   [in]  handle                        canvas handle
 * @param   [in]  keyTime                      time(microsecond)
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_remove_key_frame(bef_ae_engine_handle engine_handle,
                                     bef_ae_video_canvas_handle handle,
                                     int64_t keyTime);

/**
 * @brief   Remove all key frames [Render Thread]
 * @param   [in]  engine_handle        manager handle
 * @param   [in]  handle                        canvas handle
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_remove_all_key_frames(bef_ae_engine_handle engine_handle,
                                          bef_ae_video_canvas_handle handle);

/**
 * @brief   Get key frame json [Render Thread]
 * @param   [in]  engine_handle         manager handle
 * @param   [in]  handle                         canvas handle
 * @param   [in]  keyTime                       time(microsecond)
 * @param   [out]  valueJson                key frame json(all prop), must be released manually(free (*valueJson)), will  be NULL if there is no key frame
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_get_key_frame_params(bef_ae_engine_handle engine_handle,
                                         bef_ae_video_canvas_handle handle,
                                         int64_t keyTime,
                                         char **valueJson);

/**
 * @brief   Release key frame json [Any thread]
 * @param   [in]  valueJson                key frame json
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_free_key_frame_params(char **valueJson);

/**
 * @brief   Interpolate a float value based on the start and end values ​​by percent
 * @param   [in]  start             Start value
 * @param   [in]  end               End value
 * @param   [in]  percent           Percent, 0.0f ~ 1.0f non-clamped
 * @param   [in]  curve             Curve json, reserved parameter, currently it is linear interpolation, curve not used
 * @param   [out] floatValue        Out float value
 * @return  success     BEF_RESULT_SUC
 *          fail        Reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_video_canvas_get_key_frame_float_value(float start, float end, float percent, const char* curve, float* floatValue);

/* *********** keyframe ********** */


#endif
