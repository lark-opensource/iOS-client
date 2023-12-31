// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_MIXER_H_
#define LYNX_KRYPTON_AURUM_MIXER_H_

#include <vector>

#include "aurum/config.h"
#include "aurum/sample.h"

namespace lynx {
namespace canvas {
namespace au {

using MixerInfo = std::vector<Sample>;

// Mixer::mix Sample returned may ref inner buffer, its life cycle must be
// longer than that of Sample
class Mixer {
 public:
  __attribute__((visibility("default"))) Sample Mix(MixerInfo &&mixer_info);

 private:
  SampleFormat buffer_[AU_STREAM_BUF_LEN * 2];
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_MIXER_H_
