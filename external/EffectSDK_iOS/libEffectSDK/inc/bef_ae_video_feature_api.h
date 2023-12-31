#ifndef BEF_AE_VIDEO_FEATURE_API_H
#define BEF_AE_VIDEO_FEATURE_API_H

#include "bef_effect_public_define.h"
#include "bef_framework_public_base_define.h"

#define VIDEO_FEATURE_ALGORITHM_FORCE_DETECT "vide_feature_algorithm_force_detect"
#define VIDEO_FEATURE_ALGORITHM_TEXTURE_ORIENTATION "video_feature_algorithm_texture_orientation"

typedef void* bef_ae_feature_engine_handle;
typedef void* bef_ae_feature_handle;

/**
 * @brief   Create a amazing engine handle, support multiple instances, each instance takes an additional 5M of memory [render thread]
 * @param   [out] handle     Amazing engine handle
 * @param   [in]  width      Rendered width
 * @param   [in]  height     Rendered height
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_engine_create(bef_ae_feature_engine_handle* handle, unsigned int width, unsigned int height);

/**
 * @brief   Create a amazing engine handle, support multiple instances, each instance takes an additional 5M of memory [render thread]
 * @param   [out] handle     Amazing engine handle
 * @param   [in]  width      Rendered width
 * @param   [in]  height     Rendered height
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_engine_create_with_gpdevice(bef_ae_feature_engine_handle* handle, unsigned int width, unsigned int height, gpdevice_handle gpdevice);

/**
 * @brief   Create a amazing engine handle, support multiple instances, each instance takes an additional 5M of memory, with algorithm async option [render thread]
 * @param   [out] handle            Amazing engine handle
 * @param   [in]  width             Rendered width
 * @param   [in]  height            Rendered height
 * @param   [in]  algorithmAsync    is algorithm async
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_engine_create_with_algorithm_async(bef_ae_feature_engine_handle* handle, unsigned int width, unsigned int height, bool algorithmAsync);

#if BEF_EFFECT_AI_LABCV_TOBSDK
#if (defined(__ANDROID__) || defined(TARGET_OS_ANDROID)) && (BEF_EFFECT_ANDROID_WITH_JNI)
#include <jni.h>
BEF_SDK_API bef_effect_result_t
bef_ae_feature_check_license(JNIEnv* env, jobject context, bef_ae_feature_engine_handle handle, const char* licensePath);
BEF_SDK_API  bef_effect_result_t 
bef_ae_feature_check_license_buffer(JNIEnv* env, jobject context, bef_ae_feature_engine_handle handle, const char* buffer, unsigned long bufferLen);

#else
BEF_SDK_API bef_effect_result_t
bef_ae_feature_check_license(bef_ae_feature_engine_handle handle, const char* licensePath);
BEF_SDK_API bef_effect_result_t 
bef_ae_feature_check_license_buffer(bef_ae_feature_engine_handle handle, const char* buffer, unsigned long bufferLen);
#endif
#endif

/**
 * @brief Set aysnc preload count of animation sequerence
 *        The default value is 0, which means preloading disabled
 *        This value would be initialized by ABConfig in create interfaces on above
 * @param engine instance of AMGVideoFeatureManager
 * @param async_preload_count value of async preload count
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_engine_set_async_preload_count(bef_ae_feature_engine_handle engine,
                                              int async_preload_count);

/**
 * @brief   Set the width and height of the rendering[render thread]
 * @param   [out] handle     Amazing engine handle
 * @param   [in]  width      Rendered width
 * @param   [in]  height     Rendered height
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_engine_set_width_height(bef_ae_feature_engine_handle engine_handle, unsigned int width, unsigned int height);

/**
 * @brief   Set whether to enable low memory mode (such as releasing temporary rt) [render thread]
 * @param   [out] handle     Amazing engine handle
 * @param   [in]  enable     true: enable     false: disable
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_engine_set_low_memory_mode_enabled(bef_ae_feature_engine_handle engine_handle, bool enable);

/**
 * @brief   Set source video type
 * @param   [in] engine_handle      Amazing engine handle
 * @param   [in] type               0: normal source video; 1: image-created source video
 * @return  bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_engine_set_source_video_type(bef_ae_feature_engine_handle engine_handle, unsigned int type);

/**
 * @brief set source video mirror flag
 * 
 * @param [in] engine_handle    Amazing engine handle
 * @param [in] isMirror         0: source video is normal; 1: source video has been mirrored externally
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_engine_set_source_video_mirror(bef_ae_feature_engine_handle engine_handle, unsigned int isMirror);

/**
 * @brief   Load filter, after loading, the default order is 0, the same order value, first load priority rendering [render thread]
 * @param   [in]     engine_handle      Amazing engine handle
 * @param   [in/out] handle            feature handle. the value must be null, the new feature will be loaded; if the handle is not empty. Because the parameters are in/out, the handle must be initialized
 * @param   [in]     path              filter path
 */
BEF_SDK_API bef_effect_result_t
bef_ae_filter_feature_load(bef_ae_feature_engine_handle engine_handle,
                    bef_ae_feature_handle* handle,
                    const char *path);

/**
 * @brief   Load feature, after loading, the default order is 0, the same order value, first load priority rendering [render thread]
 * @param   [in]     engine_handle      Amazing engine handle
 * @param   [in/out] handle            feature handle. If the value is null, the new feature will be loaded; if the handle is not empty, the previous feature will be unloaded and the new feature will be loaded to implement the mutex logic. Because the parameters are in/out, the handle must be initialized
 * @param   [in]     path              feature path
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_load(bef_ae_feature_engine_handle engine_handle,
                    bef_ae_feature_handle* handle,
                    const char *path);

/**
 * @brief   Set feature rendering order [render thread]
 * @param   [in]  engine_handle     Amazing engine handle
 * @param   [in]  handle            feature handle
 * @param   [in]  order             Feature rendering order, the smaller the first rendering
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_set_order(bef_ae_feature_engine_handle engine_handle,
                         bef_ae_feature_handle handle,
                         int order);

/**
 * @brief   Set the time period for feature rendering [render thread]
 * @param   [in]  engine_handle     Amazing engine handle
 * @param   [in]  handle            feature handle
 * @param   [in]  start             Rendering start time
 * @param   [in]  end               Rendering end time
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_set_time(bef_ae_feature_engine_handle engine_handle,
                         bef_ae_feature_handle handle,
                         double start,
                         double end);

/**
 * @brief Set time offset for feature rendering [render thread]
 *        rendernig time are [start + start_offset, end - end_offset]
 *        offsets are 0 as default
 *        only use by Jianying Pro.
 * @param engine_handle [in] instance of AMGVideoFeatureManager
 * @param handle [in] instance of AMGVideoFeature
 * @param start_offset [in] absolute time offset
 * @param end_offset [in] absolute time offset
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_set_time_offset(bef_ae_feature_engine_handle engine_handle,
                               bef_ae_feature_handle handle,
                               double start_offset,
                               double end_offset);

/**
 * @brief   Update rendering feature [render thread]
 * @param   [in]  engine_handle     Amazing engine handle
 * @param   [in]  input_tex         input texture id
 * @param   [in]  output_tex        output texture id
 * @param   [in]  time              timestamp
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_update(bef_ae_feature_engine_handle engine_handle,
                      unsigned int input_tex,
                      unsigned int output_tex,
                      double time);

/**
 * @brief   Update rendering feature [render thread]
 * @param   [in]  engine_handle     Amazing engine handle
 * @param   [in]  input_device_tex         input texture
 * @param   [in]  output_device_tex        output texture
 * @param   [in]  time              timestamp
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_update_device_texture(bef_ae_feature_engine_handle engine_handle,
                      device_texture_handle input_device_tex,
                      device_texture_handle output_device_tex,
                      double time);

/**
 * @brief   unload feature [render thread]
 * @param   [in]  engine_handle Amazing engine handle
 * @param   [out] handle        feature handle
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_unload(bef_ae_feature_engine_handle engine_handle,
                        bef_ae_feature_handle* handle);

/**
 * @brief   Set feature parameters, such as intensity of brightness [render thread]
 * @param   [in]  engine_handle Amazing engine handle
 * @param   [in]  handle        feature handle
 * @param   [in]  params_json   Parameter json string
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_set_params(bef_ae_feature_engine_handle engine_handle,
                          bef_ae_feature_handle handle,
                          const char *params_json);

/**
 * @brief   Reset feature parameters
 * @param   [in]  engine_handle Amazing engine handle
 * @param   [in]  handle        feature handle
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_reset_params(bef_ae_feature_engine_handle engine_handle,
                          bef_ae_feature_handle handle);

/**
 * @brief   Get feature parameters corresponding to a certain key [render thread]
 * 
 * Note: note to be confused by bef_ae_feature_get_params in bef_ae_style.h
 * 
 * @param   [in]  engine_handle Amazing engine handle
 * @param   [in]  handle        feature handle
 * @param   [out]  params_key   Parameter key string. Must be freed by bef_ae_feature_free_params
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_get_feature_params(bef_ae_feature_engine_handle engine_handle,
                                  bef_ae_feature_handle handle,
                                  const char *param_key,
                                  char** out_param_value);

/**
 * @brief   Free param value string returned by bef_ae_feature_get_params (static method)
 * @param   [in]  params_key   Parameter string
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_free_params(char* params_str);

/**
 * @brief   destroy Amazing engine handle[render thread]
 * @param   [in]  engine_handle Amazing engine handle
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_engine_destroy(bef_ae_feature_engine_handle engine_handle);

/**
 * @brief   Set algorithm query
 * @param   [in]  engine_h      Amazing engine handle
 * @param   [in]  finder_h      query handle
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_init_algorithm(bef_ae_feature_engine_handle engine_h, bef_resource_finder finder_h);

/**
 * @brief   Is need  execute algorithm
 * @param   [in]  handle        Amazing engine handle
 *  * @param   [in]  time          timestamp, keep the same stamp with render texture
 * @return  Successful return
 *               BEF_RESULT_SUC (means need algorithm )
 *          Fail return
 *               BEF_RESULT_FAIL  (means no algorithm needed or error )
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_update_algorithm_requirement_and_graph_config(bef_ae_feature_engine_handle handle, double time);

/**
 * @brief   Get  algorithm need buffer width and height
 * @param   [in]  handle        Amazing engine handle
 * @param   [out] buffer_width   algorithm buffer width
 * @param   [out] buffer_heigt  algorithm buffer height
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_get_algorithm_width_height(bef_ae_feature_engine_handle handle, unsigned int *buffer_width, unsigned int *buffer_heigt);


/**
 * @brief   Update algorithm
 * @param   [in]  handle        Amazing engine handle
 * @param   [in]  input_idx     input texture id
 * @param   [in]  input_buffer     image buffer, buffer data format must be RGBA8888
 * @param   [in]  input_width   input buffer width
 * @param   [in]  input_height  input buffer height
 * @param   [in]  pixel_format  input buffer pixel format, just be RGBA8888 right now, other format need algorithm support later
 * @param   [in]  time          timestamp
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_algorithm_update_with_texture_or_buffer(bef_ae_feature_engine_handle handle, unsigned int input_idx, unsigned char* input_buffer, unsigned int input_width, unsigned int input_height, bef_pixel_format pixel_format, double time);

/**
 * @brief   Update algorithm
 * @param   [in]  handle        Amazing engine handle
 * @param   [in]  input_idx     input texture id
 * @param   [in]  input_width   input texture width
 * @param   [in]  input_height  input texture height
 * @param   [in]  time          timestamp
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_algorithm_update(bef_ae_feature_engine_handle handle, unsigned int input_idx, unsigned int input_width, unsigned int input_height, double time);

/**
 * @brief   Update algorithm
 * @param   [in]  handle        Amazing engine handle
 * @param   [in]  input_device_tex     input DeivceTexture
 * @param   [in]  input_width   input texture width
 * @param   [in]  input_height  input texture height
 * @param   [in]  time          timestamp
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_algorithm_update_device_texture(bef_ae_feature_engine_handle handle, device_texture_handle input_device_tex, unsigned int input_width, unsigned int input_height, double time);

/**
 * @brief   Set the parameters of the algorithm
 * @param   [in]  handle        Amazing engine handle
 * @param   [in]  params_json   Parameter json string
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_algorithm_set_params(bef_ae_feature_engine_handle handle, const char *params_json);

/**
 * @brief   enable
 * @param   [in]  engine_handle        Amazing engine handle
 * @param   [in]  handle               feature handle
 * @param   [in]  enable               true: enable     false: disable
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_set_enabled(bef_ae_feature_engine_handle engine_handle,
                           bef_ae_feature_handle handle,
                           bool enable);

/* *********** keyframe ********** */

/**
 * @brief   Set key frame (Create or update) [Render Thread]
 * @param   [in]  engine_handle         manager handle
 * @param   [in]  handle                        feature handle
 * @param   [in]  keyTime                      time(microsecond)
 * @param   [in]  valueJson                 key frame json(all prop)
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_set_key_frame(bef_ae_feature_engine_handle engine_handle,
                             bef_ae_feature_handle handle,
                             int64_t keyTime,
                             const char *valueJson);

/**
 * @brief   Remove key frame [Render Thread]
 * @param   [in]  engine_handle        manager handle
 * @param   [in]  handle                        feature handle
 * @param   [in]  keyTime                      time(microsecond)
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_remove_key_frame(bef_ae_feature_engine_handle engine_handle,
                                bef_ae_feature_handle handle,
                                int64_t keyTime);

/**
 * @brief   Remove all key frames [Render Thread]
 * @param   [in]  engine_handle        manager handle
 * @param   [in]  handle                        feature handle
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_remove_all_key_frames(bef_ae_feature_engine_handle engine_handle,
                                     bef_ae_feature_handle handle);

/**
 * @brief   Get key frame json [Render Thread]
 * @param   [in]  engine_handle         manager handle
 * @param   [in]  handle                         feature handle
 * @param   [in]  keyTime                       time(microsecond)
 * @param   [out]  valueJson                key frame json(all prop), must be released manually(free (*valueJson)), will  be NULL if there is no key frame
 * @return  Successful return
 *               BEF_RESULT_SUC
 *          Fail return
 *               reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_get_key_frame_params(bef_ae_feature_engine_handle engine_handle,
                                    bef_ae_feature_handle handle,
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
bef_ae_feature_free_key_frame_params(char **valueJson);

/* *********** keyframe ********** */

typedef int(*logMonitorFuncPointer)(const char* service, const char* log);
BEF_SDK_API bef_effect_result_t bef_ae_feature_set_log_monitor_func(logMonitorFuncPointer pfunc);
extern logMonitorFuncPointer g_logEditMonitorFileFunc;

/**
 * @brief Set VE color space.
 * @param engine_handle  manager handle
 * @param colorSpace  CSF_709_LINEAR = 0, CSF_709_NO_LINEAR = 1, CSF_2020_HLG_LINEAR = 2, CSF_2020_HLG_NO_LINEAR = 3,  CSF_2020_PQ_LINEAR = 4, CSF_2020_PQ_NO_LINEAR = 5
 */
BEF_SDK_API bef_effect_result_t bef_ae_feature_set_ve_colorspace(bef_ae_feature_engine_handle engine_handle, int colorSpace);

/**
 * @brief Set the update mode in current state.
 *        Available values: 0 - SEEK, 1 - UPDATE
 *        Default value is 0 - SEEK
 * @param engine_handle [in] VideoFeatureManager instance
 * @param mode [in] update mode
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_set_update_mode(bef_ae_feature_engine_handle engine_handle,
                                 int mode);

/**
 * @brief Load prefab resource
 * @param [in] engine_handle manager handle
 * @param [in] handle target feature handle
 * @param [in] paths  prefab resource path array
 * @param [in] count  path array size
 * @param [in] params_json Custom parameters
 */
BEF_SDK_API bef_effect_result_t
bef_ae_prefab_load(bef_ae_feature_engine_handle engine_handle,
                   bef_ae_feature_handle handle,
                   const char **paths,
                   const int32_t count,
                   const char *params_json);

/**
 * @brief Delete prefab resouce
 * @param [in] engine_handle manager handle
 * @param [in] handle target feature handle
 * @param [in] params_json Custom parameters
 */
BEF_SDK_API bef_effect_result_t
bef_ae_prefab_clear(bef_ae_feature_engine_handle engine_handle,
                    bef_ae_feature_handle handle,
                    const char *params_json);

/**
 * @brief   Set the time period for prefab in feature rendering [render thread]
 * @param   [in]  engine_handle     Amazing engine handle
 * @param   [in]  handle            feature handle
 * @param   [in]  start             Rendering start time
 * @param   [in]  end               Rendering end time
 * @param   [in]  params_json       Custom parameters
 */
BEF_SDK_API bef_effect_result_t
bef_ae_set_prefab_time(bef_ae_feature_engine_handle engine_handle,
                       bef_ae_feature_handle handle,
                       const double start,
                       const double end,
                       const char *params_json);

/**
 * @brief   Set the time period for prefab in feature rendering [render thread]
 * @param   [in]  engine_handle     Amazing engine handle
 * @param   [in]  handle            feature handle
 * @param   [in]  scaleX
 * @param   [in]  scaleY
 * @param   [in]  scaleZ
 * @param   [in]  params_json       Custom parameters
 */
BEF_SDK_API bef_effect_result_t
bef_ae_set_prefab_scale(bef_ae_feature_engine_handle engine_handle,
                        bef_ae_feature_handle handle,
                        const double scaleX,
                        const double scaleY,
                        const double scaleZ,
                        const char *params_json);

/**
 * @brief   Set the upper limit of animation sequence secondary cache
 * 
 * @param   [in]  cache_limit     upper limit of cache in bytes
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_set_anim_seq_cache_limit(int64_t cache_limit);

/**
 * @brief   set algorihtm cahce folder path
 * @param   [in]  engine_handle     Amazing engine handle
 * @param   [in]  params_json         Custom parameters, local path to cache folder
 */
BEF_SDK_API bef_effect_result_t
bef_ae_set_cache_folder_path(bef_ae_feature_engine_handle engine_handle,
                             const char *params_json);

 /**
 * @brief called by picture edit app such as XT, should be called after bef_ae_feature_init_algorithm at once
 * @param engine_handle              Amazing engine handle
 * @param pictureModeEnable          picture mode enable.
*/
BEF_SDK_API bef_effect_result_t bef_ae_active_xt_algorithm_config(bef_ae_feature_engine_handle engine_handle, bool pictureModeEnable);

#endif /* bef_ae_video_feature_api_h */
