/**
 * @file bef_swing_track_api.h
 * @author wangyu (wangyu.sky@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2021-04-14
 * 
 * @copyright Copyright (c) 2021
 * 
 */

#ifndef bef_swing_track_api_h
#define bef_swing_track_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h"

/**
 * @brief create swing track in swing manager
 * @param managerHandle instance of swing manager
 * @param outTrackHandle [out] instance of swing track
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_track_create(bef_swing_manager_t* managerHandle,
                       bef_swing_track_t** outTrackHandle);

/**
 * @brief destroy swing track
 * @param trackHandle instance of swing track
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_track_destroy(bef_swing_track_t* trackHandle);

/**
 * @brief set track params
 * @param trackHandle instance of swing track 
 * @param jsonParamStr json params，e.g. {key:value, ...}
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_track_set_params(bef_swing_track_t* trackHandle,
                           const char* jsonParamStr);

/**
 * @brief get track params
 * @param trackHandle instance of swing track 
 * @param jsonKeyStr json key
 * @param outJsonParamStr [out] json params, e.g. {key:value, ...}, string need deleted by users
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_track_get_params(bef_swing_track_t* trackHandle,
                           const char* jsonKeyStr,
                           char** outJsonParamStr);

/**
 * @brief set track layer, if layer has been existed, then return failed
 * @param trackHandle instance of swing track 
 * @param layer layer of swing track, use to sort track by increasing order
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_track_set_layer(bef_swing_track_t* trackHandle,
                          int layer);

/**
 * @brief get track layer
 * @param trackHandle instance of swing track 
 * @param layer [out] layer of swing track, use to sort track by increasing order
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_track_get_layer(bef_swing_track_t* trackHandle,
                          int* layer);

#endif /* bef_swing_track_api_h */