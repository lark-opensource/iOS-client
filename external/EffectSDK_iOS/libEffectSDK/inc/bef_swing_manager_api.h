/**
 * @file bef_swing_manager_api.h
 * @author wangyu (wangyu.sky@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2021-04-14
 * 
 * @copyright Copyright (c) 2021
 * 
 */

#ifndef bef_swing_manager_api_h
#define bef_swing_manager_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h"
#include "bef_info_sticker_api.h" // bef_InfoSticker_*
#include "bef_effect_touch_api.h"


/**
 * @brief create swing manager
 * @param outManagerHandle [out] instance of swing manager
 * @param width viewer width
 * @param height viewer height
 * @param resourceFinder resource finder function, used by ALGORITHM to find model
 * @param algorithmAsync [DEPRECATED] update algorithm in async. thread, default value is false
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_create(bef_swing_manager_t** outManagerHandle,
                         unsigned int width,
                         unsigned int height,
                         bef_resource_finder ResourceFinder,
                         bool algorithmAsync);

/**
 * @brief create swing manager with custom gpdevice
 * @param outManagerHandle [out] instance of swing manager
 * @param width viewer width
 * @param height viewer height
 * @param resourceFinder resource finder function, used by ALGORITHM to find model
 * @param algorithmAsync [DEPRECATED] update algorithm in async. thread, default value is false
 * @param gpdevice GPDevice handle
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_create_with_gpdevice(bef_swing_manager_t** outManagerHandle,
                                       unsigned int width,
                                       unsigned int height,
                                       bef_resource_finder ResourceFinder,
                                       bool algorithmAsync,
                                       gpdevice_handle gpdevice);

/**
 * @brief swing manager set resource finder
 * @param managerHandle 
 * @param resourceFinder 
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_resource_finder(bef_swing_manager_t* managerHandle,
                                      bef_resource_finder resourceFinder);

/**
 * @brief destroy swing manager
 * @param managerHandle instance of swing manager
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_destroy(bef_swing_manager_t* managerHandle);

/**
 * @brief set common parameters of swing manager
 * @param managerHandle instance of swing manager
 * @param jsonParamStr json params
 *                      {
 *                          "algorithmParams":  {
 *                                                  "vide_feature_algorithm_force_detect": true/false
 *                                                  "video_feature_algorithm_texture_orientation": 0/1/2/3(0/90/180/270)
 *                                              }
 *                      }
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_params(bef_swing_manager_t* managerHandle,
                             const char* jsonParamStr);

/**
 * @brief get swing params
 * @param managerHandle instance of swing manager
 * @param jsonKeyStr json key [ "algorithmParams", "UseTrackAlgorithm" ]
 * @param outJsonParamStr [out] {} [TODO]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_get_params(bef_swing_manager_t* managerHandle,
                             const char* jsonKeyStr,
                             char** outJsonParamStr);

/**
 * @brief set swing manager's parameter with boolean.
 * @param handle instance of swing manager
 * @param name parameter's name, include: ["UseTrackAlgorithm", ]
 * @param value true/false
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_parameter_bool(bef_swing_manager_t* handle,
                                     const char* name,
                                     bool value);

/**
 * @brief set viewer size of swing manager
 * @param managerHandle instance of swing manager
 * @param width viewer width
 * @param height viewer height
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_screen_size(bef_swing_manager_t* managerHandle,
                                  unsigned int width,
                                  unsigned int height);


/**
 * @brief pass VE color space setting to swing manager
 * @param managerHandle instance of swing manager
 * @param colorSpace CSF_709_LINEAR = 0, CSF_709_NO_LINEAR = 1, CSF_2020_HLG_LINEAR = 2, CSF_2020_HLG_NO_LINEAR = 3,  CSF_2020_PQ_LINEAR = 4, CSF_2020_PQ_NO_LINEAR = 5
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_ve_colorspace(bef_swing_manager_t* managerHandle,
                                    int colorSpace);


/**
 * @brief set current update mode
 * 
 * SEEK mode : playback is paused and the user is editing the draft
 * UPDATE mode : "normal" playback scenarios including effect preview, draft playback and export
 * 
 * @param managerHandle instance of swing manager
 * @param updateMode update mode value (0 - SEEK, 1 - UPDATE; default value is 1 - UPDATE)
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_update_mode(bef_swing_manager_t* managerHandle,
                                  int updateMode);

/**
 * @brief set whether to enable low memory mode
 * 
 * If enabled, temporary RTs will be released after feature render
 * 
 * @param managerHandle instance of swing manager
 * @param enable 
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_low_memory_mode_enabled(bef_swing_manager_t* managerHandle,
                                              bool enable);

/**
 * @brief set algorithm cache folder path
 * @param managerHandle instance of swing manager
 * @param cacheFolderPath cache folder path
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_algorithm_cache_folder_path(bef_swing_manager_t* managerHandle,
                                                  const char* cacheFolderPath);

/**
 * @brief sticker pin set restore mode
 * 
 * NOTE: this setting applies to ALL stickers
 * 
 * @param managerHandle instance of swing manager
 * @param mode BEF_INFOSTICKER_PIN_RESTORE_ORIGIN : Pin coordinates are not affected by canvas size, BEF_INFOSTICKER_PIN_RESTORE_NORMALIZED : Pin coordinates are affected by canvas size.
 * @return BEF_SDK_API
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_sticker_pin_restore_mode(bef_swing_manager_t* managerHandle,
                                               bef_InfoSticker_pin_restore_mode mode);

/**
 * @deprecated Legacy API, The Swing framework has enabled the NodeGraph feature by default from EffectSDK version 1290.
 *
 * @brief [DEPRECATED] No-op as of 1250. Swing always uses node graph implementation.
 *
 * @param managerHandle instance of swing manager
 * @param enable indicates NodeGraph feature enable or not
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_nodegraph_enabled(bef_swing_manager_t* managerHandle,
                                        bool enable);

/**
 * @breif set whether to enable memory manager
 *
 * @param managerHandle instance of swing manager
 * @param enable indicates enable or disable current feature
 *
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_memory_manager_enabled(bef_swing_manager_t* managerHandle,
                                        bool enable);

/**
 * @brief get track number of swing manager
 * @param managerHandle instance of swing manager
 * @param count [out] tracker count 
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_get_track_count(bef_swing_manager_t* managerHandle,
                                  unsigned int* count);

/**
 * @brief seek to current frame
 * 
 * The input and output textures MUST have the same dimension as the manager screen
 * 
 * @param managerHandle instance of swing manager
 * @param timestamp time stamp of current frame, in microsecond
 * @param inputTextureId input texture id
 * @param outputTextureId output texture id
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_seek_frame(bef_swing_manager_t* managerHandle,
                             bef_swing_time_t timestamp,
                             int inputTextureId,
                             int outputTextureId);

/**
 * @brief update current frame, include algorithm[render thread]
 * @param swingHandler isntance of swing manager
 * @param timestamp time stamp of current frame, in microsecond
 * @param inputDeviceTex original device texture handle
 * @param outputDeviceTex final device texture handle
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_seek_frame_device_texture(bef_swing_manager_t* swingHandler,
                                            bef_swing_time_t timestamp,
                                            device_texture_handle inputDeviceTex,
                                            device_texture_handle outputDeviceTex);

/**
 * @brief set the dedicated memory Usage. (0.0~1.0)
 * 
 * @param managerHandle 
 * @param percentLimit 
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_gpu_memory_limit(bef_swing_manager_t* managerHandle, float percentLimit);

/**
 * @brief set animation sequence async preload count (default 0)
 *
 * This will overwrite default settings obtained from EffectABConfig.
 *
 * @param managerHandle instance of swing manager
 * @param async_preload_count animation sequence async preload count
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_anim_seq_async_preload_count(bef_swing_manager_t* managerHandle,
                                                   int async_preload_count);

/**
 * @brief set animation sequence cache limit  (default 0)
 *
 * [DEPRECATED] No-op as of 1350. Swing always capitalizes <code>bef_swing_manager_set_params</code> to regulate cache.
 *
 * @param managerHandle Pointer to the given swing manager
 * @param limit The concrete cache  limit in bytes
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_set_anim_seq_cache_limit(bef_swing_manager_t* managerHandle, unsigned int limit);

/**
 * @brief merge multi feature resource to one feature resource
 * @param jsonParamStr json params, e.g. {key:value, ...}
 * "    {inputParams :[
 *          {
 *              "name": "xxfilter"
 *              "path": "/path/"
 *              "zorder":1000
 *              "preset_params":[
 *                {
 *                    "preset_key": "intensity",
 *                    "preset_value":[0.8]
 *                }
 *              ]
 *            }
 *          ]
 *      }
 * @param outputPath output file path, e.g. "path/folderName"
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_merge_feature_resource(const char* jsonParamStr,
                             const char* outputPath);

BEF_SDK_API void bef_swing_manager_process_touchDownEvent(bef_swing_manager_t* swingHandler, float x, float y);

BEF_SDK_API void bef_swing_manager_process_touchUpEvent(bef_swing_manager_t* swingHandler, float x, float y);

BEF_SDK_API void bef_swing_manager_process_panEvent(bef_swing_manager_t* swingHandler, float x, float y, float factor);

BEF_SDK_API void bef_swing_manager_update_manipulation(bef_swing_manager_t* swingHandler, bef_manipulate_data manipulations);

BEF_SDK_API void bef_swing_manager_process_batch_pan_event(bef_swing_manager_t* swingHandler, bef_batch_touchs* touchInfo);

/**
 * @brief get error infos from errorManager
 * @param managerHandle instance of swing manager
 * @param outErrorInfosJson [out] error infos
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_get_error_infos(bef_swing_manager_t* managerHandle, 
                                char** outErrorInfosJson);

/**
 * @brief free error infos
 * @param managerHandle instance of swing manager
 * @param outErrorInfosJson error infos to free
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_free_error_infos(bef_swing_manager_t* managerHandle, 
                                char** outErrorInfosJson);


/**
 * @brief get event tracking data.
 * @param managerHandle instance of swing manager
 * @param etType swing event tracking type
 * @param etData event tracking data  (Allocate memory in the effect, need the caller to call bef_swing_manager_free_raw_buffer to free)
 * @param size out length
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_get_et_data(bef_swing_manager_t* managerHandle, uint32_t etType, char** etData, int* size);

/**
 * @brief reset event tracking data.
 * @param managerHandle instance of swing manager
 * @param etType swing event tracking type
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_reset_et_data(bef_swing_manager_t* managerHandle, uint32_t etType);

/**
 * @brief free raw buffer allocated in effect
 * @param managerHandle instance of swing manager
 * @param rawData raw buffer pointer allocted in effect
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_manager_free_raw_buffer(bef_swing_manager_t* managerHandle, void* rawData);

#endif /* bef_swing_manager_api_h */
