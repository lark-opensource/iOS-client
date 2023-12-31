#pragma once

#include <stdint.h>
#include "ae_defs.h"

#ifdef __cplusplus
extern "C" {
#endif

// y = f(x); x,y = 0 ~ 1.0; define your curve for fading
typedef float (*AUDIO_FADING_CURVE_TRANSFORMER)(float x);

extern AUDIO_FADING_CURVE_TRANSFORMER audio_fading_curve_log;
extern AUDIO_FADING_CURVE_TRANSFORMER audio_fading_curve_linear;
extern AUDIO_FADING_CURVE_TRANSFORMER audio_fading_curve_exp;

MAMMON_EXPORT void* audio_fading_create(int samplerate, int channels);
MAMMON_EXPORT void audio_fading_destroy(void* af);

// total_duration_in_ms: if less than fade in+out time, the fade in and out will be executed immediately
MAMMON_EXPORT void audio_fading_set_content_duration(void* af, uint64_t total_duration_in_ms);

MAMMON_EXPORT void audio_fading_set_fadein_duration(void* af, uint64_t duration_in_ms);
MAMMON_EXPORT void audio_fading_set_fadeout_duration(void* af, uint64_t duration_in_ms);

// if not set, audio_fading_curve_log is used
MAMMON_EXPORT void audio_fading_set_fadein_curve(void* af, AUDIO_FADING_CURVE_TRANSFORMER curve);
MAMMON_EXPORT void audio_fading_set_fadeout_curve(void* af, AUDIO_FADING_CURVE_TRANSFORMER curve);

MAMMON_EXPORT void audio_fading_seek(void* af, uint64_t position_in_ms);
MAMMON_EXPORT void audio_fading_process_plannar(void* af, float** in, float** out, int samples_per_channel);
MAMMON_EXPORT void audio_fading_process_interleaving(void* af, float* in, float* out, int samples_per_channel);

#ifdef __cplusplus
}
#endif