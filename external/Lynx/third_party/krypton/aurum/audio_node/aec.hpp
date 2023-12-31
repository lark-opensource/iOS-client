// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include <cstdint>

#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif
#include "ae_aec.h"

namespace lynx {
namespace canvas {
namespace au {

int AudioEffectHelperImpl::CreateAECNode(AudioContext& ctx, int sample_rate) {
  return ctx.AllocNode(new AudioAECNode());
}

void AudioAECNode::DoPostProcess(AudioContext& ctx, Sample output) {
  const int sample_length = output.length;
  if (bg_.length != sample_length) {
    return;
  }

  DCHECK(output.data);
  if (!aec_.get()) {
    return;
  }

  ConvertToFloat(bg_.data, bg_buffer_, sample_length, channels_);
  ConvertToFloat(output.data, fr_buffer_, sample_length, channels_);

  // NS process
  int32_t num_bus = 1;
  std::vector<mammon::Bus> b_array(num_bus);
  b_array[0] = mammon::Bus("master", fr_buffer_, channels_, sample_length);
  ns_->process(b_array);  // result overwrite into fr_buffer_

  // AEC process
  num_bus = 2;
  std::vector<mammon::Bus> bus_array(num_bus);
  bus_array[0] = mammon::Bus("master", fr_buffer_, channels_, sample_length);
  bus_array[1] = mammon::Bus("reference", bg_buffer_, channels_, sample_length);
  aec_->process(bus_array);  // result overwrite into fr_buffer_

  ConvertToShort(fr_buffer_, output.data, sample_length, channels_);
}

void AudioAECNode::InitAec() {
  ns_ = std::make_unique<mammon::NoiseSuppression>(AU_SAMPLE_RATE, 2);
  // NNAEC with current AecMicSelection version
  // Only support 16K，10ms input. However, the traditional AEC3 can
  // support 44.1k and any ms input
  aec_ = std::make_unique<mammon::AecMicSelection>(AU_SAMPLE_RATE, 2);
}
}  // namespace au
}  // namespace canvas
}  // namespace lynx
