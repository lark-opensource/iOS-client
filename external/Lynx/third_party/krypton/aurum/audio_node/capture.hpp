// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_CAPTURE_H_
#define LYNX_KRYPTON_AURUM_CAPTURE_H_

#include "aurum/capture_base.h"

namespace lynx {
namespace canvas {
namespace au {

void AudioContext::SetAecBackgroundSample(const Sample &bg_sample) {
  if (aec_node == -1) {
    return;
  }

  AudioNode &aec = nodes[aec_node];
  auto &processor = aec.As<AudioAECNode>();
  processor.SetAecBackgroundSample(bg_sample);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_CAPTURE_H_
