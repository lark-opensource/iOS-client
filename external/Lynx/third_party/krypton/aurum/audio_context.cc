// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/audio_context.h"

#include "aurum/config.h"
#include "aurum/util/time.hpp"

#define AUDIO_NODE_IMPL
#include "aurum/audio_node/analyser.hpp"
#include "aurum/audio_node/buffer.hpp"
#include "aurum/audio_node/capture.hpp"
#include "aurum/audio_node/effect.hpp"
#include "aurum/audio_node/file.hpp"
#include "aurum/audio_node/gain.hpp"
#include "aurum/audio_node/mixer_node.hpp"
#include "aurum/audio_node/stream.hpp"

// clang-format off
#include "aurum/audio_node/stream_file_writer.hpp"
#include "aurum/audio_node/fast_forward.hpp"
#include "aurum/audio_node/oscillator.hpp"
// clang-format on

#pragma clang diagnostic pop

#include <string>

#include "aurum/audio.h"
#include "aurum/audio_node.h"
#include "aurum/binding.h"
#include "aurum/decoder.h"
#include "aurum/encoder.h"
#include "canvas/base/log.h"
#include "jsbridge/napi/callback_helper.h"

namespace lynx {
namespace canvas {
namespace au {

void AudioContext::Connect(int src_id, int dst_id) {
  AudioNode &src = nodes[src_id];
  AudioNode &dst = nodes[dst_id];

  dst->OnConnect(src.operator->());
}

void AudioContext::Disconnect(int node_id) {
  AudioNode &node = nodes[node_id];
  // disconnect node from targets
  node->RemoveTargets<AudioNode, decltype(nodes)>(nodes);

  // For processor and mixer, you also need to disconnect from sources
  node->DisconnectSources();
}

void AudioContext::RefContext() {
  ref_mode = true;
  ++ref_count;
  engine->Resume();
}

void AudioContext::UnrefContext() {
  ref_mode = true;
  if (ref_count > 0) {
    --ref_count;
    if (!ref_count) {
      engine->Pause();
    }
  }
}

void AudioContext::AudioNodeIsSampleSource(AudioNodeID node_id,
                                           bool is_sample_source) {
  AudioNode &node = nodes[node_id];
  if (node->is_sample_source == is_sample_source) {
    return;
  }
  node->is_sample_source = is_sample_source;
  if (node->is_active) {
    // active node is always in the active list
    return;
  }

  if (is_sample_source) {
    node.AppendToActiveList(nodes[0]);
  } else {
    node.RemoveFromActiveList(nodes[0]);
  }
  // dump(*this);
}

int AudioContext::CreateAudio(bool loop, bool autoplay, double start_time,
                              double volume) {
  int id = audios.AllocId();
  Audio &audio = audios[id];
  audio.loop = loop;
  audio.autoplay = autoplay;
  audio.start_time = start_time;
  audio.volume = volume;
  return id;
}

void AudioContext::SetAudioState(int audio_id, AudioState state) {
  Audio &audio = audios[audio_id];
  AU_LOCK(audio.action_lock);
  switch (state) {
      // The reference state machine is as follows:
      // https://docs.bytedance.net/doc/vNdXdQOnjxf5CyqQmn2Bxf
    case AudioState::Play:
      if (audio.status == Audio::Status::Ended) {
        audio.current_sample = 0;
        audio.current_time = 0;
        if (audio.decoder.Get()) {
          if (audio.decoder->GetState() == DecoderState::EndOfFile) {
            audio.decoder->SetState(DecoderState::Meta);
          }
        }
      }
      if (audio.status != Audio::Status::Playing) {
        // idle/pause/stop/end can enter this state
        if (audio.status == Audio::Status::Idle) {
          audio.current_time = audio.start_time;
          audio.current_time_is_dirty = true;
        }
        audio.status = Audio::Status::Playing;
        audio.started = true;
        audio.actions.Alloc(Audio::Action::Play);
      }
      break;
    case AudioState::Pause:
      if (audio.status == Audio::Status::Playing) {
        // only play can enter this state
        audio.started = false;
        audio.status = Audio::Status::Paused;
        audio.actions.Alloc(Audio::Action::Pause);
      }
      break;
    case AudioState::Stop:
      if (audio.status == Audio::Status::Playing ||
          audio.status == Audio::Status::Paused) {
        // onlu play/pause can enter this state
        audio.started = false;
        audio.current_time = 0;
        audio.current_time_is_dirty = true;
        audio.status = Audio::Status::Stopped;
        audio.actions.Alloc(Audio::Action::Stop);
      }
      break;
  }
  AU_UNLOCK(audio.action_lock);
}

double AudioContext::GetAudioCurrentTime(int audio_id) {
  Audio &audio = audios[audio_id];
  if (!audio.started || audio.current_time_is_dirty) {
    // time_offset will not be updated at this time
    return audio.current_time;
  }
  return CurrentTimeUs() / 1.0e6 - audio.time_offset;
}

void AudioContext::SetAudioCurrentTime(int audio_id, double ts) {
  Audio &audio = audios[audio_id];
  audio.current_time = ts;
  audio.current_time_is_dirty = true;
  // This judgment is to prevent additional messages from being sent when audio
  // is destroyed
  if (audio.loader != -1) {
    // all states can seek
    AU_LOCK(audio.action_lock);
    audio.actions.Alloc(Audio::Action::Seek);
    AU_UNLOCK(audio.action_lock);
  }
}

void AudioContext::SetAudioLoop(int audio_id, bool loop) {
  Audio &audio = audios[audio_id];
  audio.loop = loop;
}

void AudioContext::SetAudioAutoPlay(int audio_id, bool autoplay) {
  Audio &audio = audios[audio_id];
  audio.autoplay = autoplay;
}

double AudioContext::GetAudioDuration(int audio_id) {
  Audio &audio = audios[audio_id];

  DecoderBase *decoder = audio.decoder.Get();
  if (!decoder) {
    return audio.duration;
  }
  const auto &meta = decoder->GetMetaRef();
  if (meta.samples == -1) {
    return 0;
  }
  return double(meta.samples) / meta.sample_rate;
}

void AudioContext::SetAudioVolume(int audio_id, double volume) {
  Audio &audio = audios[audio_id];
  audio.volume = volume;
}

void AudioContext::SetAudioStartTime(int audio_id, double start_time) {
  Audio &audio = audios[audio_id];
  audio.start_time = start_time;
}

bool AudioContext::GetAudioPaused(int audio_id) {
  Audio &audio = audios[audio_id];
  return !audio.started;
}

class DecodeTask {
 public:
  inline DecodeTask(AudioContext &context, int execute_id, int length,
                    const void *ptr)
      : context_(context),
        execute_id_(execute_id),
        loader_(context.AllocLoader()) {
    loader::Buffer(&loader_.base, ptr, length, false);
  }

  inline void Apply(const short *data, int channels, int sample_rate,
                    int samples) {
    channels_ = channels;
    sample_rate_ = sample_rate;
    samples_ = samples;
    data_ = new float[samples * channels];

    ConvertToNonInterlaced(data, data_, samples);
    if (channels == 2) {
      ConvertToNonInterlaced(data + 1, data_ + samples, samples);
    }
  }

  inline void Dispatch(bool success) {
    success_ = success;
    context_.engine->Dispatch(this, AfterDecode);
  }

  inline ~DecodeTask() {
    delete decoder_;
    AU_LOCK(context_.loader_lock);
    context_.loaders.Release(loader_.id);
    AU_UNLOCK(context_.loader_lock);
  }

  static void DoDecode(DecodeTask *decode_task);

  static void AfterDecode(const DecodeTask *decode_task) {
    if (decode_task) {
      decode_task->PostDecode();
    }
    delete decode_task;
  }

  void PostDecode() const {
    context_.engine->SendDecodeResult(execute_id_, success_, channels_,
                                      sample_rate_, samples_, data_);
  }

 protected:
  AudioContext &context_;
  int execute_id_;
  bool success_ = false;
  AudioLoader &loader_;
  DecoderBase *decoder_ = nullptr;
  int channels_, sample_rate_, samples_;
  float *data_ = nullptr;
};

void DecodeTask::DoDecode(DecodeTask *decode_task) {
  DecoderBase *decoder = decode_task->decoder_ = decoder::Decoder(
      decode_task->loader_
          .base);  // decoder is not reused and does not need loader pool
  if (!decoder || decoder->GetType() == DecoderType::UnSupported) {
    return decode_task->Dispatch(false);
  }

  while (decoder->GetState() == DecoderState::Init) {
    decoder->ReadMeta();
  }

  if (decoder->GetState() != DecoderState::Meta) {
    return decode_task->Dispatch(false);
  }

  auto &meta = decoder->GetMetaRef();
  decode_task->sample_rate_ = meta.sample_rate;
  decode_task->channels_ = meta.channels;
  decode_task->samples_ = meta.samples;

  if (decoder->GetType() == DecoderType::WAV) {
    // If it is WAV, it can be decoded once
    SampleFormat *buffer = new SampleFormat[2 * meta.samples];
    Sample output(0, buffer);
    decoder->Decode(output, 0, meta.samples);

    decode_task->Apply(output.data, meta.channels, meta.sample_rate,
                       output.length);
    delete[] buffer;
  } else {
    constexpr int decode_len = 480;
    int data_len = meta.samples == -1 ? 1024 : meta.samples;
    short *data = (short *)malloc(data_len << 2);
    int offset = 0;

    while (decoder->GetState() != DecoderState::EndOfFile) {
      SampleFormat buffer[AU_STREAM_BUF_LEN * 2];
      Sample output(0, buffer);
      decoder->Decode(output, offset, decode_len);
      if (decoder->GetState() == DecoderState::Error) {
        free(data);
        return decode_task->Dispatch(false);
      }
      if (output.length == 0) {
        break;
      }
      if (offset + output.length > data_len) {
        do {
          data_len = data_len << 1;
        } while (offset + output.length > data_len);
        data = (short *)realloc(data, data_len << 2);
      }
      memcpy(data + (offset << 1), output.data, output.length << 2);
      offset += output.length;
    }

    decode_task->Apply(data, meta.channels, meta.sample_rate, offset);
    free(data);
  }

  decode_task->Dispatch(true);
}

void AudioContext::DecodeAudioData(int execute_id, int length,
                                   const void *ptr) {
  DecodeTask *decode_task = new DecodeTask(*this, execute_id, length, ptr);
  engine->Execute(decode_task, DecodeTask::DoDecode);
}

Napi::Value AudioContext::Invoke(const Napi::CallbackInfo &ctx) {
#define INT_ARG(n) ctx[n].ToNumber().Int32Value()
#define UINT_ARG(n) ctx[n].ToNumber().Uint32Value()
#define FLOAT_ARG(n) ctx[n].ToNumber().FloatValue()
#define DOUBLE_ARG(n) ctx[n].ToNumber().DoubleValue()
#define STR_ARG(n) ctx[n].ToString()
#define BOOL_ARG(n) ctx[n].ToBoolean().Value()
#define ARRAY_BUFFER_DATA_ARG(n) \
  (ctx[n].IsArrayBuffer() ? ctx[n].As<Napi::ArrayBuffer>().Data() : nullptr)
#define TYPED_ARRAY_DATA_ARG(n)                                               \
  (ctx[n].IsTypedArray() ? ctx[n].As<Napi::TypedArray>().ArrayBuffer().Data() \
                         : nullptr)
#define TYPED_ARRAY_LEN_ARG(n) \
  (ctx[n].IsTypedArray() ? ctx[n].As<Napi::TypedArray>().ElementLength() : 0)
#define NEW_NUMBER(val) Napi::Number::New(ctx.Env(), val)
#define NEW_BOOL(val) Napi::Boolean::New(ctx.Env(), val)

  int api = INT_ARG(1), node_id = INT_ARG(2);
  switch (Binding(api)) {
    case Binding::CONNECT:
      Connect(node_id, INT_ARG(3));
      break;
    case Binding::DISCONNECT:
      Disconnect(node_id);
      break;
      // buffer
    case Binding::CREATE_BUFFER_SOURCE_NODE:
      return NEW_NUMBER(CreateBufferSourceNode());
    case Binding::SET_BUFFER:
      SetBuffer(node_id, INT_ARG(3), INT_ARG(4), INT_ARG(5),
                (const float *)ARRAY_BUFFER_DATA_ARG(6));
      break;
    case Binding::CLEAR_BUFFER:
      ClearBuffer(node_id);
      break;
    case Binding::SET_BUFFER_LOOP:
      SetBufferLoop(node_id, BOOL_ARG(3));
      break;
    case Binding::START_BUFFER:
      StartBuffer(node_id, FLOAT_ARG(3));
      break;
    case Binding::STOP_BUFFER:
      StopBuffer(node_id);
      break;
      // audio
    case Binding::SET_AUDIO_STATE:
      SetAudioState(node_id, AudioState(INT_ARG(3)));
      break;
    case Binding::SET_AUDIO_CURRENT_TIME:
      SetAudioCurrentTime(node_id, DOUBLE_ARG(3));
      break;
    case Binding::GET_AUDIO_CURRENT_TIME:
      return NEW_NUMBER(GetAudioCurrentTime(node_id));
    case Binding::SET_AUDIO_LOOP:
      SetAudioLoop(node_id, BOOL_ARG(3));
      break;
    case Binding::SET_AUDIO_AUTO_PLAY:
      SetAudioAutoPlay(node_id, BOOL_ARG(3));
      break;
    case Binding::GET_AUDIO_DURATION:
      return NEW_NUMBER(GetAudioDuration(node_id));
    case Binding::SET_AUDIO_VOLUME:
      SetAudioVolume(node_id, DOUBLE_ARG(3));
      break;
    case Binding::SET_AUDIO_START_TIME:
      SetAudioStartTime(node_id, DOUBLE_ARG(3));
      break;
    case Binding::GET_AUDIO_PAUSED:
      return NEW_BOOL(GetAudioPaused(node_id));
    case Binding::CREATE_AUDIO:
      return NEW_NUMBER(
          CreateAudio(BOOL_ARG(2), BOOL_ARG(3), DOUBLE_ARG(4), DOUBLE_ARG(5)));
    case Binding::RESET_AUDIO_LOADER:
      ResetAudioLoader(INT_ARG(2), STR_ARG(3));
      break;
    case Binding::CREATE_AUDIO_ELEMENT_SOURCE_NODE:
      return NEW_NUMBER(CreateAudioElementSourceNode(INT_ARG(2)));
      // GainNode
    case Binding::CREATE_GAIN_NODE:
      return NEW_NUMBER(CreateGainNode());
    case Binding::SET_GAIN_VALUE:
      SetGainValue(node_id, FLOAT_ARG(3));
      break;
      // stream
    case Binding::CREATE_STREAM_SOURCE_NODE: {
      auto obj = ctx[2].ToObject();
      uint32_t ptr_high = obj.Get("_ptr_high").ToNumber().Uint32Value();
      uint32_t ptr_low = obj.Get("_ptr_low").ToNumber().Uint32Value();
      uint64_t ptr = (uint64_t(ptr_high) << 32) + ptr_low;
      return NEW_NUMBER(CreateStreamSourceNode(ptr));
    } break;
      // analyser
    case Binding::CREATE_ANALYSER_NODE:
      return NEW_NUMBER(CreateAnalyserNode());
    case Binding::UPDATE_ANALYSER_PARAM:
      UpdateAnalyserParam(node_id, AnalyserParam(INT_ARG(3)), INT_ARG(4));
      break;
    case Binding::GET_ANALYSER_DATA_BYTE:
      GetAnalyserDataByte(
          node_id, BOOL_ARG(3), INT_ARG(4),
          reinterpret_cast<unsigned char *>(TYPED_ARRAY_DATA_ARG(5)));
      break;
    case Binding::GET_ANALYSER_DATA_FLOAT:
      GetAnalyserDataFloat(node_id, BOOL_ARG(3), INT_ARG(4),
                           reinterpret_cast<float *>(TYPED_ARRAY_DATA_ARG(5)));
      break;
    case Binding::AUDIO_NODE_IS_SAMPLE_SOURCE:
      AudioNodeIsSampleSource(node_id, BOOL_ARG(3));
      break;
    case Binding::DECODE_AUDIO_DATA:
      DecodeAudioData(INT_ARG(2), INT_ARG(3),
                      reinterpret_cast<float *>(ARRAY_BUFFER_DATA_ARG(4)));
      break;
    case Binding::SET_AUDIO_BUFFER_LOADER:
      SetAudioBufferLoader(INT_ARG(2), INT_ARG(3),
                           reinterpret_cast<void *>(ARRAY_BUFFER_DATA_ARG(4)));
      break;
    case Binding::CREATE_REVERB_NODE:
      return NEW_NUMBER(CreateReverbNode());
    case Binding::SET_REVERB_PARAM:
      SetReverbParam(node_id, INT_ARG(3), FLOAT_ARG(4));
      break;
    case Binding::CREATE_EQUALIZER_NODE:
      return NEW_NUMBER(CreateEqualizerNode());
    case Binding::SET_EQUALIZER_NODE_PARAMS:
      SetEqualizerNodeParams(node_id,
                             reinterpret_cast<float *>(TYPED_ARRAY_DATA_ARG(3)),
                             (int)(TYPED_ARRAY_LEN_ARG(3)));
      break;
    case Binding::CREATE_DELAY_NODE:
      return NEW_NUMBER(CreateDelayNode(FLOAT_ARG(2)));
    case Binding::SET_DELAY:
      SetDelay(node_id, FLOAT_ARG(3));
      break;
    case Binding::CREATE_F0_DETECTION_NODE:
      return NEW_NUMBER(CreateF0DetectionNode(FLOAT_ARG(2), FLOAT_ARG(3)));
    case Binding::CREATE_VOLUME_DETECTION_NODE:
      return NEW_NUMBER(CreateVolumeDetectionNode());
    case Binding::CREATE_A_E_C_NODE:
      return NEW_NUMBER(CreateAECNode(INT_ARG(2)));
    case Binding::CREATE_FADING_NODE:
      return NEW_NUMBER(CreateFadingNode());
    case Binding::SET_FADING_DURATIONS:
      SetFadingDurations(node_id, UINT_ARG(3), UINT_ARG(4), UINT_ARG(5));
      break;
    case Binding::SET_FADING_CURVES:
      SetFadingCurves(node_id, UINT_ARG(3), UINT_ARG(4));
      break;
    case Binding::SET_FADING_POSITION:
      SetFadingPosition(node_id, UINT_ARG(3));  // uint64
      break;
    case Binding::GET_F0_DETECTION_DATA:
      GetF0DetectionData(node_id, INT_ARG(3),
                         reinterpret_cast<float *>(TYPED_ARRAY_DATA_ARG(4)),
                         reinterpret_cast<float *>(TYPED_ARRAY_DATA_ARG(5)));
      break;
    case Binding::GET_VOLUME_DETECTION_DATA:
      GetVolumeDetectionData(
          node_id, INT_ARG(3),
          reinterpret_cast<float *>(TYPED_ARRAY_DATA_ARG(4)),
          reinterpret_cast<float *>(TYPED_ARRAY_DATA_ARG(5)));
      break;
    case Binding::CREATE_OSCILLATOR_NODE:
      return NEW_NUMBER(CreateOscillatorNode());
    case Binding::SET_OSCILLATOR_FREQ:
      SetOscillatorFreq(node_id, FLOAT_ARG(3));
      break;
    case Binding::SET_OSCILLATOR_DETUNE:
      SetOscillatorDetune(node_id, FLOAT_ARG(3));
      break;
    case Binding::SET_OSCILLATOR_WAVE:
      SetOscillatorWave(node_id, INT_ARG(3));
      break;
    case Binding::START_OSCILLATOR:
      StartOscillator(node_id, FLOAT_ARG(3));
      break;
    case Binding::STOP_OSCILLATOR:
      StopOscillator(node_id);
      break;
    case Binding::CREATE_STREAM_FILE_WRITER_NODE:
      return NEW_NUMBER(CreateStreamFileWriterNode());
    case Binding::START_STREAM_FILE_WRITER:
      return NEW_BOOL(StartStreamFileWriter(node_id, STR_ARG(3)));
    case Binding::STOP_STREAM_FILE_WRITER:
      StopStreamFileWriter(node_id);
      break;
    case Binding::CREATE_FAST_FORWARD_NODE:
      return NEW_NUMBER(CreateFastForwardNode());
    case Binding::START_FAST_FORWARD:
      return NEW_BOOL(StartFastForward(node_id, STR_ARG(3), INT_ARG(4)));
    case Binding::GET_BUFFER_OFFSET:
      return NEW_NUMBER(GetBufferOffset(node_id));
    case Binding::REF_CONTEXT:
      RefContext();
      break;
    case Binding::UNREF_CONTEXT:
      UnrefContext();
      break;
    default:
      break;
  }
  return Napi::Value();
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
