#ifndef BEF_AE_BRICK_API_H
#define BEF_AE_BRICK_API_H

#include "bef_effect_public_define.h"
#include <stdbool.h>

typedef void* bef_ae_brick_engine_handle;
typedef void* bef_brick_handle;

/**
 * @brief   Create an amazing brick engine handle.
 * @param   [out] handle    bef_ae_brick_engine_handle handle
 * @param   [in]  width     Background texture pixel width
 * @param   [in]  height    Background texture pixel height
 * @param   [in]  rootDir   rootDir for load resource
 */ 
BEF_SDK_API bef_effect_result_t bef_ae_brick_engine_create(
    bef_ae_brick_engine_handle* engine_handle, const char* rootDir);

/**
 * @brief   Add a brick to scene
 * @param   [in]   engine_handle   bef_ae_brick_engine_handle handle
 * @param   [out]  brick           brick_handle
 * @param   [in]   brickPath       brick resource path
 * @param   [in]   layer           entity layer, default == -1
 * @param   [in]   target          Target brick handle
 * @param   [in]   entityName      Target entityName in target brick
 * @param   [in]   json            default parameters
 */
BEF_SDK_API bef_effect_result_t bef_ae_brick_add(
    bef_ae_brick_engine_handle engine_handle, bef_brick_handle *brick, const char *brickPath, const int layer, bef_brick_handle target, const char* entityName, const char* json);

/**
 * @brief   Remove a brick in scene
 * @param   [in]    engine_handle  bef_ae_brick_engine_handle handle
 * @param   [in]    brick          The handle of the brick which needs to be removed
 */
BEF_SDK_API bef_effect_result_t bef_ae_brick_remove(
    bef_ae_brick_engine_handle engine_handle, bef_brick_handle brick);

/**
 * @brief   Clear all bricks in scene
 * @param   [in]    engine_handle  bef_ae_brick_engine_handle handle
 */
BEF_SDK_API bef_effect_result_t bef_ae_brick_clear(
    bef_ae_brick_engine_handle engine_handle);

BEF_SDK_API bef_effect_result_t bef_ae_brick_on_event(
    bef_ae_brick_engine_handle engine_handle, const char *event, bef_brick_handle entityBrick);

/**
 * @brief   ProcessTexture every frame
 * @param   [in]    engine_handle  bef_ae_brick_engine_handle handle
 * @param   [in]    inputTexture
 * @param   [out]   outputTexture
 * @param   [in]    time           timeStamp of the video
 * @param   [in]    width          screen size width
 * @param   [in]    height         screen size height
 * @param   [in]    isYFlip        Indicate if the Y axis need to be flipped
 */
BEF_SDK_API bef_effect_result_t bef_ae_brick_process(
    bef_ae_brick_engine_handle engine_handle, unsigned int inputTexture, unsigned int outputTexture, double time, unsigned int width, unsigned int height, bool isYFlip);

/**
 * @brief   Destroy the Manager
 * @param   [in]    engine_handle  bef_ae_brick_engine_handle handle
 */
BEF_SDK_API bef_effect_result_t bef_ae_brick_engine_destroy(
    bef_ae_brick_engine_handle engine_handle);

BEF_SDK_API bef_effect_result_t bef_ae_brick_add_camera(bef_ae_brick_engine_handle engine_handle, unsigned int layer);

/**
 * @brief   set camera world position
 * @param   [in]    engine_handle  bef_ae_brick_engine_handle handle
 * @param   [in]    layer          Find camera by layer
 * @param   [in]    x              world position x
 * @param   [in]    y              world position y
 * @param   [in]    z              world position z
 */
BEF_SDK_API bef_effect_result_t bef_ae_brick_set_camera_world_position(bef_ae_brick_engine_handle engine_handle, unsigned int layer, float x, float y, float z);

BEF_SDK_API bef_effect_result_t bef_ae_brick_get_camera_world_position(bef_ae_brick_engine_handle engine_handle, unsigned int layer, float* x, float* y, float* z);

BEF_SDK_API bef_effect_result_t bef_ae_brick_set_camera_world_orientation(bef_ae_brick_engine_handle engine_handle, unsigned int layer, float x, float y, float z);

BEF_SDK_API bef_effect_result_t bef_ae_brick_get_camera_world_orientation(bef_ae_brick_engine_handle engine_handle, unsigned int layer, float* x, float* y, float* z);

BEF_SDK_API bef_effect_result_t bef_ae_brick_set_camera_type(bef_ae_brick_engine_handle engine_handle, unsigned int layer, bool isOrtho);

BEF_SDK_API bef_effect_result_t bef_ae_brick_set_world_position(bef_ae_brick_engine_handle engine_handle, bef_brick_handle brickHandle, float x, float y, float z);

BEF_SDK_API bef_effect_result_t bef_ae_brick_get_world_position(bef_ae_brick_engine_handle engine_handle, bef_brick_handle brickHandle, float *x, float *y, float *z);

BEF_SDK_API bef_effect_result_t bef_ae_brick_set_world_scale(bef_ae_brick_engine_handle engine_handle, bef_brick_handle brickHandle, float x, float y, float z);

BEF_SDK_API bef_effect_result_t bef_ae_brick_get_world_scale(bef_ae_brick_engine_handle engine_handle, bef_brick_handle brickHandle, float *x, float *y, float *z);

BEF_SDK_API bef_effect_result_t bef_ae_brick_set_world_orientation(bef_ae_brick_engine_handle engine_handle, bef_brick_handle brickHandle, float x, float y, float z);

BEF_SDK_API bef_effect_result_t bef_ae_brick_get_world_orientation(bef_ae_brick_engine_handle engine_handle, bef_brick_handle brickHandle, float *x, float *y, float *z);

/**
 * @brief   set brick params. For component brick, set scriptComponent's property. For entity brick, TODO
 * @param   [in]    engine_handle bef_ae_brick_engine_handle handle
 * @param   [in]    brick_handle  the handle of brick
 * @param   [in]    params        json format
 */
BEF_SDK_API bef_effect_result_t bef_ae_brick_set_brick_params(bef_ae_brick_engine_handle engine_handle, bef_brick_handle brickHandle, float startWorkTime, float endWorkTime, const char* json);

BEF_SDK_API bef_effect_result_t bef_ae_brick_get_resource_path(bef_ae_brick_engine_handle engine_handle, bef_brick_handle brickHandle, char* resPath, unsigned int size);

/**
 * @brief  set MSAA Mode of the scene
 * @param  [in]     engine_handle  bef_ae_brick_engine_handle handle
 * @param  [in]     msaaMode       0: NONE, 1: _4X, 2: _16X, 3: COUNT
 */
BEF_SDK_API bef_effect_result_t bef_ae_brick_set_msaa_mode(bef_ae_brick_engine_handle engine_handle, const unsigned int msaaMode);

/**
 * @brief  set brick param file's path
 * @param  [in]     engine_handle  bef_ae_brick_engine_handle handle
 * @param  [in]     brickHandle    the handle of brick
 * @param  [in]     param file's abs path      dataAbsPath
 */
BEF_SDK_API bef_effect_result_t bef_ae_brick_set_data_file_path(bef_ae_brick_engine_handle engine_handle, bef_brick_handle brickHandle, const char* dataAbsPath);
#endif