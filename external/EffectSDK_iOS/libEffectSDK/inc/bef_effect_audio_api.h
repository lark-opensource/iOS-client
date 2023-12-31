
#ifndef bef_effect_audio_api_h
#define bef_effect_audio_api_h

#include "bef_effect_public_define.h"

/**
 * @brief                        Create an audio handle.
 *      Please keep in mind that only one handle can be created at most (for now), and if you attempt to create another one before destroying the previous one, an error should occur.
 * @param [out] handle           Effect audio handle.
 * @param [in] sampleRate        Sample rate for both input audio buffers and output audio buffers.
 * @return BEF_SDK_API           Possible values include: BEF_RESULT_SUC, BEF_RESULT_FAIL, BEF_RESULT_INVALID_INTERFACE
 */
BEF_SDK_API bef_effect_result_t bef_effect_audio_create_handle(bef_effect_audio_handle *handle, int sampleRate BEF_DEFAULT(44100));

/**
 * @brief                        Destroy an audio handle.
 * @param [in] handle            The audio handle to destroy.
 * @return BEF_SDK_API           Possible values include: BEF_RESULT_SUC, BEF_RESULT_AUDIO_HANDLE_INVALID, BEF_RESULT_INVALID_INTERFACE
 */
BEF_SDK_API bef_effect_result_t bef_effect_audio_destroy_handle(bef_effect_audio_handle handle);

/**
 * @brief                       Set internal buffer frame size.
 *      Since the version this API is available (1160), an output FIFO buffer was introduced. Usually you don't need to worry about this, but if *latency* is important, it's recommeded
 *      that the size of samples pulled each time (per channel) is equal to, or n times the size of the internal buffer frame size. The default internal buffer frame size is 256, and this API can
 *      be used to specify a different one.
 *      Some proper setup examples:
 *          1. bufferFrameSize = 256, pullSize = 512 (processed twice for each pull);
 *          2. bufferFrameSize = 512, pullSize = 512 (processed once for each pull);
 *          3. bufferFrameSize = 470, pullSize = 470 (processed once for each pull);
 *      Should be called before pushing/pulling.
 * @param [out] handle           Effect audio handle.
 * @param [in] bufferFrameSize   The internal process buffer frame size (per channel)
 * @return BEF_SDK_API           Possible values include: BEF_RESULT_SUC, BEF_RESULT_AUDIO_HANDLE_INVALID, BEF_RESULT_INVALID_INTERFACE
 */
BEF_SDK_API bef_effect_result_t bef_effect_audio_set_internal_buffer_frame_size(bef_effect_audio_handle handle, int bufferFrameSize);

/**
 * @brief                        Push data to effect audio.
 *      You can push multiple types of data, discriminated by `portType` parameter, by calling this api multiple times.
 * @param [in] handle            Effect audio handle.
 * @param [in] inBuffer          The audio buffer to push. If you have more than one channel, the buffer must be provided in interleaving format.
 * @param [out] audioStatus      Audio processing status.
 * @param [in] samplesPerChannel Sample number per channel.
 * @param [in] numOfChannels     Number of channels. Currently supports only `1` and `2`.
 * @param [in] portType          `bef_effect_audio_in_port_mic` or `bef_effect_audio_in_port_music`
 * @return BEF_SDK_API           Possible values include: BEF_RESULT_SUC, BEF_RESULT_AUDIO_HANDLE_INVALID, BEF_RESULT_INVALID_INTERFACE.
 *   | ----- RETURN ----- | -------------------------------------------- MEANING -------------------------------------------------- |
 *   | BEF_RESULT_SUC | Successfully committed audio processing. However, this *DOES NOT* mean audio processing is successful.      |
 *                      You may want to check `audioStatus` for further validation if necessary.                                    |
 *   | BEF_RESULT_AUDIO_HANDLE_INVALID | The audio handle you provided is invalid.                                                  |
 *   | BEF_RESULT_INVALID_INTERFACE | The method is not implemented. Please check you SDK version or contact an RD.                 |
 */
BEF_SDK_API bef_effect_result_t bef_effect_audio_push_data(bef_effect_audio_handle handle, float* inBuffer, bef_effect_audio_status_type *audioStatus, int samplesPerChannel, int numOfChannels, bef_effect_audio_port_type portType BEF_DEFAULT(bef_effect_audio_in_port_mic));

/**
 * @brief                        Pull data from effect audio.
 *      You can pull data from different port, discriminated by `portType` parameter, for specific purpose. The most common one is for playback.
 * @param [in] handle 
 * @param [out] outBuffer        The pulled audio buffer. The buffer is in interleaving format.
 * @param [out] audioStatus      Audio processing status.
 * @param [in] samplesPerChannel Sample number per channel.
 * @param [in] numOfChannels     Number of channels. Currently supports only `1` and `2`.
 * @param [in] portType          `bef_effect_audio_out_port_play` or `bef_effect_audio_out_port_write`
 * @return BEF_SDK_API           Possible values include: BEF_RESULT_SUC, BEF_RESULT_AUDIO_HANDLE_INVALID, BEF_RESULT_INVALID_INTERFACE.
 *   | ----- RETURN ----- | -------------------------------------------- MEANING -------------------------------------------------- |
 *   | BEF_RESULT_SUC | Successfully committed audio processing. However, this *DOES NOT* mean audio processing is successful.      |
 *                      You may want to check `audioStatus` for further validation if necessary.                                    |
 *   | BEF_RESULT_AUDIO_HANDLE_INVALID | The audio handle you provided is invalid.                                                  |
 *   | BEF_RESULT_INVALID_INTERFACE | The method is not implemented. Please check you SDK version or contact an RD.                 |
 */
BEF_SDK_API bef_effect_result_t bef_effect_audio_pull_data(bef_effect_audio_handle handle, float* outBuffer, bef_effect_audio_status_type *audioStatus, int samplesPerChannel, int numOfChannels, bef_effect_audio_port_type portType BEF_DEFAULT(bef_effect_audio_out_port_play));

#endif /* bef_effect_audio_api_h */
