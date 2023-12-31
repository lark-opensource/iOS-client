//
//  bef_effect_algorithm_audio_onset_api.h
//
//  Created by bytedance on 2019/6/21.
//

#ifndef bef_effect_algorithm_audio_onset_api_h
#define bef_effect_algorithm_audio_onset_api_h
#include "bef_effect_public_define.h"
#include <stdint.h>

///
/// Integrated VESDK onset detection header file
/// written by will.li in 17th.Dec.2018
///

typedef void* bef_audio_onset_Handle;

/**
 * @brief sampleRate:  The sampling rate of the pcm stream, after initialization, the pcm stream is parsed at this sampling rate in the Process stage
 * @brief threshold:   Onset detection threshold, the default setting is 85, when dense detection is required to reduce the threshold, sparse detection raises the threshold
 * @brief Return:      0: initialized successfully；negative: initialization failed
 */
BEF_SDK_API
int16_t bef_audio_Init_OnsetInst(bef_audio_onset_Handle* handle,
                                 const int32_t sampleRate,
                                 const float threshold);

/**
 * @brief Sequentially read a pcm stream and store the detected results in the (*onset_time) and (*onset_intensity) arrays
 * @param f_pcmFlow：           Pcm stream address saved in float format, only supports mono
 * @param pcm_size：            The length of the pcm stream, the number of samples, not the length of the data stream (the number of samples multiplied by the bit length of each sample = the length of the data stream)
 * @param onset_time：          The detected onset time point, in seconds, automatically allocates memory, but it needs to be released by the business party after it is used up!
 * @param onset_intensity：     The detected onset intensity corresponds to the onset_time detection time point one by one, and the memory is automatically allocated, but it needs to be released by the business party after it is used up! 
 * @param onset_len:            Array length of detected onset_time/onset_intensity
 * @return               1 indicates that the buffer is not filled, you need to continue to call Process_OnsetInst until it returns 0
 *                       0 represents onset detection, because each call to Process_OnsetInst will refresh onset_time and onset_intensity, so you need to process the detection results in time
 *                       negative means error
 */
BEF_SDK_API
int16_t bef_audio_Process_OnsetInst_f(bef_audio_onset_Handle handle,
                                      const float* f_pcmFlow,
                                      const uint32_t pcm_size,
                                      float** onset_time,
                                      float** onset_intensity,
                                      int* onset_len);

/**
 * @brief Call pcm stream, internal overload interface
 */
BEF_SDK_API
int16_t bef_audio_Process_OnsetInst_d(bef_audio_onset_Handle handle,
                                      const double* d_pcmFlowc,
                                      const uint32_t pcm_size,
                                      float** onset_time,
                                      float** onset_intensity,
                                      int* onset_len);

/**
 * @brief Use 16-bit pcm stream, overload interface
 */
BEF_SDK_API
int16_t bef_audio_Process_OnsetInst_i(bef_audio_onset_Handle handle,
                                      const int16_t* int_pcmFlow,
                                      const uint32_t pcm_size,
                                      float** onset_time,
                                      float** onset_intensity,
                                      int* onset_len);

/**
 * @brief f_2ch_pcmFlow represents two channels
 */
BEF_SDK_API
int16_t bef_audio_Process_OnsetInst_f_2ch(bef_audio_onset_Handle handle,
                                          const float** f_2ch_pcmFlow,
                                          const uint32_t pcm_size,
                                          float** onset_time,
                                          float** onset_intensity,
                                          int* onset_len);

/**
 * @brief reset handle
 * @brief 0 Reset successful; negative Reset failed
 */
BEF_SDK_API
int16_t bef_audio_Reset_OnsetInst(bef_audio_onset_Handle handle);

/**
 * @brief Release the resources of bef_audio_onset_Handle and set bef_audio_onset_Handle to a null pointer
 * @return 0: success, negative: failure, the general reason is that the incoming bef_audio_onset_Handle is null
 */
BEF_SDK_API
int16_t bef_audio_Destroy_OnsetInst(bef_audio_onset_Handle* handle);

#endif
