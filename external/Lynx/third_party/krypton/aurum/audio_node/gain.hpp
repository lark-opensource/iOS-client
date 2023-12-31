// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif

namespace lynx {
namespace canvas {
namespace au {

int AudioContext::CreateGainNode() { return AllocNode(new AudioGainNode()); }

void AudioContext::SetGainValue(int node_id, float value) {
  AudioGainNode &gain = nodes[node_id].As<AudioGainNode>();
  gain.gain_value = value;
}

void AudioGainNode::PostProcess(AudioContext &ctx, Sample output) {
  DoMultiply(output, gain_value);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
