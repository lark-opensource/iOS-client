
#ifndef bef_effect_audio_effect_h
#define bef_effect_audio_effect_h

#include "bef_effect_public_define.h"

/**
 * @brief Set audio sample parameter
 * @param handle      Effect handle that  initialized
 * @param parameter   include sampleRate , channel, etc..
 * @return            if succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_audio_sample_parameter(bef_effect_handle_t handle, bef_audio_sample_parameter parameter);

/**
 * @breif                       Process audio effect
 * @param handle                Effect handle
 * @param inBuffer              Input audio buffer for audio effect process, inBuffer[channel][samplesPerChannel]   range: -1.0 ~ 1.0
 * @param outBuffer  output     Audio buffer after audio effect process, outBuffer[channel][samplesPerChannel]
 * @param samplesPerChannel     Samples per channel
 * @param realSamplesPerChannel Real processed samples per channel
 * @return          If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_audio(bef_effect_handle_t handle, float **inBuffer,  float **outBuffer, const int samplesPerChannel, int* realSamplesPerChannel);




/**
 * @breif                       Process audio effect
 * @param handle                Effect handle
 * @param inBuffer              Input audio buffer for audio effect process, inBuffer[channel][samplesPerChannel]   range: -1.0 ~ 1.0
 * @param outBuffer  output     Audio buffer after audio effect process, outBuffer[channel][samplesPerChannel]
 * @param samplesPerChannel     Samples per channel
 * @param realSamplesPerChannel Real processed samples per channel
 * @param channels              audio channels
 * @return          If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_audio_V2(bef_effect_handle_t handle, float **inBuffer,  float **outBuffer, const int samplesPerChannel, int* realSamplesPerChannel,int channels,int sampleRate);

/**
 * @breif                         get audio effect status
 * @param handle      Effect handle
 * @return         0: outbuffer(bef_effect_process_audio_V2)  is valid
 */
BEF_SDK_API int bef_effect_get_audio_effect_status(bef_effect_handle_t handle);

/**
 * @breif                       Process audio effect
 * @param handle                Effect handle
 * @param inBuffer              Input audio buffer for audio effect process, inBuffer[channel][samplesPerChannel]   range: -32768  ~ 32767
 * @param outBuffer  output     Audio buffer after audio effect process, outBuffer[channel][samplesPerChannel]
 * @param samplesPerChannel     Samples per channel
 * @param realSamplesPerChannel Real processed samples per channel
 * @return          If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_audio_int16(bef_effect_handle_t handle, int16_t **inBuffer,  int16_t **outBuffer, const int samplesPerChannel, int* realSamplesPerChannel);

/**
 * @breif                       Process audio effect
 * @param handle                Effect handle
 * @param inBuffer              Input audio buffer for audio effect process, inBuffer[channel][samplesPerChannel]   range: -32768  ~ 32767
 * @param outBuffer  output     Audio buffer after audio effect process, outBuffer[channel][samplesPerChannel]
 * @param samplesPerChannel     Samples per channel
 * @param realSamplesPerChannel Real processed samples per channel
 * @param channels              audio channels
 * @param sampleRate            audio sampleRate
 * @return          If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_audio_int16_V2(bef_effect_handle_t handle, int16_t **inBuffer,  int16_t **outBuffer, const int samplesPerChannel, int* realSamplesPerChannel,int channels,int sampleRate);

/**
 * @breif                       Fetch audio effect param
 * @param handle                Effect handle
 * @param audioEffectParam      Audio effect parameter
 * @return          If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_fetch_audio_effect_parameter(bef_effect_handle_t handle, bef_audio_effect* audioEffectParam);
/**
 * @breif                       recoginze audio effect
 * @param handle                Effect handle
 * @param inBuffer              Input audio buffer for audio effect process, inBuffer[channel]
 * @param length                num of samples
 * @param samplesPerChannel     Samples per channel
 * @param realSamplesPerChannel Real processed samples per channel
 * @return          If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_audio_recognize(bef_effect_handle_t handle, const int16_t *inBuffer, const int32_t length,  const int samplesPerChannel, int* realSamplesPerChannel);
/**
 * @breif                       get audio recognize status
 * @param handle                Effect handle
 * @return                      0:enable -1:disable
 */
BEF_SDK_API int bef_effect_get_audio_recognize_status(bef_effect_handle_t handle);
/**
 * @breif                       get audio electric status
 * @param handle                Effect handle
 * @return                      0:enable -1:disable
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_audio_electric_status(bef_effect_handle_t handle);

/**
 * @brief                       set client audio recognition dict
 * @param handle                Effect handle
 * @param pairListStr           pairListStr, separated by comma and colon   <word>:<pinyin>
 * @return                      If succeed return IES_RESULT_SUC,  BEF_RESULT_FAIL if parse failed
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_audio_recognize_dict(bef_effect_handle_t handle, const char* pairListStr);

/**
 * @brief                       get whole audio recognition dict
 * @param handle                Effect handle
 * @param pairListStr           pairListStr, separated by comma and colon   <word>:<pinyin>, must free outside!
 * @return                      If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_audio_recognize_dict(bef_effect_handle_t handle, char** pairListStr);

/**
 * @brief Set audio config with a specified path string.
 * @param handle        Effect handle
 * @param strPath       The absolute path of audio config package.
 * @return              If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_audio_config(bef_effect_handle_t handle, const char *strPath);

/**
 * @brief remove audio config with a specified path string.
 * @param handle        Effect handle
 * @param strPath       The absolute path of audio config package.
 * @return              If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_clear_audio_config(bef_effect_handle_t handle);

/**
 * @breif                       Process audio in bach
 * @param handle                Effect handle
 * @param inBuffer              Input audio buffer for audio effect process
 * @param samplesPerChannel     Samples per channel
 * @param sampleRate            audio sampleRate
 * @return                      If succeed return BEF_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_process_bach_audio(bef_effect_handle_t handle, float *inBuffer, int samplesPerChannel, int sampleRate);

/**
 * @breif                       Audio manager callback
 * @param                       ve instance pointer (Set empty if not needed)
 * @param path                  sticker path
 * @param param                 json param
 * @param result                json result (External malloc, Internal free)
 * @return                      If succeed return 0,  other return 1
 */
typedef int (*bef_effect_audio_manager_callback)(void*, const char*, const char*, char**);

/**
 * @breif                       Set audio callback
 * @param handle                Effect handle
 * @param pointer               External instance pointer
 * @param func                  Callback function
 * @return                      If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_audio_manager_callback(bef_effect_handle_t handle, void* pointer, bef_effect_audio_manager_callback func);

/**
 * @breif                       Enable audio callback
 * @param handle                Effect handle
 * @param enable                true or false
 * @return                      If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_enable_audio_manager_callback(bef_effect_handle_t handle, bool enable);


// Set infos for *MultiPort* (also known as *MicInput*) audio system. The related apis are located in bef_effect_audio_api.h header.

/**
 * @brief                       Set audio playback device type, default as bef_effect_audio_playback_device_type_unknown
 * @param type                  The current audio playback device type
 * @return                      If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_audio_set_playback_device_type(bef_effect_handle_t handle, bef_effect_audio_playback_device_type type);

/**
 * @brief                       Set audio playback delay. Data pulled ---- delay ---- play
 *                              Used when user input audio (e.g. singing through mic or push a button to play sound in response to playback) should sync with the
 *                              audio playback. The sticker can retrieve this information and setup delay node accordingly.
 * @param handle                Effect handle
 * @param delay                 Delay(ms) from audio pulled to audio actually played
 * @return                      If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_audio_set_playback_delay(bef_effect_handle_t handle, int delay);

#endif /* bef_effect_audio_effect_h */
