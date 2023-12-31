/**
 * @file bef_swing_key_frame_api.h
 * @author wujiajie (wujiajie.hogaki@bytedance.com)
 * @brief new keyFrame API based on Swing
 * @version 0.1
 * @date 2022-12-15
 *
 * @copyright Copyright (c) 2022
 *
 */

#ifndef bef_swing_key_frame_api_h
#define bef_swing_key_frame_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h" // BEF_SDK_API

/**
 * @brief 创建一个关键帧系统，关键帧系统的顺序根据创建顺序决定
 * @param segmentHandle [in] segmentHandle, segment who host this keyFrame system
 * @param outKeyframeHandle [out] outPut Keyframe Handle
 * @param strJson [in] json file with complete protocol informations
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_key_frame_create(bef_swing_segment_t* segmentHandle,
                           bef_keyframe_t** outKeyframeHandle,
                           const char* strJson);
/**
 * @brief 删除关键帧系统
 * @param segmentHandle [in] segmentHandle, segment who host this keyFrame system
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_key_frame_remove(bef_swing_segment_t* segmentHandle);

/**
 * @brief 设置关键帧的属性，支持增量方式设置JSON,
 * 可以单独设置一个关键帧，单关键帧组不能再拆分，也就是要完整的关键帧组信息
 * 例如： { "k": { "r": [...] } }
 * 设置某个关键帧数行为空的组表示删除这个关键帧组
 * 例如： { "k": { "r": [] } }
 * @param keyframeHandle [in] keyFrame system handle
 * @param strJson [in] the json protocol file that supports full or incremental setting informations
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_key_frame_set_config(bef_keyframe_t* keyframeHandle,
                               const char* strJson);

/**
 * @brief 给定属性名字，删除关键帧系统中该属性
 * @param keyframeHandle [in] keyFrame system handle
 * @param attributeName [in] attributeName to be deleted
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_key_frame_remove_attribute(bef_keyframe_t* keyframeHandle,
                              char* attributeName);

/**
 * @brief 全量获取关键帧配置
 * @param keyframeHandle [in] keyFrame system handle
 * @param outConfigStr [out] outPut config files contain complete protocol informations
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_key_frame_get_config(bef_keyframe_t* keyframeHandle,
                               char** outConfigStr);

/**
 * @brief 删除关键帧返回的配置
 * @param keyframeHandle [in] keyFrame system handle
 * @param configStr [out] outPut config files to be delete
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_key_frame_del_config(bef_keyframe_t* keyframeHandle,
                              char* configStr);

#endif /* bef_swing_key_frame_api_h */
