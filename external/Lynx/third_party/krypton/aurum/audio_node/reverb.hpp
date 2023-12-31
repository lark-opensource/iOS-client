// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif
#include "reverb.h"

namespace lynx {
namespace canvas {
namespace au {

int AudioEffectHelperImpl::CreateReverbNode(AudioContext& ctx) {
  return ctx.AllocNode(new AudioReverbNode());
}

#define REVERB_SETTER(name, func, min, max) \
  if (value > max) {                        \
    value = max;                            \
  } else if (value < min) {                 \
    value = min;                            \
  }                                         \
  this->name = value;                       \
  reverb_.func(value);

void AudioEffectHelperImpl::SetReverbParam(AudioContext& ctx, int node_id,
                                           int type, float value) {
  AudioReverbNode& reverb = ctx.nodes[node_id].As<AudioReverbNode>();
  reverb.SetParam(type, value);
}

void AudioReverbNode::SetParam(int type, float value) {
  switch (type) {
    case 0:
      REVERB_SETTER(room_size_, setRoomSize, 0.0f, 1.5f);
      break;
    case 1:
      REVERB_SETTER(hf_damping_, setDamp, 0.0f, 1.5f);
      break;
    case 2:
      REVERB_SETTER(stereo_depth_, setStereoDepth, 0.0, 1.0f);
      break;
    case 3:
      REVERB_SETTER(dry_, setDry, -3.0, 3.0f);
      break;
    case 4:
      REVERB_SETTER(wet_, setWet, -3.0, 3.0f);
      break;
    case 5:
      REVERB_SETTER(dry_gain_db_, setDryGain, -60.0, 60.0);
      break;
    case 6:
      REVERB_SETTER(wet_gain_db_, setWetGain, -60.0, 60.0);
      break;
    default:
      break;
  }
}

void AudioReverbNode::DoPostProcess(AudioContext& ctx, Sample output) {
  int len = output.length;
  ConvertToFloat(output.data, input_buffer_, len, channels_);

  reverb_.process(input_buffer_, output_buffer_, len);
  ConvertToShort(output_buffer_, output.data, len, channels_);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
