// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif
#include <cstdint>

#include "Echo2.h"

namespace lynx {
namespace canvas {
namespace au {

void AudioDelayNode::DoPostProcess(AudioContext &ctx, Sample output) {
  if (delay_ < 50) {
    return;
  }

  const int sample_length = output.length;
  ConvertToFloat(output.data, input_buffer, sample_length, channels_);

  for (float *input = input_buffer, *end = input + sample_length * channels_;
       input < end;) {
    echo1_.process(*input, input);
    input++;

    echo2_.process(*input, input);
    input++;
  }

  ConvertToShort(input_buffer, output.data, sample_length, channels_);
}

AudioContext::AudioNodeID AudioEffectHelperImpl::CreateDelayNode(
    AudioContext &ctx, float delay) {
  return ctx.AllocNode(new AudioDelayNode(delay));
}

void AudioEffectHelperImpl::SetDelay(AudioContext &ctx,
                                     AudioContext::AudioNodeID node_id,
                                     float new_delay) {
  AudioDelayNode &node = ctx.nodes[node_id].As<AudioDelayNode>();
  node.SetDelay(new_delay);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
