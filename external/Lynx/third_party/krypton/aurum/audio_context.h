// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_AUDIO_CONTEXT_H_
#define LYNX_KRYPTON_AURUM_AUDIO_CONTEXT_H_

#include <string>

#include "aurum/audio.h"
#include "aurum/audio_node.h"
#include "aurum/audio_stream.h"
#include "aurum/capture_base.h"
#include "aurum/config.h"
#include "aurum/util/pool.hpp"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace canvas {
namespace au {

class LoaderBase;
class DecoderBase;
class AudioLoader;
class AudioEngine;
class AudioEffectHelperImpl;

class AudioContext {
 public:
  AudioEngine *engine;
  uint64_t consume_begin_time;

  Pool<AudioLoader, 8> loaders;
  Pool<Audio, 8> audios;       // private
  Pool<AudioNode, 128> nodes;  // private

  constexpr static int8_t READ_FILE = 1, WRITE_FILE = 2;

  inline AudioContext(AudioEngine *engine) : engine(engine) {
    AudioNode &destination =
        nodes.Alloc(new AudioDestinationNode());  // 0 is the destination
    destination->is_active = true;
    destination->is_sample_source =
        true;  // AudioDestinationNode default output to SampleCallback
    destination.active_prev = &destination;
  }

  virtual ~AudioContext() = default;

  inline AudioLoader &AllocLoader() {
    AU_LOCK(loader_lock);
    AudioLoader &ret = loaders.Alloc();
    AU_UNLOCK(loader_lock);
    return ret;
  }

  int loader_lock = 0;
  int ref_count = 0;
  bool ref_mode = false;

  inline AudioNode &Dest() { return nodes[0]; }

  void SetAecBackgroundSample(const Sample &bg_sample);

  float bgm_volume = 0.65, mic_volume = 1.1,
        post_volume = -1.0;  // post_volume valid in [0, 1.0]

  inline AudioNode *GetRecordNode(int id) {
    return record_nodes[id] == -1 ? nullptr : &nodes[record_nodes[id]];
  }

  Napi::Value Invoke(const Napi::CallbackInfo &ctx);

  bool is_recording = false;
  uint64_t record_time = 0;

  friend class AudioEffectHelperImpl;

 protected:
  // record_nodes[] save the microphone sound and background sound (during /
  // before / after) streaming process
  int record_nodes[3] = {-1, -1, -1};

  using AudioNodeID = int;
  using AudioID = int;
  using StreamID = uint64_t;
  using Utf8Value = const std::string &;

  int aec_node = -1;
  int aec_denoise_node = -1;

  inline AudioNodeID AllocNode(AudioNodeBase *handle) {
    return nodes.AllocId(handle);
  }

  inline AudioNodeID AllocActiveNode(AudioNodeBase *handle) {
    AudioNode &node = nodes.Alloc(handle);
    node->is_active = true;
    node.AppendToActiveList(nodes[0]);

    return node->GetID();
  }

#define AUDIO_API

#include "aurum/audio_api.h"

#undef AUDIO_API
};

class AudioLoader {
 public:
  inline AudioLoader(int id) : id(id) {
    KRYPTON_LOGV("new AudioLoader ") << id;
  }

  inline ~AudioLoader() {
    KRYPTON_LOGV("release AudioLoader") << id;
    LoaderBase *loader = &base;
    loader->~LoaderBase();
  }

  union {
    LoaderBase base;
    void *_holder[16];
  };

 public:
  int id;
  uint32_t hash;
  int path_len;
  char path[32];
  int refs = 0;
  int deref_countdown = 0x7fffffff;  // release callback
};

inline void DoMultiply(au::Sample output, float factor) {
  if (factor > (32766. / 32767.) && factor < (32768. / 32767.)) {
    return;  // close to 1, do nothing
  }

  au::SampleFormat *from = output.data, *end = from + (output.length << 1);

  // We use 8 as the threshold. When the factor is greater than 8, integer
  // multiplication is not used
  constexpr int FACTOR_THRESHOLD = 8;

  if (factor < 1) {
    // Use integer multiplication to improve performance
    int32_t ifactor = int32_t(factor * 65536 + 0.5f);
    for (; from < end; from++) {
      int data = (*from * ifactor) >> 16;
      *from = data;
    }
  } else if (factor <= FACTOR_THRESHOLD) {
    // factor : The magnification used to convert to an integer
    constexpr int FACTOR_MULTIPLY = 65536 / FACTOR_THRESHOLD;
    // The number of displacements required to restore the product to the
    // sampled value
    constexpr int FACTOR_SHIFT = 31 - __builtin_clz(FACTOR_MULTIPLY);

    int32_t ifactor = int32_t(factor * FACTOR_MULTIPLY + 0.5f);
    for (; from < end; from++) {
      int data = (*from * ifactor) >> FACTOR_SHIFT;
      *from = AU_MIN_MAX(data, -32768, 32767);
    }
  } else {  // factor > 8
    for (; from < end; from++) {
      int data = *from * factor;
      *from = AU_MIN_MAX(data, -32768, 32767);
    }
  }
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_AUDIO_CONTEXT_H_
