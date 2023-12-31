//
//  bef_effect_bach_api.h
//  byted-effect-sdk
//
// Created by yong.yu on 2021/6/04
//

#ifndef bef_effect_bach_api_h
#define bef_effect_bach_api_h

#include "bef_effect_public_define.h"

typedef void* bef_bach_resource_finder_handle_t; /**< bach resource finder handle*/

/**
 * @brief Create bach resource finder handle.
 * @param handle           [in]  handle used to create bach resource finder.  could use BachAlgorithmSystem*
 * @param resource_finder  [in]  create by VE, use platform-sdk
 * @param finder_handle    [out]  resource finder handle that will be created. call destroy by VE to release memory
 * @return  If succeed return BEF_EFFECT_RESULT_SUC otherwise return BEF_EFFECT_RESULT_FAIL
 */
BEF_SDK_API bef_effect_result_t bef_bach_resource_finder_create(
    bef_effect_handle_t handle,
    bef_resource_finder resource_finder,
    bef_bach_resource_finder_handle_t* finder_handle);

/**
  * @brief Destory bach resource finder handle and helper handle
  * @param handle         [in] bach resource finder handle that will be destroyed
  */
BEF_SDK_API void bef_bach_resource_finder_destroy(
    bef_bach_resource_finder_handle_t handle);

/**
 * @brief get algorithm graph and buffer width,height.
 * @param path              [in]  zip Path or algorithmConfig.json path
 * @param algorithm_json    [out] algorithm graph json format
 * @param view_width        [in]  view width
 * @param view_height       [in]  view height
 * @param buffer_width      [out] algorithm buffer width
 * @param buffer_height     [out] algorithm buffer height
 * @param motion_size       [out] stop_motiion shadow size
 * @return  If succeed return BEF_EFFECT_RESULT_SUC otherwise return BEF_EFFECT_RESULT_FAIL
 */
BEF_SDK_API void bef_bach_get_graph(
    const char* path,
    char** algorithm_json,
    int view_width,
    int view_height,
    int* buffer_width,
    int* buffer_height);

/**
* @brief Destory like algorithm_json content
* @param content         [in] delete content which create in bach_api
*/
BEF_SDK_API void bef_bach_destroy_content(char* content);

/**
* @brief get stop_motion count
* @param path           [in]   zip Path or algorithmConfig.json path
* @param motion_count   [out]  stop_motion count
*/
BEF_SDK_API void bef_bach_get_stop_motion_count(const char* path, int* motion_count);

/**
* @brief get stop_motion count
* @param path           [in]   zip Path or algorithmConfig.json path
* @param threshold      [out]  guarantee_threshold
*/
BEF_SDK_API bef_effect_result_t bef_bach_get_stop_motion_threshold(const char* path, float* threshold);

/**
 * @brief convert BachBuffer to serialize result only use stop-motion and will delete in future
 * @param serialize_buffer      [in] algorithm bach stopMotionBuffer serialize array.
 * @param size                  [in] stopMotionBuffer array num
 * @param bachbuffer            [out] new stopMotionBuffer
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_bach_get_stop_motion_buffer(char** serialize_buffer, int size, int type, void** bach_buffer);

/**
 * @brief convert BachBuffer to serialize result only use stop-motion and will delete in future
 * @param bachbuffer            new stopMotionBuffer
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_bach_delete_stop_motion_buffer(void* bach_buffer);


/**
 * @brief convert brush points to a mask
 * @param points_array      brush points: x1, y1, x2, y2...
 * @param array_length      length of points_array
 * @param thickness         thickness of brush, unit: pixel
 * @param width             mask width
 * @param height            mask height
 * @param bachbuffer        new brushMaskBuffer, format: CV_8UC4
 * @return                  If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_bach_get_brush_mask(float* points_array, int array_length, int thickness, int width, int height, unsigned char** bach_buffer);


/**
 * @brief delete brushMaskBuffer
 * @param bachbuffer            brushMaskBuffer
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_bach_delete_brush_mask(unsigned char* bach_buffer);

#endif /* bef_effect_bach_api_h */
