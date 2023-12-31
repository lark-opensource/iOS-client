//
//  Created by lvshaohui on 2021/10/27.
//

#ifndef bef_effect_pure_algorithm_api_h
#define bef_effect_pure_algorithm_api_h
#include "bef_effect_public_define.h"

typedef void* bef_algorithms_interlayer_handle;

/**
 * @brief execute algorithm by name. Do not use this interface!!!! It is only used for LVPro to running waveforms, the interface will be removed in future (expected in 1070) and implemented in Bach.
 * @param handle  handle
 * @param input_idx  input texture id
 * @param input_buffer  input image buffer
 * @param input_width   input image width
 * @param input_height  input image height
 * @param pixel_format  input image format
 * @param time  timeStamp
 * @param name  algorithm name
 * @param params  algorithm params, JSON string.
 * @param algorithm_buffer   algorithm image buffer result. Memory created by effect.
 * @param algorithm_res_json  algorithm result, JSON string. Memory created by effect.
 * @return  If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_algorithms_pure_execute_algorithm_by_name(bef_algorithms_interlayer_handle handle,
                                              unsigned int input_idx,
                                              unsigned char* input_buffer,
                                              unsigned int input_width,
                                              unsigned int input_height,
                                              bef_pixel_format pixel_format,
                                              double time, const char* name,
                                              const char* params,
                                              char** algorithm_buffer, char** algorithm_res_json);

/**
 * @brief release result memory. 
 * @param handle  handle
 * @param name  algorithm name
 * @param algorithm_buffer   algorithm result, image buffer.
 * @param algorithm_res_json  algorithm result, JSON string.
 * @return  If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_algorithms_pure_release_result_buffer(bef_algorithms_interlayer_handle handle,
                                          const char* name,
                                          char** algorithm_buffer,
                                          char** algorithm_res_json);

#endif /* bef_effect_pure_algorithm_api_h */
