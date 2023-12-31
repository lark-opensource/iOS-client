//
//  bef_effect_algorithm_cap.hpp
//  effect-sdk
//
//  Created by lvshaohui1234 on 2021/11/1.
//

#ifndef bef_effect_algorithm_cap_h
#define bef_effect_algorithm_cap_h

#include <stdio.h>
#include "bef_effect_public_define.h"
#include "bef_framework_public_base_define.h"

typedef void* bef_algorithm_cap_handle;

/**
 * @brief get all buffers.
 * @param handle                effect handle which regist algorithmCap.
 * @param algorithm_buffers     BufferSet which has all BachBuffers result on this frame
 * @param mem_size              size of algorithm_buffers
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_get_all_algorithm_buffers(bef_algorithm_cap_handle handle, void** algorithm_buffers, int* mem_size);

/**
 * @brief get buffers by type.
 * @param handle                effect handle which regist algorithmCap.
 * @param type                  enum type Bach::AlgorithmType format.
 * @param algorithm_buffer      BachBuffer type
 * @param mem_size              size of algorithm_buffers
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_get_algorithm_buffers(bef_algorithm_cap_handle handle, int32_t type, void** algorithm_buffer, int* mem_size);

/**
 * @brief get all algorithms serialize result.
 * @param handle                effect handle which regist algorithmCap.
 * @param algorithm_buffers     all algorihtms serialize result
 * @param mem_size              size of algorithm_buffers
 * @param algorithm_json        describe algorithm_buffers
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_get_all_algorithm_results_serialize(bef_algorithm_cap_handle handle,
                                                                                             char** algorithm_buffers,
                                                                                             int* mem_size,
                                                                                             char** algorithm_json);

/**
 * @brief get algorithm serialize result by type.
 * @param handle                effect handle which regist algorithmCap.
 * @param algorithm_buffer      algorihtm serialize result
 * @param type                  enum type Bach::AlgorithmType format.
 * @param mem_size              size of algorithm_buffer
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_get_algorithm_result_serialize(bef_algorithm_cap_handle handle,
                                                                                        int32_t type,
                                                                                        char** algorithm_buffer,
                                                                                        int* mem_size);

/**
 * @brief set all buffers.
 * @param handle                effect handle which regist algorithmCap.
 * @param algorithm_buffers     BufferSet which has all BachBuffers result on this frame
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_set_all_algorithm_buffers(bef_algorithm_cap_handle handle, void* algorithm_buffers);

/**
 * @brief set buffer by type.
 * @param handle                effect handle which regist algorithmCap.
 * @param type                  enum type Bach::AlgorithmType format.
 * @param algorithm_buffer      BachBuffer type
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_set_algorithm_buffer(bef_algorithm_cap_handle handle, int32_t type, void* algorithm_buffer);

/**
 * @brief set all algorithms serialize result.
 * @param handle                effect handle which regist algorithmCap.
 * @param serialize_buffers     all algorihtms serialize result
 * @param algorithm_json        describe algorithm_buffers
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_set_all_algorithm_results_serialize(bef_algorithm_cap_handle handle,
                                                                                             char* serialize_buffers,
                                                                                             char* algorithm_json);
/**
 * @brief set algorithm serialize result by type.
 * @param handle                effect handle which regist algorithmCap.
 * @param serialize_buffer      algorihtm serialize result
 * @param type                  enum type Bach::AlgorithmType format.
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_set_algorithm_result_serialize(bef_algorithm_cap_handle handle,
                                                                                        int32_t type,
                                                                                        char* serialize_buffer);

/**
 * @brief destory all buffers.
 * @param algorithm_buffers     BufferSet which has all BachBuffers result on this frame
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_destory_destory_all_buffers(void* algorithm_buffers);

/**
 * @brief destory buffer by type.
 * @param type                  enum type Bach::AlgorithmType format.
 * @param algorithm_buffer      BachBuffer type
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_destory_algorithm_buffer(int32_t type, void* algorithm_buffers);

/**
 * @brief set all algorithms serialize result.
 * @param serialize_buffers     all algorihtms serialize result
 * @param algorithm_json        describe algorithm_buffers
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_destory_all_algorithm_serialize_results(char* serialize_buffers, char* algorithm_json);

/**
 * @brief destroy algorithm serialize result by type.
 * @param serialize_buffer      algorihtm serialize result
 * @param type                  enum type Bach::AlgorithmType format.
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_destory_algorithm_serialize_results(int32_t type, char* serialize_buffer);

/**
 * @brief convert BachBuffer to serialize result only use stop-motion and will delete in future 
 * @param type                  enum type Bach::AlgorithmType format.
 * @param algorithm_buffer      BachBuffer type
 * @param serialize_buffer      algorihtm serialize result
 * @return                      If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_algorithm_cap_convert_serialize(int32_t type, void* algorithm_buffer, char** serialize_buffer, int* mem_size);

#endif
