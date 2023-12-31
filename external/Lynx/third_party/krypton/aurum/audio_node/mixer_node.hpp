// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL

#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/effect/effect_helper.h"
#include "aurum/util/time.hpp"

#endif

namespace lynx {
namespace canvas {
namespace au {

Sample AudioMixerNode::OnProcess(AudioContext &ctx, int len) {
  MixerInfo mixer_info;
  AU_LOCK(nodes_lock_);
  for (auto it = source_nodes_.cbegin(); it != source_nodes_.cend(); it++) {
    AudioNodeBase *node = *it;
    Sample output = node->Process(ctx, len, generation_);
    if (!output.length) {
      continue;
    }

    mixer_info.push_back(output);
  }
  AU_UNLOCK(nodes_lock_);

  Sample output = mixer_.Mix(std::move(mixer_info));
  if (output.length) {
    PostProcess(ctx, output);
  }
  return output;
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
