// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_RESAMPLER_H_
#define LYNX_KRYPTON_AURUM_RESAMPLER_H_

#include "aurum/sample.h"

namespace lynx {
namespace canvas {
namespace au {
class AudioContext;
class Resampler;

// sampling interface for resampler
class SampleSource {
 public:
  ~SampleSource();

  virtual void ReadSamples(AudioContext &ctx, Sample &output, int samples) = 0;
  Sample Resample(AudioContext &ctx, int samples);

 protected:
  int channels_;
  int sample_rate_;

 private:
  Resampler *resampler_ = nullptr;
  SampleFormat buffer_[AU_STREAM_BUF_LEN * 2];
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_RESAMPLER_H_
