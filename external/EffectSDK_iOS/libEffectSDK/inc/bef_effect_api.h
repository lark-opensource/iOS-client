//
//  bef_effect_api.h
//  byted-effect-sdk
//
//  Created by bytedance on 01/09/2017.
//  Copyright © 2017 bytedance. All rights reserved.
//

#ifndef bef_effect_api_h
#define bef_effect_api_h

#include "bef_effect_public_define.h"
#include "bef_effect_audio_effect.h"
#include "bef_effect_hand_detect.h"
#include <stdbool.h>

/**
 * @brief get effect version.
 * @param version     a char array used for Effect version.
 * @param size        size of char array "version"
 * @return            If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_sdk_version(char* version, const int size);
/**
 * @brief get effect commit.
 * @param commit      a char array used for Effect commit.
 * @param size        size of char array "commit" 
 * @return            If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_sdk_commit(char* commit, const int size);

/**
 * @brief Create effect handle.
 * @param handle      Effect handle that will be created.
 * @return            If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_create(bef_effect_handle_t *handle/*, bool bUseAmazing*/);

/**
 * @brief Create effect handle.
 * @param handle      Effect handle that will be created.
 * @param useAmazing  Effect if using Amazing Engine
 * @return            If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_create_handle(bef_effect_handle_t *handle, bool useAmazing);

/**
 * @param handle      Effect handle that will  destroy
 */
BEF_SDK_API void bef_effect_destroy(bef_effect_handle_t handle);

#if defined(__ANDROID__) || defined(TARGET_OS_ANDROID)
/**
 * @brief Setup an AssetManager handle with specific effect handle. This function must be called before bef_effect_init.
 * @param handle       Effect handle
 * @param assetManager AssetManager handle
 * @return             If succeed return BEF_EFFECT_RESULT_SUC. If the handle is null or has already initialized,
 *                     return BEF_EFFECT_RESULT_INVALID_EFFECT_HANDLE.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_asset_handler(bef_effect_handle_t handle, void* assetManager);
#endif

/**
 * @brief Receive Settings config from app client. This function must be called immediately after bef_effect_create_handle.
 * 
 * @param handle             Effect handle
 * @param platformConfig     Settings config. It is a Json string.
 * @return                   if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_platform_config(bef_effect_handle_t handle, const char* platformConfig);

/**
 * @brief Create function pointer to resolve model file path
 * @param handle        Effect handle
 * @param strModelDir   Resource folder
 * @return              Function pointer to a function that returns the absolute path to given dir and name, under strModelDir
 */
BEF_SDK_API bef_resource_finder bef_create_file_resource_finder(bef_effect_handle_t handle, const char *strModelDir);

#if defined(__ANDROID__) || defined(TARGET_OS_ANDROID)
BEF_SDK_API bef_resource_finder bef_create_asset_resource_finder(bef_effect_handle_t handle, void* assetManager, const char* strModelDir);
#endif

/**
 * @brief Initialize effect handle.
 * @param handle     Effect handle
 * @param width      Texture width
 * @param height     Texture height
 * @param resource_finder Function pointer to resolve model file path
 * @return           If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_init_with_resource_finder(bef_effect_handle_t handle,
                                                                    int width, int height,
                                                                    bef_resource_finder resource_finder,
                                                                    const char *deviceName);

/**
 * @brief Initialize effect handle.
 * @param handle     Effect handle
 * @param width      Texture width
 * @param height     Texture height
 * @param resource_finder Function pointer to resolve model file path
 * @return           If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_init_with_resource_finder_and_gpdevice(bef_effect_handle_t handle,
                                                                    int width, int height,
                                                                    bef_resource_finder resource_finder,
                                                                    const char *deviceName,
                                                                    gpdevice_handle gpdevice);

/**
 * @brief Initialize effect handle.
 * @param handle     Effect handle
 * @param width      Texture width
 * @param height     Texture height
 * @param resource_finder Function pointer to resolve model file path
 * @param resource_finder_releaser Function pointer to free resource_finder result
 * @return           If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_init_with_resource_finder_v2(bef_effect_handle_t handle,
                                                                    int width, int height,
                                                                    bef_resource_finder          resource_finder,
                                                                    bef_resource_finder_releaser resource_finder_releaser,
                                                                    const char *deviceName);

/**
 * @brief Peek resources needed by specified requirements
 *        This function is used internally, do not call from outside.
 *
 * @param requirements            Requirement array, can not be NULL. e.g. ["faceDetect", "petFaceDetect"]
 * @param requirementsLength      Length of requirement array, e.g. 2
 * @param outResourceNames        Resource names array needed by requirements. e.g. ["ttfacemodel/tt_face_v5.0.model", "petfacemodel/petface_v2.4.model"]
 * @param outLength               Length of out resource names, e.g. 2
 * @return                        If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_peek_resources_needed_by_requirements(const char** requirements,
                                                                                 const int requirementsLength,
                                                                                 const char*** outResourceNames,
                                                                                 int* outLength);
/*
 * @brief Free result of bef_effect_peek_resources_needed_by_requirements
 * @param resourceNames bef_effect_peek_resources_needed_by_requirements outResourceNames
 * @param length        bef_effect_peek_resources_needed_by_requirements outLength
 */
BEF_SDK_API void bef_effect_free_peek_resources_result(const char** resourceNames, int length);

/**
 * @brief Set the share resource directory of the amazing engine
 * @param handle          Effect instance handle
 * @param strShareDir     Share resource directory (absolute path)
 * @return          Successfully return BEF_EFFECT_RESULT_SUC, otherwise see bef_effect_define.h for errors.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_amazing_share_dir(bef_effect_handle_t handle, const char *strShareDir);

/**
 * @brief Initialize effect handle.
 * @param handle     Effect handle
 * @param width      Texture width
 * @param height     Texture height
 * @param strModeDir  Resource folder
 * @return           If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_init(bef_effect_handle_t handle, int width, int height, const char *strModeDir, const char* deviceName);

/**
 * @brief Initialize MessageCenter.
 * @return           If succeed return BEF_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_message_center_init();

/**
 * @brief Initialize effect handle.
 * @param handle     Effect handle
 * @param width      Texture width
 * @param height     Texture height
 * @param strModeDir  Resource folder
 * @return           If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_init_with_gpdevice(bef_effect_handle_t handle, int width, int height, const char *strModeDir, const char* deviceName, gpdevice_handle gpdevice);

/**
 * @brief Set render api
 * @param handle     Effect handle
 * @param api render api  gles20:0 gles30
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_render_api(bef_effect_handle_t handle, bef_render_api_type api);

/**
* @brief Set whether to use the new audio sdk api. Not used by default
* @param handle effect handle
* @param useNewAudioSdkApi True is used, false is not used
*/
BEF_SDK_API bef_effect_result_t bef_effect_set_use_new_audiosdk_api(bef_effect_handle_t handle, bool useNewAudioSdkApi);

/**
 * @brief Turn the parallel framework on or off, and the algorithm completes the detection in an independent thread after it is turned on. Not enabled by default
 * @param handle effect handle
 * @param usePipeline True is used, false is not used
 */
BEF_SDK_API bef_effect_result_t bef_effect_use_pipeline_processor(bef_effect_handle_t handle, bool usePipeline);

/**
 * @brief set sync input
 * @param handle     Effect handle
 * @param useSyncInput sync input flag
 */
BEF_SDK_API bef_effect_result_t bef_effect_use_sync_input(bef_effect_handle_t handle, bool useSyncInput);

/**
 * @brief Turn on or off the 3buffer strategy of the parallel framework
 * @param handle effect handle
 * @param use3Buffer True is enable, false is not disable
 */
BEF_SDK_API bef_effect_result_t bef_effect_use_pipeline_3_buffer(bef_effect_handle_t handle, bool use3Buffer);

/**
 * @brief Turn on or off the fence strategy of the parallel framework
 * @param handle effect handle
 * @param usefence True is enable, false is not disable
 */
BEF_SDK_API bef_effect_result_t bef_effect_use_gles3_fence(bef_effect_handle_t handle, bool usefence);

/**
 * @brief Turn the parallel framework on or off, and the algorithm completes the detection in an independent thread after it is turned on. Not enabled by default
 * @param handle effect handle
 * @param colorSpace  CSF_709_LINEAR = 0, CSF_709_NO_LINEAR = 1, CSF_2020_HLG_LINEAR = 2, CSF_2020_HLG_NO_LINEAR = 3,  CSF_2020_PQ_LINEAR = 4, CSF_2020_PQ_NO_LINEAR = 5
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_ve_colorspace(bef_effect_handle_t handle, int colorSpace);

/**
 * @brief Turn the amazing engine built-in effect on or off
 * @param handle     Effect handle
 * @param useAmazingBuiltin True is enable, false is not disable
 */
BEF_SDK_API bef_effect_result_t bef_effect_use_amazing_builtin(bef_effect_handle_t handle, bool useAmazingBuiltin);
 
 /**
 * @brief Clean up the residual algorithm tasks of the parallel framework, used when switching the background or switching the resolution. It will also be called automatically when the camera is switched
 * @param handle     Effect handle
 */
BEF_SDK_API bef_effect_result_t bef_effect_clean_pipeline_processor_task(bef_effect_handle_t handle);

/**
 * @brief pause effect handle.
 * @param handle     Effect handle
 * @param type       pause type, ref: bef_framework_public_constant_define.h
 */
BEF_SDK_API void bef_effect_onPause(bef_effect_handle_t handle, int type);

/**
 * @brief resume effect handle.
 * @param handle     Effect handle
 * @param type       pause type, ref: bef_framework_public_constant_define.h
 */
BEF_SDK_API void bef_effect_onResume(bef_effect_handle_t handle, int type);

/**
 * @brief Set AmazingEngine audio mute status
 * @param handle     Effect handle
 * @param needMuted    whether need to mute
 */
BEF_SDK_API void bef_effect_set_amazing_mute_status(bef_effect_handle_t handle, bool needMuted);

#ifdef AMAZING_EDITOR_SDK
/**
 * @brief update dual instance
 * @param handle     Effect handle
 */
BEF_SDK_API bef_effect_result_t bef_effect_updateDualInstance(bef_effect_handle_t handle);
#endif

/**
 * @brief Set frame size.
 * @param handle      Effect handle
 * @param width       Texture width
 * @param height      Texture height
 * @return            If succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_width_height(bef_effect_handle_t handle, int width, int height);

/**
 * @brief Set device quaternion available status, which is used for detection.
 * @param handle      Effect handle that  initialized
 * @param isAvailable Available status
 * @return            if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_device_rotation_available(bef_effect_handle_t handle, bool isAvailable);

/**
 * @brief Set device rotation, which is used to operate geometries.
 * @param handle      Effect handle that  initialized
 * @param quaternion  device quaternion
 * @return            if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_device_rotation(bef_effect_handle_t handle, float *quaternion);


/**
 * @brief Set device rotation, which is used to operate geometries.
 * @param handle      Effect handle that  initialized
 * @param quaternion  device quaternion
 * @param timestamp   time stamp
 * @return            if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_device_rotation_timestamp(bef_effect_handle_t handle, float *quaternion,double timestamp);

/**
 * @brief Set camera  orientation, which is used for detection.
 * @param handle      Effect handle that  initialized
 * @param orientation Camera clock wise
 * @return            if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_orientation(bef_effect_handle_t handle, bef_rotate_type deviceOrientation);

/**
 * @brief Set frame to device orientation.
 * @param handle      Effect handle that initialized
 * @param orientatoin Frame to device clockwise yaw angle
 * @return            if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_frame_device_orientation(bef_effect_handle_t handle, bef_rotate_type orientation);

/**
 * @brief get resource tag info for client, indicate view support type.
 * @param handle      Effect handle that initialized
 * @param featureList resource featuresList
 * @Param tag  a pointer to get tag info string, memory not less than 40 bytes, and caller is responsible for memory allocation/free.
 * @return            if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_resource_multiview_tag(bef_effect_handle_t handle, const char* featureList, char* tag);

/**
 * @brief set the safe area of the the effect texture, use normalized coordinate to describe the safe are rect, currently only support IF UI. This interface need to be call after set_width_height() and before process_texture().
 * @param handle Effect Handle that initialized
 * @param viewType 0: camera view. 1: editor view. Currently only support camera view
 * @param safe_area[] safe_area list. If the safeAreaList is nullptr, indices set safe area to full view.
 * @param size list size. If the size is 0, indicates set the safe area to full view.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_safe_area(bef_effect_handle_t handle, int viewType, bef_safe_area safeAreaList[], unsigned int size);

/**
 * @brief Set camera pose.
 * @param handle        Effect handle that  initialized
 * @param pos           Camera pose
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_camera_pose(bef_effect_handle_t handle, const bef_matrix4x4 *pose);

/**
 * @brief Set status of external tracker.
 * @param handle        Effect handle that  initialized
 * @param pos           Status of external tracker
 * 0: tracking result are valid, 1: tracking result has some error, 2: tracking result is unusable at all.
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_set_tracking_status(bef_effect_handle_t handle, int trackingStatus);

/**
 * @brief Set count of raw feature points.
 * @param handle        Effect handle that  initialized
 * @param pos           Count of raw feature points
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_set_raw_feature_points_count(bef_effect_handle_t handle, int rawFeaturePointsCount);

/**
 * @brief Set camera fov.
 * @param fovx      Camera fovx
 * @param fovy      Camera fovy
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_camera_fov(float fovx, float fovy);

/**
 * @brief Set camera intrinsic.
 * @param intrinsic     Camera intrinsic
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_camera_intrinsic(const bef_camera_intrinsic *intrinsic);

/**
 * @brief Set camera toward
 * @param handle        Effect handle that  initialized
 * @param position      Camera positin
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_camera_device_position(bef_effect_handle_t handle,  bef_camera_position position);

/**
 * @brief Setup beauty-face-filter with a specified string.
 * @param handle        Effect handle
 * @param strBeautyName The name of beauty will apply
 * @param bUseAmazing   use amazing engine?
 * @return              If succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_beauty(bef_effect_handle_t handle, const char *strBeautyName);

/**
 * @brief Setup beauty-face-filter with a specified string.
 * @param handle      Effect handle
 * @param strMakeupName The path of makeup resource will apply
 * @return            If succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_buildin_makeup(bef_effect_handle_t handle, const char* strMakeupName);

/**
 * @brief Setup hdrConfigPath with a specified string.
 * @param handle      Effect handle
 * @param hdrConfigDir The dir of hdrnet resource will apply，pass "" to disable HDR
 * @return            If succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_buildin_hdr(bef_effect_handle_t handle, const char* hdrConfigDir);

/**
 * @brief Setup night-mode-filter with a specified string.
 * @param handle      Effect handle
 * @param night_type  The name of nightMode will apply
 * @return            If succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_night_mode(bef_effect_handle_t handle, const char* night_type);
/**
 * @brief Update beauty-face-filter parameters.
 * @param handle            Effect handle
 * @param fSmoothIntensity  Filter smooth intensity
 * @param fBrightenIntensity   Filter brighten intensity
 *                          If both of fSmoothIntensity and fBrightenIntensity is 0 , this filter would not work.
 * @param bUseAmazing
 * @return                  If succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_update_beauty(bef_effect_handle_t handle, const float fSmoothIntensity, const float fBrightenIntensity);

/**
 * @brief Setup reshape-face-filter with a specified string.
 * @param handle          Effect handle
 * @param strPath         The absolute path of effect package.
 * @return                If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_reshape_face(bef_effect_handle_t handle, const char *strPath);

/**
 * @brief Update reshape-face-filter parameters
 * @param handle          Effect handle
 * @param fIntensity      Filter intensity
 * @return                if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_update_reshape_face(bef_effect_handle_t handle, const float fIntensity);

/**
 * @brief Update reshape-face-filter parameters
 * @param handle          Effect handle
 * @param eyeIntensity    eye intensity
  * @param cheekIntensity cheek intensity
 * @return                if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_update_reshape_face_intensity(bef_effect_handle_t handle, const float eyeIntensity, const float cheekIntensity);

/**
 * @brief Setup music-effect-filter with a specified string.
 * @param handle    Effect handle
 * @param strPath   The absolute path of effect package.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_music_effect(bef_effect_handle_t handle, const char *strPath);

/**
 * @brief Update music volume data
 * @param handle          Effect handle
 * @param volume          Music volume data.
 * @return                If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_update_music_effect_volume(bef_effect_handle_t handle, float volume);

/**
 * @brief Update music-effect-filter intensity
 * @param handle          Effect handle
 * @param fIntensity      Filter intensity
 * @return                if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_update_music_effect_intensity(bef_effect_handle_t handle, const float fIntensity);

/**
 @param handle                  effect handle
 @param leftFilterPath    [in]  current filter path
 @param colorPath         [out]  next filter path
 @parm  colorType         [out]  the direction that the next filter will appear
 @return            if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_filter_info(bef_effect_handle_t handle, const char *leftFilterPath, char** colorPath, int* colorType);

/**
 @param handle              effect handle
 @param leftFilterPath      current filter path
 @param rightFilterPath     next filter path
 @parm  direction           the direction that the next filter will appear
 @param position            the borderline of left-filter and right-filter in x-axis.
 @return            if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
//BEF_SDK_API bef_effect_result_t bef_effect_switch_color_filter(bef_effect_handle_t handle, const char *leftFilterPath, const char *rightFilterPath, float position);

/**
 @param handle              effect handle
 @param leftFilterPath      current filter path,not be ""
 @param rightFilterPath     next filter path,not be ""
 @parm  direction           the direction that the next filter will appear
 @param position            the borderline of left-filter and right-filter in x-axis.
 @return            if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_switch_color_filter_v2(bef_effect_handle_t handle, const char *leftFilterPath, const char *rightFilterPath, float position);
/**
 @param handle              effect handle
 @param leftFilterPath      current filter path,not be ""
 @param rightFilterPath     next filter path,not be ""
 @parm  position            the borderline of left-filter and right-filter in x-axis.
 @param leftIntensity       the intensity of left filter
 @param rightIntensity      the intensity of right filter
 @return                    if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_switch_color_filter_intensity_v3(bef_effect_handle_t handle, const char* leftFilterPath, const char* rightFilterPath, float position,float leftIntensity,float rightIntensity);

/**
 * Set color filter with a specified string.
 * @param handle    Effect handle
 * @param strPath   The absolute path of effect package.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
//BEF_SDK_API bef_effect_result_t bef_effect_set_color_filter(bef_effect_handle_t handle, const char *strPath);

/**
 * Set color filter with a specified string.
 * @param handle    Effect handle
 * @param strPath   The absolute path of effect package.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_color_filter_v2(bef_effect_handle_t handle, const char *strPath);
/**
 * @param handle        Effect handle
 * @param filter_path   The absolute path of effect package.
 * @param intensity     the intensity of filter,default -1.0.
 * @return              If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_color_filter_intensity_v3(bef_effect_handle_t handle, const char* filter_path,float *intensity);
/**
 * @param handle        Effect handle
 * @param filter_path   The absolute path of effect package.
 * @param intensity     the intensity of filter
 * @return          If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_color_filter_intensity_v3(bef_effect_handle_t handle, const char* filter_path,float intensity);
/**
 * @brief Update color-filter intensity
 * @param handle          Effect handle
 * @param fIntensity      Filter intensity
 * @return                if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_update_color_filter(bef_effect_handle_t handle, const float fIntensity);

/**
 * Set skintone filter with a specified string.
 * @param handle    Effect handle
 * @param strPath   The absolute path of effect package.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_skin_tone_filter(bef_effect_handle_t handle, const char* strPath);

/**
 * @brief Set effect with a specified string.
 * @param handle    Effect handle
 * @param strPath   The absolute path of effect package.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_effect(bef_effect_handle_t handle, const char *strPath);

/**
 * @brief Specify the time range of current sticker in editor timeline.
 *        Note: This method need to be called before bef_effect_process_texture.
 * @param handle        Effect handle.
 * @param startTime     The appear time of sticker in editor timeline,
 *                      set BEF_UNKNOWN_TIME if the start time is not sure. BEF_UNKINOWN_TIME is defined
 *                      in bef_framework_public_constant_define.h.
 * @param endTime       The disapper time of sticker in editor timeline, set BEF_UNKNOWN_TIME if the end time is not                     sure. The default value of the end time will be 1000, when the start time is set to                              BEF_UNKNOWN_TIME.
 * @param return        If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_effect_time_domain(bef_effect_handle_t handle,
                                                                  double startTime,
                                                                  double endTime);

/**
 * @brief Set whether stickers should sync time domain set by bef_effect_set_effect_time_domain.
 * @param handle        Effect handle.
 * @param needSync          need sync time domain
* @param return        If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_sync_time_domain(bef_effect_handle_t handle, bool needSync);

/**
 * @brief Set sticker with a specified path string.
 * @param handle        Effect handle
 * @param strPath       The absolute path of sticker package.
 * @param stickerId     The sticker package Id.
 * @param reqId         The reqId of set path.
 * @param canUseAmazing The sticker whether is campatiable to amazing engine
 * @return              If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_sticker(bef_effect_handle_t handle, unsigned int stickerId, const char *strPath, int reqId, bool needReload, bool canUseAmazing);

/**
 * @brief Set sticker with a specified path string.
 * @param handle        Effect handle
 * @param strPath       The absolute path of sticker package.
 * @param stickerId     The sticker package Id.
 * @param reqId         The reqId of set path.
 * @param stickerTag    The effect sticker config 
 * @return              If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_sticker_with_tag(bef_effect_handle_t handle, unsigned int stickerId, const char *strPath, int reqId, bool needReload, const char *stickerTag);

/**
 * @brief Set sticker with a specified path string.
 * @param handle        Effect handle
 * @param strPath       The absolute path of sticker package.
 * @param stickerId     The sticker package Id.
 * @param reqId         The reqId of set path.
 * @param stickerTag    The effect sticker config 
 * @return              If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_sticker_with_tag_v2(bef_effect_handle_t handle, uint64_t stickerId, const char *strPath, uint64_t reqId, bool needReload, const char *stickerTag);

/**
 * @brief Set effect when need rebuild.
 * @param handle        Effect handle
 * @param strPath       The absolute path of effect package.
 * @param needReload    Need rebuild effect
 * @return          If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_effect_reload(bef_effect_handle_t handle, const char *strPath, const bool needReload);

/**
 * @brief Update effect intensity
 * @param handle          Effect handle
 * @param fIntensity      Filter intensity
 * @return                if succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_update_effect(bef_effect_handle_t handle, const float fIntensity);

BEF_SDK_API bef_effect_result_t bef_effect_set_auxiliary_texture(bef_effect_handle_t handle, unsigned int textureID, const char* textureKey, unsigned int width, unsigned int height);
BEF_SDK_API bef_effect_result_t bef_effect_set_auxiliary_texture_device_texture(bef_effect_handle_t handle, device_texture_handle deviceTexture, const char* textureKey, unsigned int width, unsigned int height);
/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param handle     Effect handle
 * @param srcTexture source texture
 * @param dstTexture destination texture
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture(bef_effect_handle_t handle, unsigned int srcTexture, unsigned int dstTexture, double timeStamp);

/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param handle     Effect handle
 * @param srcDeviceTexture source texture
 * @param dstDeviceTexture destination texture
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_device_texture(bef_effect_handle_t handle, device_texture_handle srcDeviceTexture, device_texture_handle dstDeviceTexture, double timestamp);

/**
 * @breif            Draw srcTexture with effects to dstTexture with native buffer.
 * @param handle     Effect handle
 * @param srcTexture source texture
 * @param srcBuffer  source pixel buffer (CVPixelBufferRef/AHardwareBuffer)
 * @param dstTexture distination texture
 * @param dstBuffer  distination pixel buffer (CVPixelBufferRef/AHardwareBuffer)
 * @param timeStamp  time stamp
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_with_native_buffer(bef_effect_handle_t handle, unsigned int srcTexture, void* srcBuffer, unsigned int dstTexture, void* dstBuffer, double timeStamp);

/**
 * @breif            Draw srcTexture with effects to dstTexture with native buffer.
 * @param handle     Effect handle
 * @param srcTexture source texture (DeviceTexture)
 * @param srcBuffer  source pixel buffer (CVPixelBufferRef/AHardwareBuffer)
 * @param dstTexture distination texture (DeviceTexture)
 * @param dstBuffer  distination pixel buffer (CVPixelBufferRef/AHardwareBuffer)
 * @param timeStamp  time stamp
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_with_native_buffer_device_texture(bef_effect_handle_t handle, device_texture_handle srcDeviceTexture, device_texture_handle dstDeviceTexture, double timeStamp);

/**
 * @breif Multi-input single-output rendering interface
 * @param handle     Effect handle
 * @param srcTexture Input texture array. The width and height of each texture can be different
 * @param srcTextureCount Number of input textures
 * @param timeStamp timestamp
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_textures_with_native_buffers(bef_effect_handle_t handle, bef_src_texture* srcTexture, unsigned int srcTextureCount, bef_src_texture dstTexture, double timeStamp);

/**
 * @breif Multi-input single-output rendering interface
 * @param handle     Effect handle
 * @param srcDeviceTexture Input texture array. The width and height of each texture can be different
 * @param srcTextureCount Number of input textures
 * @param timeStamp timestamp
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_textures_with_native_buffers_device_texture(bef_effect_handle_t handle, bef_src_device_texture* srcDeviceTextures, unsigned int srcTextureCount, bef_src_device_texture dstDeviceTexture, double timeStamp);

/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param handle     Effect handle
 * @param srcTexture source texture
 * @param srcBuffer  source pixel buffer (CVPixelBufferRef/AHardwareBuffer)
 * @param dstTexture distination texture
 * @param dstBuffer  distination pixel buffer (CVPixelBufferRef/AHardwareBuffer)
 * @param rotation   face rotation
 * @param pExtraData detection data
 * @param timeStamp  time stamp
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_textures_with_extra_infos(bef_effect_handle_t handle, bef_src_texture* srcTexture, unsigned int srcTextureCount, bef_src_texture dstTexture, bef_rotate_type rotation, bef_auxiliary_data* pExtraData[], double timeStamp);


/**
 * @breif     Draw [in]textures with effects to [out]textures.(MultiIn MultiOut)
 * @param handle     Effect handle
 * @param textures  texture descripes in struct bef_texture_param
 * @param texture_count  count of @textures
 * @param timeStamp  time stamp
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_mimo(bef_effect_handle_t handle, bef_texture_param* textures, unsigned int texture_count, double timeStamp);
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_mimo_device_texture(bef_effect_handle_t handle, bef_texture_param_device_texture* srcDeviceTextures, unsigned int srcTextureCount, double timeStamp);
/**
 * @breif     get texture info of current scene
 * @param handle     Effect handle
 * @param textures  texture descripes in struct bef_texture_param
 * @param max_count  max count of @textures
 * @return return count of textures written if succeed ,  or negtive will be return
 */
BEF_SDK_API int bef_effect_get_texture_mimo_info(bef_effect_handle_t handle, bef_texture_param* textures, unsigned int max_count);

/**
 * @breif            Load current frame resource
 * @param handle     Effect handle
 * @param resourceLoadingTimeoutUs Wait for the resource loading time(us).  -1: the resource will return synchronously after loading. 0: asynchronous loading does not wait. Other values ​​are loaded asynchronously, and return after waiting at most resourceLoadingTimeoutUs us
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_load_resource_with_timeout(bef_effect_handle_t handle, int resourceLoadingTimeoutUs);
/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param handle     Effect handle
 * @param srcTexture source texture
 * @param dstTexture distination texture
 * @param timeStamp Current frame timestamp
 * @param resourceLoadingTimeoutUs resourceLoadingTimeoutUs Wait for the resource loading time(us).  -1: the resource will return synchronously after loading. 0: asynchronous loading does not wait. Other values ​​are loaded asynchronously, and return after waiting at most resourceLoadingTimeoutUs us
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_with_loading_timeout(bef_effect_handle_t handle, unsigned int srcTexture, unsigned int dstTexture, double timeStamp, int resourceLoadingTimeoutUs);

/**
 * @brief process with normal cpu buffer, YUV4:2:0P support currently.
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_pixel_buffer_with_loading_timeout(bef_effect_handle_t handle, bef_pixel_buffer *inputBuf, bef_pixel_buffer *outputBuf, double timeStamp, int resourceLoadingTimeoutUs);

/**
 * @brief get effect process mode, GPU(effect process with GPU) or CPU(effect process with CPU)
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_effect_process_mode(bef_effect_handle_t handle, bef_effect_process_mode *mode);

// Interfaces deprecated since version 520
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_multi_texture(bef_effect_handle_t handle, bef_src_texture* srcTexture, unsigned int srcTextureCount, double timeStamp, bool isForce);

/**
 * @breif The only interface for the algorithm to process textures, other interfaces need to converge to this
 * @param handle     Effect handle
 * @param srcTexture Input texture array. The width and height of each texture can be different
 * @param srcTextureCount Number of input textures
 * @param params Additional parameters
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_multi_texture_with_params(bef_effect_handle_t handle, bef_src_texture* srcTexture, unsigned int srcTextureCount, bef_algorithm_param* params);

/**
 * @breif The only interface for the algorithm to process textures, other interfaces need to converge to this
 * @param handle     Effect handle
 * @param srcDeviceTextures Input texture array. The width and height of each texture can be different
 * @param srcTextureCount Number of input textures
 * @param params Additional parameters
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_multi_texture_with_params_device_texture(bef_effect_handle_t handle, bef_src_device_texture* srcDeviceTextures, unsigned int srcTextureCount, bef_algorithm_param* params);

/**
 * @brief enable algorithm synchronizer, only used when parallel framework enabled.
 * @param handle effect handle
 */
BEF_SDK_API void bef_effect_enable_algorithm_syncer(bef_effect_handle_t handle);

/**
 * @brief wait until latest frame algorithm calculation done, only used when parallel framework enabled.
 * @param handle effect handle
 * @param[out] timestamp sync frame's timestamp
 * @return if succeed return IES_RESULT_SUC, other value please see bef_effect_base_define.h
 * @note 1. inner syncer will be released after the first wait invoked, so do not use it twice
 *       2. to avoid multi-thread issue, use this interface in same thread with process_texture_***
 */
BEF_SDK_API bef_effect_result_t bef_effect_sync_latest_algorithm_calculation(bef_effect_handle_t handle, double* timestamp);

/**
 * @breif Video background traversing sticker transfer algorithm cpu buffer interface
 * @param handle     Effect handle
 * @param srcTexture Input texture array. The width and height of each texture can be different
 * @param srcTextureCount Number of input textures
 * @param params Additional parameters
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_auxiliary_algorithm_buffer(bef_effect_handle_t handle, bef_src_texture* srcTexture, unsigned int srcTextureCount, bef_algorithm_param* params);
/**
 * @breif Set algorithm playback mode
 * @param handle Effect handle
 * @param mode Playback mode
 * @param filePath Algorithm file path
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_algorithm_replay_mode(bef_effect_handle_t handle, bef_algorithm_replay_mode mode, const char* filePath);

/**
 * @breif create algorithm and load algorithm model
 * @param handle Effect handle
 * @param req algorithm type
 */
BEF_SDK_API bef_effect_result_t bef_effect_load_algorithm(bef_effect_handle_t handle, bef_algorithm_requirement req);

/**
* @breif load resource
* @param handle Effect handle
* @param req algorithm type
*/
BEF_SDK_API bef_effect_result_t bef_effect_load_gpu_resource(bef_effect_handle_t handle);

/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param handle     Effect handle
 * @param srcTexture source texture
 * @param dstTexture destination texture
 * @param rotation   face rotation
 * @param pExtraData detection data
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_with_detection_data(bef_effect_handle_t handle, unsigned int srcTexture, unsigned int dstTexture, bef_rotate_type rotation, bef_auxiliary_data* pExtraData);

/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param handle     Effect handle
 * @param srcDeviceTexture source texture
 * @param dstDeviceTexture destination texture
 * @param rotation   face rotation
 * @param pExtraData detection data
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_with_detection_data_device_texture(bef_effect_handle_t handle, device_texture_handle srcDeviceTexture, device_texture_handle dstDeviceTexture, bef_rotate_type rotation, bef_auxiliary_data* pExtraData);

/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param handle     Effect handle
 * @param srcTexture source texture
 * @param dstTexture distination texture
 * @param rotation   face rotation
 * @param pExtraData detection data
 * @param timeStamp  time stamp
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_with_detection_data_and_timestamp(bef_effect_handle_t handle, unsigned int srcTexture, unsigned int dstTexture, bef_rotate_type rotation, bef_auxiliary_data* pExtraData, double timeStamp);

/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param handle     Effect handle
 * @param srcTexture source texture
 * @param srcBuffer  source pixel buffer (CVPixelBufferRef/AHardwareBuffer)
 * @param dstTexture destination texture
 * @param dstBuffer  destination pixel buffer (CVPixelBufferRef/AHardwareBuffer)
 * @param rotation   face rotation
 * @param pExtraData detection data
 * @param timeStamp  time stamp
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_with_extra_info(bef_effect_handle_t handle, unsigned int srcTexture, void* srcBuffer, unsigned int dstTexture, void* dstBuffer, bef_rotate_type rotation, bef_auxiliary_data* pExtraData, double timeStamp);

/**
 * @breif            Draw srcTexture with effects to dstTexture.
 * @param handle     Effect handle
 * @param srcDeviceTexture source texture (DeviceTexture)
 * @param dstDeviceTexture destination texture (DeviceTexture)
 * @param rotation   face rotation
 * @param pExtraData detection data
 * @param timeStamp  time stamp
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_texture_with_extra_info_device_texture(bef_effect_handle_t handle, device_texture_handle srcDeviceTexture, device_texture_handle dstDeviceTexture, bef_rotate_type rotation, bef_auxiliary_data* pExtraData, double timeStamp);

/**
 * @brief get frame_info data by writing into p_frame_info, caller should ensure the accessibility of the struct pointer
 * @param handle effect handler
 * @param p_frame_info frame info struct pointer
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_frame_info(bef_effect_handle_t handle, bef_frame_info* p_frame_info);

/**
 * @breif            Test effect RebuildChain
 * @param handle     Effect handle
 * @param flag       true->enable rebuildchain false->disable rebuildchain
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_buildChain_flag(bef_effect_handle_t handle, bool flag);
/**
 * @breif            Set RT reuse flag
 * @param handle     Effect handle
 * @param flag       default false,true->enable rt, false->disable rt
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_rt_flag(bef_effect_handle_t handle, bool flag);
/**
 * @brief Set flush flag
 * @param handle     Effect handle
 * @return Detection mode, reference bef_effect_base_define.h for detail.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_flush_flag(bef_effect_handle_t handle, bool flag);
/**
 * @brief Set default makeup segmentation
 * @param handle     Effect handle
 * @param enable     true or false
 * @return Detection mode, reference bef_effect_base_define.h for detail.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_default_makeup_segmentation(bef_effect_handle_t handle, bool enable);
/**
 * @brief Set flush mode
 * @param handle     Effect handle
 * @return Detection mode, reference bef_effect_base_define.h for detail.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_flush_mode(bef_effect_handle_t handle, bef_flush_mode mode);
/**
* @brief Get algorithm remark
* @param handle     Effect handle
* @return Detection mode, reference bef_effect_base_define.h for detail.
*/
BEF_SDK_API bef_effect_remark* bef_effect_get_remark(bef_effect_handle_t handle);

/**
 * @brief Get detection mode
 * @param handle     Effect handle
 * @return Detection mode, reference bef_effect_base_define.h for detail.
 */
BEF_SDK_API bef_algorithm_requirement bef_effect_get_requirment(bef_effect_handle_t handle);

BEF_SDK_API bef_effect_result_t bef_algorithm_get_size(bef_effect_handle_t handle, int *width, int *height);

/**
 * @brief set algorithm change type mag be enable post
 * @param handle     Effect handle
 * @param type       algorithm change type
 * @param bEnable    msg enable be post
 */
BEF_SDK_API void bef_effect_set_algorithm_change_msg(bef_effect_handle_t handle, bef_algorithm_change_type type, bool bEnable);

/**
 * @brief get algorithm change type mag be enable post
 * @param handle     Effect handle
 * @param type       algorithm change type
 * @return true is enable, false is disable
 */
BEF_SDK_API bool bef_effect_get_algorithm_change_msg(bef_effect_handle_t handle, bef_algorithm_change_type type);


/**
 * @param handle      Effect handle that will be created
 * @param fIntensity  Filter smooth intensity
 * if fIntensity is 0 , this filter would not work.
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_intensity(bef_effect_handle_t handle, bef_intensity_type intensityType, float fIntensity);

/**
 * @breif Set the current state of the client
 * @param handle     Effect handle
 * @param state Client status, such as preview, photo, and recording, ref: details in bef_effect_public_business_define.h
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_client_state(bef_effect_handle_t handle, bef_client_state state);


/**
 * you should invoke this interface follow on init effect , and must before processTexture!
 * @param handle   : Effect handle that will be created
 * @param intensityType : adjustment intensity
 * @param resource : feature path, not effect path
 * @return          if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_adjustment_resource(bef_effect_handle_t handle,bef_intensity_type intensityType,const char *resource);

/**
 * @param handle            Effect handle that will be created
 * @param resource          feature dir path
 * @param intensity_name    intensity name match to uniform of shader
 * @param fIntensity        Filter smooth intensity
 * @return                  if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_adjustment_intensity(bef_effect_handle_t handle, const char *resource, bef_intensity_name intensity_name, float fIntensity);
/**
 * Add or remove a small item.
 * @param handle
 * @param intensityType: Item category
 * @param resource: feature path, not effect path
 * @param iTypeStatus: 0 means remove, 1 means add.
 * @return
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_buildin_adjustment(bef_effect_handle_t handle, bef_intensity_type intensityType, const char *resource, int iTypeStatus);
/**
 * @brief Remove all build-in feature
 * @param handle
 * @return
 */
BEF_SDK_API bef_effect_result_t bef_effect_remove_buildin_adjustment(bef_effect_handle_t handle);

/**
 * @param handle      Effect handle that will be created
 * @param x           position x in local view coordinate
 * @param y           position y in local view coordinate
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_music_brush_append_point(bef_effect_handle_t handle, float x, float y);

/**
 * @brief Deprecated function, no longer valid
 * @param maxMemCache max memory cache value, uint MB
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_max_memcache(bef_effect_handle_t handle, unsigned int maxMemCache);

/**
 * @param handle      Effect handle that will be created
 */
BEF_SDK_API void bef_effect_clean_cache(bef_effect_handle_t handle);

/**
 * @param cachePath   texture cache path
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_texture_cache_path(bef_effect_handle_t handle, const char* cachePath);

/**
 * @param maxMemSize  max memory size, uint MB
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_texture_cache_max_mem_size(bef_effect_handle_t handle, unsigned int maxMemSize);

/**
 * @param maxCacheSize max storage size, uint MB
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_texture_cache_max_cache_size(bef_effect_handle_t handle, unsigned int maxCacheSize);

/**
 * @param maxMemSize  max memory size, uint MB
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_texture_cache_total_mem_size(bef_effect_handle_t handle, unsigned int* totalMemCache);

/**
 * @param maxCacheSize max storage size, uint MB
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_texture_cache_total_cache_size(bef_effect_handle_t handle, unsigned int* totalCacheSize);

/**
 * @param preloadNum num of preload texture cache file
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_texture_cache_preload_num(bef_effect_handle_t handle, int preloadNum);

/**
 * @param preloadNum num of preload texture cache file
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_texture_cache_preload_num(bef_effect_handle_t handle, int* preloadNum);

/**
 * @param handle Effect handle that already be created
 * @param result Current algorithm detect result struct
 * @param algorithmId Current algorithm id
 * @param subType Reserve to get sub content of algorithm result
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_general_algorithm_result(bef_effect_handle_t handle, bef_base_effect_info* result, int algorithmIndex, int subType);

/**
 * @param handle      Effect handle that will be created
 * @return            return current user score
 */
//BEF_SDK_API bef_effect_result_t bef_effect_set_skeleton_template_identity(bef_effect_handle_t handle, int templateId, int guideIndex, enum bef_body_dance_mode_type type);

/**
 * @param handle Effect handle that already be created
 * @param result Current face detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_face_detect_result(bef_effect_handle_t handle, bef_face_info* result);

#ifndef TRANSPARENCY_CENTER_I18N
/**
 * @param handle Effect handle that already be created
 * @param result Current face verify dynamic result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_face_verify_dynamic_result(bef_effect_handle_t handle, bef_face_verify_dynamic_info* result);
#endif
#ifndef TRANSPARENCY_CENTER_I18N
BEF_SDK_API bef_effect_result_t bef_effect_get_face_clusting_result(bef_effect_handle_t handle, bool *result);
#endif
/**
 * @param handle Effect handle that already be created
 * @param result Current face detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_face_attrs_detect_result(bef_effect_handle_t handle, bef_face_attrs_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current face detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_skeleton_detect_result(bef_effect_handle_t handle, bef_skeleton_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current microphone attention detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_microphone_attention_detect_result(bef_effect_handle_t handle, bef_microphone_attention_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current face detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_face_cat_detect_result(bef_effect_handle_t handle, bef_face_cat_detect* result);

/**
 * @param handle      Effect handle that will be created
 * @return            return current user hit result[0 = no, 1 = good, 2 = perfect]
 */
//BEF_SDK_API bef_effect_result_t bef_effect_get_body_dance_result(bef_effect_handle_t handle, bef_body_dance_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current hand detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_hand_detect_result(bef_effect_handle_t handle, bef_hand_info* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current hand detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_hand_detect_roi_result(bef_effect_handle_t handle, bef_hand_info* result);

/**
 @param handle Effect handle
 @param result Current enigma detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_enigma_detetct_result(bef_effect_handle_t handle, bef_enigma_result* result);

/**
 @param handle Effect handle
 @param result Free enigma detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_free_enigma_detetct_result(bef_effect_handle_t handle, bef_enigma_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current expression detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_expression_detect_result(bef_effect_handle_t handle, bef_expression_detect_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current scene detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_scene_recognition_detect_result(bef_effect_handle_t handle, bef_scene_detect_result* result);

/**
* @param handle Effect handle that already be created
* @param result Current avatar drive result struct
*/
BEF_SDK_API bef_effect_result_t bef_effect_get_avatar_drive_result(bef_effect_handle_t handle, bef_avatar_drive_info* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current bling detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_bling_detect_result(bef_effect_handle_t handle, bef_bling_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current protrait matting detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_portait_matting_detect_result(bef_effect_handle_t handle, bef_matting_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current sky segmentation detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_sky_seg_detect_result(bef_effect_handle_t handle, bef_matting_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current mug detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_mug_detect_result(bef_effect_handle_t handle, bef_mug_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current head segmentation result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_head_seg_detect_result(bef_effect_handle_t handle, bef_head_seg_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current hair color detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_hair_color_detect_result(bef_effect_handle_t handle, bef_hair_color_result* result);

/**
 * @param handle Effect handle that already be created
 * @param result Current face fatting detect result struct
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_face_fitting_detect_result(bef_effect_handle_t handle, bef_face_fitting_mesh_result* result);

/**
 * @brief Get object_tracking algorithm result.
 * @param handle Effect handle
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API int bef_effect_get_object_tracking_result(bef_effect_handle_t handle,
                                                      bef_object_tracking_result* result);

BEF_SDK_API bef_effect_result_t bef_effect_refresh_algorithm(bef_effect_handle_t handle, bef_algorithm_requirement algorithmFlag, bool enableRequirment);

BEF_SDK_API bef_effect_result_t bef_effect_set_external_algorithm(bef_effect_handle_t handle, bef_algorithm_requirement algorithmFlag);

/**
 * @param handle      Effect handle that will be created
 * @param bodyDance   [SkeletonDetectModeBeforeRecordingStart = 0, SkeletonDetectModeAfterRecordingStart = 1]
 * @return            return
 */
//BEF_SDK_API bef_effect_result_t bef_effect_set_body_dance_mode(bef_effect_handle_t handle, int bodyDance);

// The interface is gradually obsolete from the 520 version
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_texture(bef_effect_handle_t handle, unsigned int textureid_src, double timeStamp);
// The interface is gradually obsolete from the 520 version
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_texture_device_texture(bef_effect_handle_t handle, device_texture_handle device_texture_src, double timeStamp);
// The interface is gradually obsolete from the 520 version
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_texture_force(bef_effect_handle_t handle, unsigned int textureid_src, double timeStamp, bool isForce);
// The interface is gradually obsolete from the 520 version
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_buffer(bef_effect_handle_t handle, int width, int height, const unsigned char* imageData, bef_pixel_format pixformat, double timeStamp);

BEF_SDK_API bef_effect_result_t bef_effect_set_algorithm_pre_config(bef_effect_handle_t handle, unsigned int width, unsigned int height);

// The interface is gradually obsolete from the 520 version
/**
 * Note: must be called before bef_effect_init!
 * @param handle      Effect handle that will be created
 * @param useTTFaceDetect   [use TT face detect = true, no use TT face detect = false]
 * @return            return
 */
BEF_SDK_API bef_effect_result_t bef_effect_use_TT_facedetect(bef_effect_handle_t handle, bool useTTFaceDetect);


/**
 * @breif             Get algorithm's last executing time
 * @param handle      Effect handle that will be created
 * @param algorithmType   the algorithm which you want to get its executing time
 * @return            return executing time
 */
BEF_SDK_API long long bef_effect_get_algorithm_execute_time(bef_effect_handle_t handle, bef_algorithm_requirement algorithmType);

/**
 * @breif             Get frame second
 * @param handle      Effect handle that will be created
 * @return            return frame per second
 */
BEF_SDK_API float bef_effect_get_frame_per_second(bef_effect_handle_t handle);

/**
 * @breif            Set algorithm's ext param, such as face dectect frequency.
 * @param handle     Effect handle
 * @param extParam   Extra param: 1 face dectect extra param
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_algorithm_ext_param(bef_effect_handle_t handle, bef_algorithm_ext_param *extParam);

/**
 * @breif            Set algorithm's dynamic param.
 * @param handle     Effect handle
 * @param extParam   Extra param: 1 face dectect extra param
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_algorithm_runtime_param(bef_effect_handle_t handle, int64_t key, float val);

/**
 * @breif            Set algorithm's ext param, such as face dectect frequency.
 * @param handle     Effect handle
 * @param force      force: true
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_algorithm_force_detect(bef_effect_handle_t handle, bool force);
/**
 * @breif                       Set bgm enable play
 * @param handle                Effect handle
 * @param bEnable               bgm is enable
 */
BEF_SDK_API void bef_effect_set_bgm_enable(bef_effect_handle_t handle, bool bEnable);

/**
 * @breif                       Get bgm enable play
 * @param handle                Effect handle
 * @return                      If succeed return true,  other return false
 */
BEF_SDK_API bool bef_effect_get_bgm_enable(bef_effect_handle_t handle);

/**
 * @breif                       Set bgm mute
 * @param handle                Effect handle
 * @param bIsMute               true: set bgm mute, false: set bgm unmute
 */
BEF_SDK_API void bef_effect_set_bgm_mute(bef_effect_handle_t handle, bool bIsMute);

/**
 * @brief                       set audioPlayer implement
 * @param handle                Effect handle
 * @param factoryPtr            LiveAudioPlayerFactory
 */
BEF_SDK_API bool bef_effect_set_audio_player_factory(bef_effect_handle_t handle, void *factoryPtr);

/**
 * @brief                       set audioPlayer implement
 * @param handle                Effect handle
 * @param factoryPtr            VEAudioPlayerFactory
 */
BEF_SDK_API bool bef_effect_set_ve_audio_player_factory(bef_effect_handle_t handle, void *factoryPtr);

/**
 * @brief                       set videoPlayer implement
 * @param handle                Effect handle
 * @param factoryPtr            VEVideoPlayerFactory
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_ve_video_player_factory(bef_effect_handle_t handle, void *factoryPtr);

/**
 * @breif                       set enable the NPU sky seg,or use the normal sky seg
 * @param handle                Effect handle
 * @return                      If succeed return true,  other return false
 * @details                     will be deleted after confirming it's not used
 */
BEF_SDK_API bool bef_effect_hichry_skyseg_enable(bef_effect_handle_t handle, bool enable);

/**
 *  @breif                       Temporary interface, deleted after merging live broadcast and short video
 * @param handle                Effect handle
 * @return                      If succeed return true,  other return false
 */
BEF_SDK_API bool bef_effect_set_glclear(bef_effect_handle_t handle, bool enable);

/**
 * @param  isStart : true: start recording, false: end recording
 */
BEF_SDK_API void bef_effect_record_video_notify(bool isStart);

/**
 *  @breif            notify last video deleted in multistage mode
 *  @param handle     Effect handle
 */
BEF_SDK_API void bef_effect_delete_last_video_notify(bef_effect_handle_t handle);
/**
 *  @breif                       Take a photo interface
 */
BEF_SDK_API void bef_effect_capture_notify(void);

/**************************** application manager ********************************/

BEF_SDK_API void bef_effect_will_resign_active();

BEF_SDK_API void bef_effect_did_become_active();

BEF_SDK_API void bef_effect_did_enter_back_ground();

BEF_SDK_API void bef_effect_will_enter_foreground();

BEF_SDK_API void bef_effect_will_terminate();

BEF_SDK_API void bef_effect_receive_memory_warning();

BEF_SDK_API bool bef_effect_get_audio_playing_progress(bef_effect_handle_t handle, bef_audio_progress *progresses, int* count, const int max_count);
BEF_SDK_API bool bef_effect_set_audio_playing_progress(bef_effect_handle_t handle, const bef_audio_progress *progresses, const int count);



BEF_SDK_API void bef_effect_send_msg(bef_effect_handle_t handle, unsigned int msgID,
                                     long arg1, long arg2, const char *arg3);

typedef int(*EffectMsgReceiveFunc)(void* userdata, unsigned int msgID,
                                               long arg1, long arg2, const char *arg3);

BEF_SDK_API bef_effect_result_t add_effect_msg_receive_func(bef_effect_handle_t handle, EffectMsgReceiveFunc pfunc, void* userdata);

BEF_SDK_API bef_effect_result_t remove_effect_msg_receive_func(bef_effect_handle_t handle, EffectMsgReceiveFunc pfunc, void* userdata);

typedef int(*EffectMsgReceiveFuncV2)(void* userdata, unsigned int msgID,
                                               int64_t arg1, uint64_t arg2, const char *arg3);

BEF_SDK_API bef_effect_result_t add_effect_msg_receive_func_v2(bef_effect_handle_t handle, EffectMsgReceiveFuncV2 pfunc, void* userdata);

BEF_SDK_API bef_effect_result_t remove_effect_msg_receive_func_v2(bef_effect_handle_t handle, EffectMsgReceiveFuncV2 pfunc, void* userdata);


/**************************** monitor begin ********************************/
/**
 * @brief start record effect running state
 * @param handle Effect handle
 */
BEF_SDK_API void bef_effect_monitor_start(bef_effect_handle_t handle);

/**
 * @brief get effect record log, it's a json string, detail see doc : https://docs.bytedance.net/sheet/GiO5Uons9Upnzn9earbzhb#1
 * @param handle Effect handle
 * @return contains monitor contents json string
 */
BEF_SDK_API const char* bef_effect_get_monitor_content(bef_effect_handle_t handle);

/**
 * @brief stop record effect running state, because monitor running on render thread, stop is async, user shoud recevier msg RENDER_MSG_TYPE_MONITOR do samething(like call function bef_effect_get_monitor_content)
 * @param handle Effect handle
 */
BEF_SDK_API void bef_effect_monitor_stop(bef_effect_handle_t handle);

/**
 * @brief set log output level, it's only working on debug version
 * @param logLevel out put log min level, detail see bef_effect_public_base_define.h bef_log_level
 */
BEF_SDK_API void bef_effect_set_log_level(bef_log_level logLevel);
/**************************** monitor end  *********************************/


/**
 * @brief Set beat information of music
 * @param handle Effect handle
 * @param timeData      beat's time index of music
 * @param beatData      beat's intensity
 * @param dataLen       the length of timeData ( and beatData)
 */
//BEF_SDK_API bef_effect_result_t bef_effect_set_music_nodes(bef_effect_handle_t handle, float *timeData, float *beatData, const int dataLen);
BEF_SDK_API bef_effect_result_t bef_effect_set_music_node_filepath(bef_effect_handle_t handle, const char *strPath);
BEF_SDK_API bef_effect_result_t bef_effect_set_music_time_func(bef_effect_handle_t handle, float (*getCurTime)(void* userData), void* userData);

BEF_SDK_API bef_effect_result_t bef_effect_set_play_audio_func(bef_effect_handle_t handle, int (*playAudio)(void* userData, const char **audioPaths, const int audioNum), void* userData);

/**
 * @brief Get effect label string which needs to be display on screen.
 *        For EffectCam debug, and not being debug mode of project.
 * @param handle Effect handle
 * @param infoStr a pointer to get info string
 * @return return
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_info_string(bef_effect_handle_t handle, char* infoStr);


/**
 * @brief               set or add render cache texture from path
 *                      if path is null, delete texture from render cache
 * @param handle        Effect handle
 * @param key           render cache key
 * @param path          file path
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_render_cache_texture(bef_effect_handle_t handle, const char* key, const char* path);

/**
 * @brief               set or add render cache image with cpu buffer, current support YUV4:2:0P
 *                      if path is null, delete image from render cache
 * @param handle        Effect handle
 * @param key           render cache key
 * @param image         render cache image
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_render_cache_texture_with_buffer2(bef_effect_handle_t handle, const char* key, bef_pixel_buffer* image);

/**
 * @brief               same as `bef_effect_set_render_cache_texture` except
 *                      resizing to fit Custom Texture if input texture is too large. used in low devices
 * @param handle        Effect handle
 * @param key           render cache key
 * @param path          file path
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_render_cache_texture_resize_safe(bef_effect_handle_t handle, const char* key, const char* path);

/**
 * @brief          get render cache textureId with key(Called in GL thread only!)
 * @param handle        Effect handle
 * @param key              render cache key
 * @param texture          result texture info
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_render_cache_texture(bef_effect_handle_t handle, const char* key, bef_texture_param* texture);


/** @brief               set or add render cache texture from buffer
 * @param handle Effect handle
 * @param key  render cache key
 * @param image image buffer
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_render_cache_texture_with_buffer(bef_effect_handle_t handle, const char* key, bef_image* image);

/** @brief               set or add multiple render cache texture from buffer
 * @param handle Effect handle
 * @param key  render cache key
 * @param image image buffer
 * @param num the number of the image you want to set into the render cache
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_render_cache_texture_with_buffer_multiple(bef_effect_handle_t handle, const char* key[], bef_image* image[], int num);

/**
 * @brief               set render_cache_texture_orientation
 * @param handle        Effect handle
 * @param key           render cache key
 * @param value         value
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_render_cache_texture_orientation(bef_effect_handle_t handle, const char* key, bef_rotate_type orientation);


/**
 * @brief               set or add value to render cache
 * @param handle        Effect handle
 * @param key           render cache key
 * @param value         value
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_render_cache_int_value(bef_effect_handle_t handle, const char* key, int value);


/**
 * @brief               set or add value to render cache
 * @param handle        Effect handle
 * @param key           render cache key
 * @param value         value
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_render_cache_string_value(bef_effect_handle_t handle, const char* key, const char* value);

/**
 * @brief               set font path and face
 * @param handle        Effect handle
 * @param path          font path
 * @param faceIndex     font face index
 */
BEF_SDK_API bef_effect_result_t
    bef_effect_set_font_path(bef_effect_handle_t handle, const char* path, const int faceIndex);

/**
 * @brief               set srt data
 * @param handle        Effect handle
 * @param srtData       srt data
 */
BEF_SDK_API bef_effect_result_t
    bef_effect_set_srt_utf32(bef_effect_handle_t handle, const bef_srt_data* srtData);

/**
 * @brief               get photo algorithm detect result
 * @param handle        effect handle
 * @param image         detect image
 * @param algorithmType algorithm type
 * @param doesContain   true or false
 */
BEF_SDK_API bef_effect_result_t
bef_effect_detect_photo_content(bef_effect_handle_t handle, bef_image* image, const char* algorithmType, bool* doesContain);

/**
 * @brief               get photo algorithm detect result
 * @param handle        effect handle
 * @param image         detect image
 * @param algorithmType algorithm type
 * @param resultCount   count of result
 */
BEF_SDK_API bef_effect_result_t
bef_effect_detect_photo_content_with_num(bef_effect_handle_t handle, bef_image* image, const char* algorithmType, int* resultCount);

/**
 * @brief               get photo enigma detect result
 * @param handle        effect handle
 * @param image         detect image
 * @param result        Current enigma detect result struct
 */
BEF_SDK_API bef_effect_result_t
bef_effect_detect_photo_enigma(bef_effect_handle_t handle, bef_image* image, bef_enigma_result* result);

/**
 * @brief               create enigma handle
 * @param handle        address of enigma handle
 */
BEF_SDK_API bef_effect_result_t
bef_effect_enigma_create_handle(bef_enigma_sdk_handle *handle);

/**
 * @brief               Encoding configuration
 * @param handle        enigma handle
 * @param type          param type
 * @param value         param value
 */
BEF_SDK_API bef_effect_result_t
bef_effect_enigma_set_encode_hint(bef_enigma_sdk_handle handle, bef_enigma_param_type type, float value);

/**
 * @brief               release enigma
 * @param handle        enigma handle
 */
BEF_SDK_API bef_effect_result_t
bef_effect_enigma_release_handle(bef_enigma_sdk_handle handle);

/**
 * @brief               QR coding interface, get JPG data
 */
BEF_SDK_API bef_effect_result_t
bef_effect_enigma_qrcode_encode(bef_enigma_sdk_handle handle, const char *content, int scale, int padding, void **dst_data, int *data_len);

/**
 * @brief QR encoding interface, get the bitmap of the original code, and the memory is allocated and released internally by the API
 */
BEF_SDK_API bef_effect_result_t
bef_effect_enigma_qrcode_encode2(bef_enigma_sdk_handle handle, const char *content, void **dst_data, int *width, int *height);

/**
 * @brief                       dy code encoding interface
 * @param center_logo_buff      Byte stream in the logo area in the middle of the image
 * @param center_logo_buff_size The length of the byte stream in the logo area in the middle of the image
 * @param dy_logo_buff      Byte stream in the logo area in the upper right corner
 * @param dy_logo_buff_size The length of the byte stream in the logo area in the upper right corner.
 * @param decoration_logo_buff  Byte stream of large V image
 * @param decoration_logo_buff_size The length of the byte stream of large V image
 * @param add_v_logo            Indicates whether to add a large V mark in the logo area in the center, the value is {0, 1}
 * @param scale                 Represents the size of the dy QR, when the scale is 1, the diameter of the dy QR is about 400 pixels, when the scale is 2, the diameter is about 800 pixels, and so on
 * @param padding               The size of white space around the image, pixel value
 */
BEF_SDK_API bef_effect_result_t
bef_effect_enigma_dycode_encode(bef_enigma_sdk_handle handle, const char *content, const char *center_logo_buff,
                                 int center_logo_buff_size, const char *dy_logo_buff, int dy_logo_buff_size,
                                 const char *decoration_logo_buff, int decoration_logo_buff_size, int add_v_logo,
                                 int scale, int padding, void **dst_data, int *data_len);
/**
 * @brief               set generateBitmap func ptr to effect
 */
BEF_SDK_API bef_effect_result_t
bef_effect_set_generate_bitmap_func(
                                    bef_effect_handle_t handle,
                                    int (*generateBitmap)(void*, unsigned char**, int *, int *, int *, unsigned char*, int, bef_text_layout),
                                    int (*generateBitmapUTF32)(void* , unsigned char**, int *, int *, int *, unsigned int*, int, bef_text_layout),
                                    void* userData);

/**
 * @brief               set generateTextBitmap func ptr to effect
 */
BEF_SDK_API bef_effect_result_t
bef_effect_set_generate_text_bitmap_func(
                                    bef_effect_handle_t handle,
                                    int (*generateTextBitmap)(void*, unsigned char**, int *, int *, int *, unsigned char*, int, bef_text_layout),
                                    void* userData);

/**
 @brief set input text
 @param handle effect_handle
 @param input_text Text content
 @param nArg1 Input parameter
 @param nArg2 Input parameter
 @param cArg3 Input parameter
 @return status
 */
BEF_SDK_API bef_effect_result_t
bef_effect_set_input_text(bef_effect_handle_t handle, const char *input_text, int nArg1, int nArg2, const char *cArg3);

/**
 *@brief User collapses keyboard
 @param handle effect_handle
 @param finished Cancel input: false, end input: true
 @return status
 */
BEF_SDK_API bef_effect_result_t
bef_effect_notify_keyboard_hide(bef_effect_handle_t handle, bool finished);

/**
 @brief Get all feature text content, the structure is held externally but the internal data is created by effect
 
 @param handle effect_handle
 @param text_content 
 @return status
 */
BEF_SDK_API bef_effect_result_t
bef_effect_get_text_content(bef_effect_handle_t handle, bef_text_content* text_content);

/**
 @brief Release text data structure pointer
 
 @param text_content Text data structure pointer
 @return status
 */


BEF_SDK_API bef_effect_result_t
bef_effect_free_text_content(bef_text_content* text_content);

// Get the word count limit
BEF_SDK_API bef_effect_result_t
bef_effect_get_text_max_count(bef_effect_handle_t handle, int* count);

BEF_SDK_API bef_effect_result_t
bef_effect_set_language(bef_effect_handle_t handle, const char* language);

/**
 @brief Set the switch for men and women with different makeup (same makeup with different intensity)
 
 @param handle effect_handle
 @param text_content Text data structure pointer
 @return status
 */
BEF_SDK_API bef_effect_result_t
bef_effect_set_male_makeup_state(bef_effect_handle_t handle, bool state);

/**
 @brief Clear event

 @param handle effect_handle
 @return status
*/
BEF_SDK_API bef_effect_result_t
bef_effect_clear_event(bef_effect_handle_t handle);

#if defined(__ANDROID__) || defined(TARGET_OS_ANDROID)
typedef enum IES_EFFECT_LOG_LEVEL {
    IESEffectLogLevelError = 4,
    IESEffectLogLevelWarn = 3,
    IESEffectLogLevelInfo = 2,
    IESEffectLogLevelDebug = 1,
    IESEffectLogLevelVerbose = 0,
} IESEffectLogLevel;
#else
typedef enum IES_EFFECT_LOG_LEVEL {
    IESEffectLogLevelError,
    IESEffectLogLevelWarn,
    IESEffectLogLevelInfo,
    IESEffectLogLevelDebug,
    IESEffectLogLevelVerbose,
} IESEffectLogLevel;
#endif

typedef int(*logFileFuncPointer)(int logLevel, const char* msg);
typedef int(*logFabricFuncPointer)( const char* msg);
typedef int(*AppLogFuncPointer)(const char *chEventName, const char *chJson, const char *chEventType);

BEF_SDK_API bef_effect_result_t bef_effect_set_log_to_local_func(logFileFuncPointer pfunc);
BEF_SDK_API bef_effect_result_t bef_effect_add_log_to_local_func_with_key(const char* key, logFileFuncPointer pfunc);
BEF_SDK_API bef_effect_result_t bef_effect_remove_log_to_local_func_with_key(const char* key);

BEF_SDK_API bef_effect_result_t bef_effect_add_applog_func(AppLogFuncPointer pfunc);
BEF_SDK_API bef_effect_result_t bef_effect_remove_applog_func(AppLogFuncPointer pfunc);

#if __linux__ || defined(TARGET_OS_LINUX)
BEF_SDK_API bef_effect_result_t bef_effect_add_cloud_rendering_server_applog_func(AppLogFuncPointer pfunc);
BEF_SDK_API bef_effect_result_t bef_effect_remove_cloud_rendering_server_applog_func(AppLogFuncPointer pfunc);
#endif

typedef int(*logFabricFuncPointer)(const char* msg);
BEF_SDK_API bef_effect_result_t bef_effect_set_log_to_fabric_func(logFabricFuncPointer pfunc);

typedef int(*logMonitorFuncPointer)(const char* service, const char* log);
BEF_SDK_API bef_effect_result_t bef_effect_set_log_monitor_func(logMonitorFuncPointer pfunc);

extern logFabricFuncPointer g_logToFabricFunc;
#ifndef AMAZING_EDITOR_SDK
extern logMonitorFuncPointer g_logMonitorFileFunc;
#else
extern thread_local logMonitorFuncPointer g_logMonitorFileFunc;
#endif


typedef struct BefRequirement_ST
{
    unsigned long long algorithmReq;
    unsigned long long algorithmParam;
} bef_requirement;

BEF_SDK_API bef_requirement bef_effect_get_new_requirment(bef_effect_handle_t handle);
BEF_SDK_API bef_requirement bef_effect_get_external_requirement(bef_effect_handle_t handle);
BEF_SDK_API bef_effect_result_t bef_effect_refresh_new_algorithm(bef_effect_handle_t handle, bef_requirement algorithmFlag, bool enableRequirment);
BEF_SDK_API bef_effect_result_t bef_effect_set_external_new_algorithm(bef_effect_handle_t handle, bef_requirement algorithmFlag);
BEF_SDK_API long long bef_effect_get_new_algorithm_execute_time(bef_effect_handle_t handle, bef_requirement algorithmType);

BEF_SDK_API bef_effect_result_t bef_effect_set_using_asyn_api(bool usingAsynApi);



// Get a list of currently used algorithms
BEF_SDK_API bef_effect_result_t bef_effect_get_requirment_array(bef_effect_handle_t handle, bef_requirement_new* requirementArray);

// Request to turn certain algorithms on or off
BEF_SDK_API bef_effect_result_t bef_effect_refresh_algorithm_array(bef_effect_handle_t handle, bef_requirement_new algorithmFlag, bool enableRequirment);

// Use specific algorithms
BEF_SDK_API bef_effect_result_t bef_effect_set_external_algorithm_array(bef_effect_handle_t handle, bef_requirement_new algorithmFlag);

// Get the execution time of a specific algorithm
BEF_SDK_API long long bef_effect_get_one_algorithm_execute_time(bef_effect_handle_t handle, bef_requirement_new algorithmType);

// Set additional algorithm parameters
BEF_SDK_API bef_effect_result_t bef_effect_set_algorithm_array_ext_param(bef_effect_handle_t handle, bef_algorithm_array_ext_param* extParam);

/**
 @param handle Effect instance handle
 @param widthPtr Store texture width value
 @param heightPtr Store texture height value
 @param handle effectmanager handle
 @param widthPtr where returned width store, may be a pointer to a stack alloc variable
 @param heightPtr where returned height store, may be a pointer to a stack alloc variable
 @return status
 @note duet mode VE or other caller should create dstTexture of resolution according to return value of this function
*/
BEF_SDK_API bef_effect_result_t bef_effect_get_duet_dst_texture_resolution(bef_effect_handle_t handle, int *widthPtr, int *heightPtr);

/**
VE calls this interface to obtain the AB parameters required by EffectSDK, including the field (key), field type (dataType: Bool, Int, Float, String), default value (defaultValue), AB or Setting, description, assembled into a JSON string

 @return Json string
*/
BEF_SDK_API const char*
bef_effect_request_ab_info();

/**
 @brief VE calls this interface by license to obtain the AB parameters required by EffectSDK, including the field (key), field type (dataType: Bool, Int, Float, String), default value (defaultValue), AB or Setting, description, assembled into a JSON string

 @return Json string
*/
BEF_SDK_API const char*
bef_effect_request_ab_info_with_license(const char* license);

/**
 @brief VE calls this interface by license array to obtain the AB parameters required by EffectSDK, including the field (key), field type (dataType: Bool, Int, Float, String), default value (defaultValue), AB or Setting, description, assembled into a JSON string
 @param licenses license array
 @param length the length of licenses
 @param resStr Store the pointer of the json string (Allocate memory in the effect, need the caller to call bef_effect_free_ab_result_buffer to free)
 @param withDefault Whether resStr contains default AB configuration
 @return status
*/
BEF_SDK_API bef_effect_result_t
bef_effect_request_ab_info_with_license_array(const char** licenses, const int length, char** resStr, const bool withDefault);

/**
 @brief VE calls this interface to free the memory allocated by bef_effect_request_ab_info_with_license_array
 @param buffer the resStr parameter of bef_effect_request_ab_info_with_license_array
 @return status
*/
BEF_SDK_API bef_effect_result_t
bef_effect_free_ab_result_buffer(char** buffer);

/**
 @brief Set the license for the Effect instance
 @param handle Effect instance handle
 @param license license
 
 @return status
 */
BEF_SDK_API bef_effect_result_t 
bef_effect_set_ab_license(bef_effect_handle_t handle, const char* license);

/**
 @brief VE calls this interface to set the AB parameters to effect

 @param key the key of AB
 @param value the value of AB
 @param dataType value datatype(Bool, Int, Float, String):
                        typedef enum {
                            BEF_AB_DATA_TYPE_BOOL = 0,
                            BEF_AB_DATA_TYPE_INT = 1,
                            BEF_AB_DATA_TYPE_FLOAT = 2,
                            BEF_AB_DATA_TYPE_STRING = 3,
                        }bef_ab_data_type;
 @return status
 */
BEF_SDK_API bef_effect_result_t
bef_effect_config_ab_value(const char* key, void* value, int dataType);

/**
 @brief VE calls this interface to get the AB parameter value

 @param key the key of AB
 @param value to store the value of AB
 @param dataType valuse datatype(Bool, Int, Float, String):
                       typedef enum {
                           BEF_AB_DATA_TYPE_BOOL = 0,
                           BEF_AB_DATA_TYPE_INT = 1,
                           BEF_AB_DATA_TYPE_FLOAT = 2,
                           BEF_AB_DATA_TYPE_STRING = 3,
                       }bef_ab_data_type;
 @return status
*/
BEF_SDK_API bef_effect_result_t
bef_effect_get_ab_value(const char* key, void* value, int dataType);

BEF_SDK_API bef_effect_result_t
bef_effect_set_cache_directory(bef_effect_handle_t handle, const char *path);

/**
 @brief In picture mode, open, close, refresh the interface of algorithm cache
 @param state Whether to refresh the algorithm cache, if it is true, execute the algorithm once, cache the result, if it is false, then close the algorithm cache strategy
 @return status
*/

BEF_SDK_API bef_effect_result_t bef_effect_update_algorithm_cache(bef_effect_handle_t handle, bool state, const char* uniqueID);

/**
 * @brief     get xt local edit param
 * @param handle     Effect handle
 * @param tag        Package tag
 * @param pointX     The X coordinate of the trigger point
 * @param pointY     The Y coordinate of the trigger point
 * @param scale     The scale of the current rendering range
 * @param intensity     The intensity of the current render point
 * @param flagMask     Rendering point mask scaling
 * @param pointCount   The total number of rendered points
 * @return           status
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_xt_local_edit_param(bef_effect_handle_t handle, const char* tag, float pointX[], float pointY[], float scale[], float intensity[], float flagMask[], int pointCount);

/**
 * @brief     set skinunified algorithm memory level
 * @param handle     Effect handle
 * @param memoryLevel     algotihm memory level，MAX - Lv1 - Lv2 - MIN = 0 - 1 - 2 - 255
 * @return           if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_skinunified_memory_level(bef_effect_handle_t handle, int memoryLevel);

/**
 * @brief Get a screenshot based on the key
 * @param handle Effect instance handle
 * @param key Key
 * @param image Screenshot data
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_get_captured_image_with_key(bef_effect_handle_t handle, const char* key, bef_image** image);

/**
 * @brief Release screenshot
 * @param handle Effect instance handle
 * @param image Screenshot data(Obtained form bef_effect_get_captured_image_with_key)
 */
BEF_SDK_API void bef_effect_release_captured_image(bef_effect_handle_t handle, bef_image* image);

/**
 * @brief The location and size of the anchor screen in live broadcast
 * @param handle Effect instance handle
 * @param topLeftX Texture topLeft 
 * @param topLeftY Texture topLeft
 * @param width      Texture width
 * @param height     Texture height
 * @return
 */
BEF_SDK_API void bef_effect_set_double_view_rect(bef_effect_handle_t handle, float topLeftX, float topLeftY, float width, float height);

/**
 * @brief                assign external model names,
 *                       if re-assign,  provide new params for 'req' and 'model_names'
 *                       if clear,      provide an empty array for 'req'
 * @param handle         Effect handle
 * @param req            the requirement that your assign model names for，e,g, const char* related_req[2] = {"matting","faceDetect"};
 *                       the requirement must use the assigned models, even if the assigned mdoels is null
 * @param model_names    the names of those model you assigned, e,g, const char* model_names[2] = {"model_1;model_2","model_3;model_4"};
 *                       the requirement must use the assigned models, even if the assigned mdoels is null, so do not assigned null to a requirement
 * @param num            the number of requirement that your want to assign model names
 * @return               return BEF_RESULT_SUC if success
 *
 * @NOTICE               the requirement must use the assigned models, even if the assigned mdoels is null, so do not assigned null to a requirement
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_assigned_model_names(bef_effect_handle_t handle, const char* req[], const char* model_names[], int num);

/**
 * @brief                assign external model names with priority,
 *                       if re-assign,  provide new params for 'req' and 'model_names'
 *                       if clear,      provide an empty array for 'req'
 * @param handle         Effect handle
 * @param req            the requirement that your assign model names for，e,g, const char* related_req[2] = {"matting","hdrnet"};
 *                       the requirement must use the assigned models, even if the assigned mdoels is null
 * @param model_names    the names of those model you assigned, e,g, const char* model_names[2] = {"model_1;model_2","model_3;model_4"};
 *                       the requirement must use the assigned models, even if the assigned mdoels is null, so do not assigned null to a requirement
 * @param req_priorities  the priority of the req.  we will compare all req priority in the effectmanager to choose the one with highest priorty,  and use its models as the final algorithm                                                    model
 * @param num            the number of requirement that your want to assign model names
 * @return               return BEF_RESULT_SUC if success
 *
 * @NOTICE               the requirement must use the assigned models, even if the assigned mdoels is null, so do not assigned null to a requirement
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_assigned_model_names_with_priority(bef_effect_handle_t handle, const char* req[], const char* model_names[], const int* req_priorities, int num);


BEF_SDK_API void bef_effect_set_get_time_func(bef_effect_handle_t handle, double (*getTime)());

/**
 * @brief Get whether the current type is general audio
 * @param handle Effect handle
 * @return             0:yes -1:no
 */
BEF_SDK_API int bef_effect_get_general_audio_status(bef_effect_handle_t handle);

#if BEF_EFFECT_AI_LABCV_TOBSDK
void bef_effect_send_RecodeVedioEvent(bef_effect_handle_t handle);
#endif

// tt
/**
 * @brief              Set application home directory
 * @param              dir application home directory
 * @return             BEF_RESULT_SUC if success.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_documents_dir(const char* dir);
// tmp
 /**
 * @brief called by picture edit app such as XT, should be called after create_handle at once
 * @param handle                   Effect handle
 * @param pictureModeEnable        picture mode enable.
*/
BEF_SDK_API bef_effect_result_t bef_effect_active_xt_algorithm_config(bef_effect_handle_t handle, bool pictureModeEnable);

/**
 * @brief Clear texture pool
 * @param handle   Effect handle
 * @param mode  clear mode. ( #define CLEAR_MODE_TEXTURE_POOL 0x00000001     // clear texture pool
                         #define CLEAR_MODE_HW_TEXTURE_POOL 0x00000002  // force release of unused hardware texture in texture pool
                         #define CLEAR_MODE_UNDO_REDO_CACHE 0x00000004  // clear undo/redo texture cache
                         #define CLEAR_MODE_IMAGE_MANAGER_CACHE 0x00000008  // clear image manager texture cache
                         #define CLEAR_MODE_FBO 0x00000010               // clear FBO
                         #define CLEAR_MODE_ALL 0xFFFFFFFF              // clear all of above)
*/
BEF_SDK_API bef_effect_result_t bef_effect_clear_texture_cache(bef_effect_handle_t handle, unsigned int mode);


/**
 * @brief set xingtu's low memory mode, when true will clear texture pool after draw
 * @param handle   Effect handle
 * @param enable  enable.
*/
BEF_SDK_API bef_effect_result_t bef_effect_set_xt_low_memory_mode(bef_effect_handle_t handle, bool enable);

/**
 * @brief set associated BEFController handle
 * @param handle     Effect handle
 * @param num            the number of requirement that your want to assign model names
*/
BEF_SDK_API bef_effect_result_t bef_effect_set_associated_handle(bef_effect_handle_t handle, void* befController);

/**
 * @brief Set whether it is a dark environment
 * @param handle Effect instance handle
 * @param isAmbientDark Set to true when the environment is dark, other to false
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_ambient_dark_status(bef_effect_handle_t handle, bool isAmbientDark);

BEF_SDK_API bef_effect_result_t bef_effect_get_current_frame_path_buffer_length(bef_effect_handle_t handle, const char* key, unsigned int* clientPathVertexesCount);


BEF_SDK_API bef_effect_result_t bef_effect_get_current_frame_path(bef_effect_handle_t handle, bef_red_envelope_frame_client_path* clientPath);

BEF_SDK_API bef_effect_result_t bef_amazing_ar_update_frame(void* arFrame);

BEF_SDK_API bef_effect_result_t bef_amazing_ar_inject_session(void* session);

BEF_SDK_API bef_effect_result_t bef_amazing_ar_did_update_anchors(void** ptrArray, int count);

BEF_SDK_API bef_effect_result_t bef_amazing_ar_did_remove_anchors(void** ptrArray, int count);

BEF_SDK_API bef_effect_result_t bef_amazing_ar_did_add_anchors(void** ptrArray, int count);

typedef int (*connect_callback)(int status, const char *msg);

typedef int (*transport_callback)(int status, const char *msg);

/**
 * @brief Set ip address and port for preview debugger, only used for Modeo
 * @param handle Effect instance handle
 * @param ip Server ip address
 * @param port Server port
 * @param cb Call when connect is closed.
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_preview_debugger_set_ip(bef_effect_handle_t handle, const char *ip, int port);

#ifdef AMAZING_EDITOR_SDK
/**
 * @brief Set ip address and port for preview client
 * @param handle Effect instance handle
 * @param ip Client ip address
 * @param port Clinet port
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_preview_configure_runtime_client(bef_effect_handle_t handle, const char *ip, int port);
#endif

/**
 * @brief Set connection callback, only used for Modeo
 * @param handle Effect instance handle
 * @param cb Call when connect is closed.
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_preview_debugger_register_connect_callback(bef_effect_handle_t handle, connect_callback cb);

/**
 * @brief Set directory for preview debugger. Tell effect where can save the sticker, only used for Modeo
 * @param handle Effect instance handle
 * @param path The directory path
 * @return If succeed return IES_RESULT_SUC,  other vashi lue please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_preview_debugger_set_directory(bef_effect_handle_t handle, const char *path);

/**
 * @brief Set transport callback, only used for Modeo
 * @param handle Effect instance handle
 * @param cb Call and transfer path of the sticker saved.
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_preview_debugger_register_transport_callback(bef_effect_handle_t handle, transport_callback cb);

/**
 * @brief Get output data that strong related with the output cloud rendering frame
 * @param handle       Effect handle
 * @param cloudName   unique cloud name
 * @param buf              Output data
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_cloud_rendering_extended_output_data(
    bef_effect_handle_t handle,
    const char* cloudName,
    bef_cloud_rendering_extended_output_data* buf);

/**
 * @brief Set the strong related input data to the current cloud rendering frame
 * @param handle       Effect handle
 * @param cloudName   unique cloud name
 * @param buf              Input data
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_cloud_rendering_extended_input_data(
    bef_effect_handle_t handle,
    const char* cloudName,
    const bef_cloud_rendering_extended_input_data* buf);

/**
 * @brief Set the maleOpacity and femaleOpacity for a  sticker
 * @param handle       Effect handle
 * @param path           the abs path of the sticker that we set opacity
 * @param maleOpacity       the percentage of intensity that facemakeup works for male
 * @param femaleOpacity   the percentage of intensity that facemakeup works for female
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_external_FaceMakeup_Opacity(bef_effect_handle_t handle, const char* path, float maleOpacity, float femaleOpacity);

/**
 * @param handle Effect handle that already be created
 * @param result Current algorithm face_result;
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_algorithm_detect_result(bef_effect_handle_t handle,bef_algorithm_data *result);

/**
 * @param handle Effect handle that already be created
 * @param path faceDistortionV3 Path
 * @param keys faceDistortionV3 keys
 * @param values faceDistortionV3 key to value
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_distortion_param(bef_effect_handle_t handle, char** path, char **keyValues);

BEF_SDK_API bef_effect_result_t bef_effect_style_algorithm(bef_effect_handle_t handle, bool enable,bef_requirement_new algorithmFlag);

/**
 * @brief Set algorithm config, only for orion, thread unsafe.
 * @param handle Effect handle
 * @param algorithmConfig bach algorithm config string
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_refresh_bach_algorithm_config(bef_effect_handle_t handle, const char *algorithmConfig);

/**
 * @breif Video background traversing sticker transfer algorithm cpu YUV buffer interface
 * @param handle     Effect handle
 * @param input Input buffer struct
 * @param timeStamp time stamp
 * @return if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_pixel_buffer(bef_effect_handle_t handle, bef_pixel_buffer *input, double timeStamp);
 
/**
 * @brief add bach algorithm config that is set using invoking this interface by VE, thread unsafe.
 * @param handle Effect handle
 * @param graphName bach graph name
 * @param algorithmConfig bach algorithm config string
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_add_bach_algorithm_config(bef_effect_handle_t handle, const char* graphName, const char *algorithmConfig);

/**
 * @brief remove bach algorithm config that is set using invoking the interface(bef_effect_add_bach_algorithm_config) by VE, thread unsafe.
 * @param handle Effect handle
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_remove_all_bach_algorithm_config(bef_effect_handle_t handle);

/**
 * @brief get bach algorithm result(default garph and graphs that is set by interface) by type
 * @param handle Effect handle
 * @param result bach algorithm buffer
 * @param algorithmType bach algorithm Type, see BachAlgorithmConstant.h
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API int bef_effect_get_bach_result(bef_effect_handle_t handle, void** result, int algorithmType);

/**
 * @brief get bach algorithm result(default garph and graphs that is set by interface) by name
 * @param handle Effect handle
 * @param result bach algorithm buffer
 * @param graphNodeName bach algorithm node name
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API int bef_effect_get_bach_result_by_node_name(bef_effect_handle_t handle, void** result, const char* graphNodeName);

/**
 * @brief get bach algorithm result(default garph and graphs that is set by interface) by graph and node name
 * @param handle Effect handle
 * @param result bach algorithm buffer
 * @param graphName bach algorithm graph name
 * @param graphNodeName bach algorithm node name
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API int bef_effect_get_bach_result_by_graph_and_node_name(bef_effect_handle_t handle, void** result, const char* graphName, const char* graphNodeName);

/**
 * @brief set replay algorithm file path
 * @param handle Effect handle
 * @param filePath replay filePath alone with replay video 
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_new_algorithm_replay_path(bef_effect_handle_t handle, const char* filePath);

/**
 * @brief set replay timestamp for index in file
 * @param handle Effect handle
 * @param timestamp replay timestamp
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_new_algorithm_replay_timestamp(bef_effect_handle_t handle, double timestamp);

/**
 * @brief   Sync load object to scene
 * @param   [in] handle              Effect Handle
 * @param   [in] dstPath             The path need to be load
 * @param   [in] associatedID    The target attach point id of loaded part (Add to scene if null)
 * @param   [out] outName           The name of loaded part
 * @return  If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_load_to_scene(bef_effect_handle_t handle, const char* path, const char* associatedID, char* outName);

/**
 * @brief   Sync load to current scene with specific id.
 * @param   [in] handle              Effect Handle
 * @param   [in] path                   The path need to be loaded.
 * @param   [in] originalID   The target attach point id of loaded part (Add to scene if null)
 * @param   [out] result          Result of sync, 0 is loaded, 1 is already exist, 2 is other error
 * @return  If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_load_to_scene_with_id(bef_effect_handle_t handle, const char* path, const char* originalID, int* result);

/**
 * @brief   Remove object in scene
 * @param   [in] handle              Effect Handle
 * @param   [in] ID                       The ID to remove.
 * @param   [in] callback           Callback func.
 * @param   [in] isSync           Whether remove sync.
 * @return  If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_remove_from_scene(bef_effect_handle_t handle, const char* ID, bef_effect_callback callback, bool isSync);

/**
 * @brief   Set property of part in scene.
 * @param   [in] handle              Effect Handle
 * @param   [in] ID           The ID to set property.
 * @param   [in] propValue            The property value to set.
 * @param   [in] callback            Callback func.
 * @param   [in] isSync         Whether set property sync.
 * @return  If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_property(bef_effect_handle_t handle, const char* ID, const char* propertyName, bef_effect_value_param* propValue, bef_effect_callback callback, bool isSync);

/**
 * @brief   Get Proeprty of object in scene.
 * @param   [in] handle              Effect Handle
 * @param   [in] ID            The ID to get property.
 * @param   [in] propertyName            The Property name to set.
 * @param   [out] result            Proprety value.
 * @return  If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_property(bef_effect_handle_t handle, const char* ID, const char* propertyName, bef_effect_value_param* result);

/**
 * @brief   Call method of object in scene.
 * @param   [in] handle              Effect Handle
 * @param   [in] ID             The ID of calling method.
 * @param   [in] methodName            The method name to call.
 * @param   [in] params             Method paramters.
 * @param   [out] result             Method result.
 * @param   [in] callback         Callback func
 * @param   [in] isSync             Whether call method sync.
 * @return  If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_call_method(bef_effect_handle_t handle, const char* ID, const char* methodName, const bef_effect_value_params* params, bef_effect_value_param* result, bef_effect_callback callback, bool isSync);

/**
 * @brief   Set whether use sensor orientation for algorithm
 * @param   [in] handle              Effect Handle
 * @param   [in] flag                  Whether use sensor orientation for algorithm
 * @return  If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
*/
BEF_SDK_API bef_effect_result_t bef_effect_set_use_sensor_orientation_for_algorithm(bef_effect_handle_t handle, bool flag);

/**
 * @brief reset frame cost record
 * @param handle Effect handle
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_reset_frame_cost_statistics(bef_effect_handle_t handle);

/**
 * @brief get frame cost statistics
 * @param handle Effect handle
 * @param statisticsFrameCost frame cost statistics
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_frame_cost_statistics(bef_effect_handle_t handle, bef_statistics_frame_cost* statisticsFrameCost);

/**
 * @brief get error infos from errorManager
 * @param   [in] handle              Effect Handle
 * @param outErrorInfosJson [out] error infos
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_effect_get_error_infos(bef_effect_handle_t handle,
                                char** outErrorInfosJson);

/**
 * @brief free error infos
 * @param   [in] handle              Effect Handle
 * @param outErrorInfosJson error infos to free
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_effect_free_error_infos(bef_effect_handle_t handle,
                                char** outErrorInfosJson);

/**
 * @brief get event tracking data.
 * @param handle Effect handle
 * @param etType event tracking type
 * @param etData event tracking data (Allocate memory in the effect, need the caller to call bef_effect_free_raw_buffer to free)
 * @param size out length
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_et_data(bef_effect_handle_t handle, uint32_t etType, char** etData, int* size);

/**
 * @brief reset event tracking data.
 * @param handle Effect handle
 * @param etType event tracking type
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t bef_effect_reset_et_data(bef_effect_handle_t handle, uint32_t etType);

/**
 * @brief free raw buffer allocated in effect
 * @param handle Effect handle
 * @param rawData raw buffer pointer allocted in effect
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t bef_effect_free_raw_buffer(bef_effect_handle_t handle, void* rawData);

/**
 * @brief check gputurbo cond is satisfied
 * @param handle Effect handle
 * @return is gputurbo cond is satisfied
 */
BEF_SDK_API bool bef_effect_isEnable_gputurbo(bef_effect_handle_t handle);

/**
 * @brief set whether use downscaleTexture from caller
 * @param handle Effect handle
 * @param useDownScaleTex whether use downscale texture
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_use_downscaleTex(bef_effect_handle_t handle, bool useDownScaleTex);

#endif /* bef_effect_h */

