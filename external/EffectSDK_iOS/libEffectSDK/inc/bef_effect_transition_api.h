//
//  bef_effect_transition_api.h
//
//  Created by lvqingyang on 2019/7/15.
//

#ifndef bef_effect_transition_api_h
#define bef_effect_transition_api_h

#include "bef_effect_public_define.h"
#include "bef_effect_public_business_mv_define.h"
/**
 * @brief                   Set the transition resource package path
 * @param handle            Effect handle
 * @param transition_path   the transition resource package path
 * @return                  If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_transition(bef_effect_handle_t handle, const char *transition_path);

/**
 * @brief Get current transition resource package path
 * @param handle            Effect handle
 * @param transition_path   the transition resource package path
 * @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_current_transition(bef_effect_handle_t handle, char *transition_path);

/**
 * @brief           Set resolution
 * @param handle    Effect handle
 * @param width     Texture width
 * @param height    Texture height
 * @return          If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_resolution(bef_effect_handle_t handle, int width, int height);

/**
 * @brief           Set the total duration of the transition
 * @param handle    Effect handle
 * @param duration  Unit us
 * @return          If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_transition_duration(bef_effect_handle_t handle, double duration);

/**
 * @brief           Set the timeout for resource loading
 * @param handle    Effect handle
 * @param timeoutUs Unit us, When timeoutUs = -1, the resource returns synchronously after loading. When timeoutUs = 0, asynchronous loading does not wait
 * @return          If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_transition_load_resource_timeout_us(bef_effect_handle_t handle, int timeoutUs);

/**
 * @brief                   Failure may be returned when the resource is not loaded. The resource loading timeout can be set by bef_effect_mv_set_resource_load_timeout_us interface.
 * @param handle            Effect handle
 * @param progress          timestamp
 * @param resources         Input resources
 * @param resources_count   The length of resources array
 * @return                  If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_seek_transition(bef_effect_handle_t handle, double progress, bef_mv_input_resource *resources, int resources_count, unsigned int output_texture);

/**
 * @brief                   Failure may be returned when the resource is not loaded. The resource loading timeout can be set by bef_effect_mv_set_resource_load_timeout_us interface.
 * @param handle            Effect handle
 * @param progress          timestamp
 * @param resources         Input resources
 * @param resources_count   The length of resources array
 * @return                  If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_seek_transition_device_texture(bef_effect_handle_t handle, double progress, bef_mv_input_resource_device_texture* resources_device_texture, int resources_count, device_texture_handle output_device_texture);

/**
 * @brief            reset m_currDescriptorTimeRangeIndex for algorithm detect if the mv transition has more than 3 fragments
 * @param handle           Effect handle
 * @return           If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_reset_transition_rebuildfeature(bef_effect_handle_t handle);

#endif /* bef_effect_transition_api_h */
