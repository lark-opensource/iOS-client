//
//  bef_effect_3d_object_manipulate_api.h
//  effect_sdk
//
//  Created by Helen on 2018/5/6.
//

#ifndef bef_effect_3d_object_manipulate_api_h
#define bef_effect_3d_object_manipulate_api_h

#include <stdio.h>
#include "bef_effect_public_define.h"

typedef enum {
    BEF_3D_OBJECT_TYPE_NORMAL = 1, /// Ordinary 3D model
    BEF_3D_OBJECT_TYPE_TEXT = 2,   // 3D text
} bef_3d_object_type;



/**
 * @brief 3D model modification
 * @param handle effect_sdk_handle
 * @return whether succeed.
 */
BEF_SDK_API bef_effect_result_t bef_effect_modify_3d_object_operation(bef_effect_handle_t handle);

/**
 * @brief A 3D model modification operation starts
 * @param handle effect_sdk_handle
 * @return whether succeed.
 */
BEF_SDK_API bef_effect_result_t bef_effect_begin_modifing_3d_object_operation(bef_effect_handle_t handle);

/**
 * @brief A 3D model modification operation ends
 * @param handle effect_sdk_handle
 * @return whether succeed.
 */
BEF_SDK_API bef_effect_result_t bef_effect_end_modifing_3d_object_operation(bef_effect_handle_t handle);

/**
 * @brief Complete 3D model production
 * @param handle effect_sdk_handle
 * @return whether succeed.
 */
BEF_SDK_API bef_effect_result_t bef_effect_finish_modifing_3d_object(bef_effect_handle_t handle);

/**
 * @note The obtained data needs to be released by the business party
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_3d_object_mesh_data(bef_effect_handle_t handle, unsigned char **binary_data, unsigned int *binary_data_length);

/**
 * @note After calling this method, the business party is responsible for releasing data
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_3d_object_mesh_with_data(bef_effect_handle_t handle, const unsigned char *binary_data, const unsigned int binary_data_length);

BEF_SDK_API bef_effect_result_t bef_effect_save_3d_object_mesh_data(bef_effect_handle_t handle, const char * filePath);

#endif /* bef_effect_3d_object_manipulate_api_h */
