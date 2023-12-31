
//
// Created by William.Hua on 2021/1/4.
//

#ifndef AUDIO_EFFECT_SRC_AUDIO_SDK_SAMI_NON_REALTIME_EFFECT_H
#define AUDIO_EFFECT_SRC_AUDIO_SDK_SAMI_NON_REALTIME_EFFECT_H
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif
enum NonRealtimeEffectType {
    kNonRealtimeType_TimeScaler = 0,
    kNonRealtimeType_PitchShifter = 1,
};

typedef struct SAMINonRealEffect* SAMINonRealEffectRef;

int32_t SAMINonRealtimeEffectCreateWithType(SAMINonRealEffectRef* in_effect, NonRealtimeEffectType in_type,
                                            int32_t in_sample_rate, int32_t in_num_channels);

int32_t SAMINonRealtimeEffectDestroy(SAMINonRealEffectRef* in_effect);

int32_t SAMINonRealtimeEffectGetFloatParameter(SAMINonRealEffectRef in_effect, const char* in_param_name,
                                               float* out_param_val);

int32_t SAMINonRealtimeEffectSetFloatParameter(SAMINonRealEffectRef in_effect, const char* in_param_name,
                                               float in_param_val);
/**
 * @brief Get output data latency compared to input data in time-domain samples
 *
 * @param out_latency: number of samples delayed
 * @return 0 if succeed
 */
int32_t SAMINonRealtimeEffectGetRequiredBlockSize(SAMINonRealEffectRef in_effect, size_t* out_block_size);

/**
 * @brief Get output data latency compared to input data in time-domain
 *
 * @param out_latency: number of samples per channel
 * @return 0 if succeed
 */
int32_t SAMINonRealtimeEffectGetLatency(SAMINonRealEffectRef in_effect, size_t* out_latency);

int32_t SAMINonRealtimeEffectProcessPlanarData(SAMINonRealEffectRef in_effect, float** in_buf, bool in_is_final_flag,
                                               int32_t in_num_channels, int32_t in_num_samples_per_channel);

/**
 * @brief Get available size to output
 *
 * @param in_effect: effect ref
 * @param out_available_size: available size, number of samples per channel
 * @return 0 if succeed
 */
int32_t SAMINonRealtimeEffectGetAvailableSize(SAMINonRealEffectRef in_effect, size_t* out_available_size);

/**
 * @brief Get output data from this effect processor
 * If the size of output buffer is smaller than `available` data, only the size of output buffer will be write to
 * output blocks.
 *
 * @param in_effect: effect ref
 * @param in_out_buf:  output buffer with planar format (non-interleaved)
 * @param in_num_channels: output channels, which should be same as SAMINonRealtimeEffectCreateWithType:in_num_channels
 * @param in_num_samples_per_channel: output buffer's length as number of samples per channel
 * @return How many samples write to each channel
 */
int32_t SAMINonRealtimeEffectRetrieve(SAMINonRealEffectRef in_effect, float** in_out_buf, int32_t in_num_channels,
                                      int32_t in_num_samples_per_channel);

#ifdef __cplusplus
}
#endif

#endif  // AUDIO_EFFECT_SRC_AUDIO_SDK_SAMI_NON_REALTIME_EFFECT_H
