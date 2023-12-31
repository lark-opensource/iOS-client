//
//  cae_mammon_effect.h
//  mammon_engine
//

#ifndef cme_mammon_effect_h
#define cme_mammon_effect_h

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CAEEffectImpl CAEEffect;

void cae_effect_create(CAEEffect** inout_inst_ptr, const char* effect_name, const size_t sample_rate,
                       const size_t nb_channels);

void cae_effect_destroy(CAEEffect** inst);

const char* cae_effect_getName(CAEEffect* inst);

int32_t cae_effect_processPlanar(CAEEffect* inst, float** planar_data, size_t nb_channels, size_t nb_samples);

int32_t cae_effect_processInterleaved(CAEEffect* inst, float* interleave_data, size_t nb_channels, size_t nb_samples);

void cae_effect_reset(CAEEffect* inst);

void cae_effect_getParameter(CAEEffect* inst, const char* name, float* out_param_value);

void cae_effect_setParameter(CAEEffect* inst, const char* name, float in_param_value);

/// get state data size in bytes
size_t cae_effect_getStateSize(CAEEffect* inst);

/// get state data, before calling this function,
/// use cae_effect_get_state_size to get the size of state data and allocate buffer to store the state data
/// @param bytes output buffer
/// @param size On input the max bytes of output buffer. On output, the actual data size of the state data
void cae_effect_getState(CAEEffect* inst, uint8_t* bytes, size_t* size);

void cae_effect_setState(CAEEffect* inst, uint8_t* bytes, const size_t size);

size_t cae_effect_getLatency(CAEEffect* inst);

size_t cae_effect_getRequiredBlockSize(CAEEffect* inst);

bool cae_effect_needsPreprocess(CAEEffect* inst);

void cae_effect_setPreprocessing(CAEEffect* inst, bool b);

void cae_effect_setResRoot(CAEEffect* inst, const char* path);

// need to free
const char* cae_effect_getResRoot(CAEEffect* inst);

#ifdef __cplusplus
}
#endif

#endif /* cme_mammon_effect_h */
