//
//  cme_audio_stream.h
//  mammon_engine
//

#ifndef mammon_engine_cme_audio_stream_h
#define mammon_engine_cme_audio_stream_h

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CMEAudioStreamImpl CMEAudioStream;

void mammon_audio_stream_create(CMEAudioStream ** inout_audio_stream_inst, size_t channels, size_t samples_per_channel);

void mammon_audio_stream_destroy(CMEAudioStream ** inout_audio_stream_inst);

/// get specific channel data
float * mammon_audio_stream_getChannel(CMEAudioStream *audio_stream, const size_t channel_index);

/// copy from channel_data, make sure the size of channel_data is at least num_frames
void mammon_audio_stream_setChannel(CMEAudioStream *audio_stream, const size_t channel_index, float * channel_data);

/**
 * @brief resize audio frame
 *
 * @param num_frame new size of samples per channel
 * @param num_channal new size of channels
 */
void mammon_audio_stream_resize(CMEAudioStream *audio_stream, size_t num_frame, size_t num_channal);

void mammon_audio_stream_resizeChannel(CMEAudioStream *audio_stream, size_t num_channal);

void mammon_audio_stream_resizeFrame(CMEAudioStream *audio_stream, size_t num_frame);

/// fill stream data with zeros
void mammon_audio_stream_zeros(CMEAudioStream *audio_stream);

/// clear stream data
void mammon_audio_stream_clear(CMEAudioStream *audio_stream);

size_t mammon_audio_stream_getNumChannels(CMEAudioStream *audio_stream);

size_t mammon_audio_stream_getNumSamples(CMEAudioStream *audio_stream);

#ifdef __cplusplus
}
#endif

#endif /* mammon_engine_cme_audio_stream_h */
