//
//  bef_effect_xt.h
//  effect_sdk
//
//  Created by camusli on 2019/11/14.
//

#ifndef bef_effect_xt_h
#define bef_effect_xt_h

#include "bef_effect_api.h"
#include "bef_effect_public_define.h"
#include "bef_effect_xt_define.h"

//NAMESPACE_BEF_EFFECT_FRAMEWORK_USING

/**
 * @brief Get manual liquefaction vertex buffer size
 * @param handle        Effect handle
 * @param nodePath      The absolute path of the node resource package can be used to specify the feature. Generally, there is only one manual liquefaction feature
 * @return              If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API int
bef_effect_xt_get_liquefy_vertex_buffer_size(bef_effect_handle_t handle,const char* nodePath);

/**
 * @brief Get manual liquefaction vertex data
 * @param handle           Effect handle
 * @param nodePath         The absolute path of the node resource package can be used to specify the feature.
 * @param buffer           Buffer pointer for storing vertices
 * @param len              The length of buffer array
 * @return           If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_xt_get_liquefy_vertex_state(bef_effect_handle_t handle, const char* nodePath, float *buffer, int len);

/**
 * @brief Set manual liquefaction vertex data
 * @param handle           Effect handle
 * @param nodePath         he absolute path of the node resource package can be used to specify the feature.
 * @param buffer           Buffer pointer for storing vertices
 * @param len              The length of buffer array
 * @return           If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_xt_set_liquefy_vertex_state(bef_effect_handle_t handle,const char* nodePath, float *buffer, int len);

/**
 * @brief Set manual reshape input image size
 * @param handle           Effect handle
 * @param nodePath         he absolute path of the node resource package can be used to specify the feature.
 * @param width            original image width
 * @param height           original image height
 * @return           If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_xt_set_reshape_input_pic_size(bef_effect_handle_t handle,const char* nodePath, int width, int height);

/**
 * @brief Set manual reshape rect
 * @param handle           Effect handle
 * @param nodePath         he absolute path of the node resource package can be used to specify the feature.
 * @param rect             rect info of selected domain
 * @param type             type of reshape(QUADRESHAPE or ELLIPSESHAPE)
 * @return           If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_xt_set_reshape_rect_domain(bef_effect_handle_t handle,const char* nodePath, const ManualReshapeRectDomain* rect, ManualReshapeType type);
/**
 * @brief Set manual reshape stretch param
 * @param handle           Effect handle
 * @param nodePath         he absolute path of the node resource package can be used to specify the feature.
 * @param param            stretch param, include bottomY coordinate, upY coordinate, target width, target height and thresh intensity
 * @return           If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_xt_set_reshape_stretch_param(bef_effect_handle_t handle,const char* nodePath, const ManualReshapeStretchParam* param);

/**
 * @brief Get manual reshape real pic domain after stretch
 * @param handle           Effect handle
 * @param nodePath         he absolute path of the node resource package can be used to specify the feature.
 * @param rect             get real pic domain param, (0, 0) is at bottom left corner, and rect contains left, right, bottom, up value and is measured in pixel
 * @return                 If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_xt_get_pic_domain(bef_effect_handle_t handle,const char* nodePath, ManualPicDomainParam* rect);
#endif /* byted_effect_xt_h */

