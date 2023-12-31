/**
 * @file bef_swing_segment_video_api.h
 * @author yankai.ff (yankai.ff@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2021-11-17
 * 
 * @copyright Copyright (c) 2021
 * 
 */

#ifndef bef_swing_segment_video_api_h
#define bef_swing_segment_video_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h" // BEF_SDK_API

/**
 * @brief create feature segment in video segment
 * @param videoHandle instance of video segment
 * @param outFeatureHandle [out] instance of feature segment
 * @param path feature segment resource path
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_create_feature(bef_swing_segment_t* videoHandle,
                                       bef_swing_segment_t** outFeatureHandle,
                                       const char* path);

/**
 * @brief add feature segment into video segment
 * @param videoHandle instance of video segment
 * @param featureHandle instance of feature segment
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_add_feature(bef_swing_segment_t* videoHandle,
                                    bef_swing_segment_t* featureHandle);

/**
 * @brief create custom segment in video segment
 * @param videoHandle instance of video segment
 * @param outCustomHandle [out] instance of custom segment
 * @param path nullptr
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_create_custom(bef_swing_segment_t* videoHandle,
                                       bef_swing_segment_t** outCustomHandle,
                                       const char* path);


/**
 * @brief add custom segment into video segment
 * @param videoHandle instance of video segment
 * @param customHandle instance of custom segment
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_add_custom(bef_swing_segment_t* videoHandle,
                                    bef_swing_segment_t* customHandle);

/**
 * @brief set video segment input texture Id
 * @param segmentHandle instance of video segment
 * @param videoTextureId video texture for VideoSegment
 * @param videoWidth video texture width
 * @param videoHeight video texture height
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_texture(bef_swing_segment_t* segmentHandle,
                                    unsigned int videoTextureId,
                                    unsigned int videoWidth,
                                    unsigned int videoHeight);

/**
 * @brief set video segment input texture handle
 * @param segmentHandle instance of video segment
 * @param videoTexture video texture handle for VideoSegment
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_device_texture(bef_swing_segment_t* segmentHandle,
                                           device_texture_handle videoDeviceTexture);

/**
 * @brief set video transform information by VideoTransfrom structure
 * @param segmentHandle instance of segment
 * @param transform instance of video transform structure
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_transform(bef_swing_segment_t* segmentHandle,
                                      bef_video_transform_t* transform);

/**
 * @brief get current video transform information by VideoTransfrom structure
 * @param segmentHandle instance of segment
 * @param[out] outTansform returned video transform structure
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_get_transform(bef_swing_segment_t* segmentHandle,
                                      bef_video_transform_t* outTransform);

/**
 * @brief set video adapt scale
 * 
 * All scaling operations will be internally muliplied by the adapt scale.
 * e.g. for adaptScale=2.0, calling bef_swing_segment_video_set_transform
 * with scale=1.5 results in actual scaling of video by 1.5 * 2.0 = 3.0.
 * 
 * The API should be called when the video size or canvas size changes.
 * 
 * @param segmentHandle instance of video segment
 * @param adaptScale video adapt scale
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_adapt_scale(bef_swing_segment_t* segmentHandle,
                                        double adaptScale);

/**
 * @brief set video segment background texture Id
 * @param segmentHandle instance of video segment
 * @param backgroundTextureId background texture for VideoSegment
 * @param backgroundWidth background texture width
 * @param backgroundHeight background texture height
 * @return BEF_SDK_API
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_background_texture(bef_swing_segment_t* segmentHandle,
                                               unsigned int backgroundTextureId,
                                               unsigned int backgroundWidth,
                                               unsigned int backgroundHeight);

/**
 * @brief set video segment background texture handle
 * @param segmentHandle instance of video segment
 * @param backgroundTexture background texture handle for VideoSegment
 * @return BEF_SDK_API
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_background_device_texture(bef_swing_segment_t* segmentHandle,
                                                      device_texture_handle backgroundDeviceTexture);

/**
 * @brief set video segment anim
 * @param segmentHandle instance of video segmetn
 * @param animPath anim resource package path for VideoSegment
 * @param startTime anim start time for VideoSegment, in microsecond
 * @param endTime anim end time for VideoSegment, in microsecond
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_animation(bef_swing_segment_t* segmentHandle,
                                      const char* animPath,
                                      bef_swing_time_t startTime,
                                      bef_swing_time_t endTime);

/**
 * @brief set video segment anim with animType
 * @param segmentHandle instance of video segmetn
 * @param animPath anim resource package path for VideoSegment
 * @param animType type (in/out/combo) of anim in one VideoSegment
 * @param startTime anim start time for VideoSegment, in microsecond
 * @param endTime anim end time for VideoSegment, in microsecond
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_animation_with_type(bef_swing_segment_t* segmentHandle,
                                      const char* animPath,
                                      uint32_t animType,
                                      bef_swing_time_t startTime,
                                      bef_swing_time_t endTime);

/**
 * @brief set video segment blend mode
 * @param segmentHandle instance of stick segment
 * @param blendPath blend mode path, nullptr represent default blend mode
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_blend(bef_swing_segment_t* segmentHandle,
                                  const char* blendPath);

/**
 * @brief set video type
 * @param segmentHandle instance of video segment
 * @param srcVideoType 0 -- normal(video) 1 -- image
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_video_type(bef_swing_segment_t* segmentHandle,
                                       bef_video_type srcVideoType);


/**
 * @brief  Is need execute algorithm
 * @param  segmentHandle instance of video segment
 * @param  [out] need_update_algorithm return 1 if need update algorithm, return 0 otherwise
 * @param timestamp time stamp of current frame, in microsecond
 * @return Successful return
 *        BEF_RESULT_SUC
 *     Fail return
 *        BEF_RESULT_FAIL
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_check_algorithm_update(bef_swing_segment_t* segmentHandle, int* need_update_algorithm , bef_swing_time_t timestamp);

/**
 * @brief  Get algorithm need buffer width and height
 * @param  segmentHandle instance of video segment
 * @param  [out] buffer_width  algorithm buffer width
 * @param  [out] buffer_heigt algorithm buffer height
 * @return Successful return
 *        BEF_RESULT_SUC
 *     Fail return
 *        reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_get_algorithm_width_height(bef_swing_segment_t* segmentHandle, unsigned int *buffer_width, unsigned int *buffer_heigt);


/**
 * @brief  Update algorithm
 * @param  segmentHandle instance of video segment
 * @param  [in] buffer   input algorithm buffer,  buffer data format must be RGBA8888 or it is a native buffer
 * @param  [in] buffer_type input buffer type, 0 is cpu buffer ,1 is native buffer(CVPixelBuffer/AHardwareBuffer)
 * @param  [in] input_width  input buffer width
 * @param  [in] input_height input buffer height
 * @return Successful return
 *        BEF_RESULT_SUC
 *     Fail return
 *        reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_video_set_algorithm_buffer(bef_swing_segment_t* segmentHandle, void* buffer, int buffer_type, unsigned int buffer_width, unsigned int buffer_height);


#endif /* bef_swing_segment_video_api_h */
