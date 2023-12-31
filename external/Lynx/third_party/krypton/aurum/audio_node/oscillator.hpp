// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif
#include "math.h"

namespace lynx {
namespace canvas {
namespace au {

int AudioContext::CreateOscillatorNode() {
  return AllocNode(new AudioOscillatorNode());
}

Sample AudioOscillatorNode::OnProcess(AudioContext &ctx, int len) {
  constexpr int sample_rate = AU_SAMPLE_RATE;

  switch (wave_form_) {
    case 0:  // sine
      for (int i = 0; i < len; i++) {
        buffer_[i << 1] = buffer_[(i << 1) + 1] =
            sinf((i + sample_offset_) * 1.0 / sample_rate * frequency_ * M_PI *
                 2) *
            0x7fff;
      }
      break;
    case 1:  // square
      for (int i = 0; i < len; i++) {
        int flag = (2 * (i + sample_offset_) * frequency_) / sample_rate;
        if ((flag & 1) == 1) {  // odd -> minus;
          buffer_[i << 1] = buffer_[(i << 1) + 1] = -0x7fff;
        } else {
          buffer_[i << 1] = buffer_[(i << 1) + 1] = 0x7fff;
        }
      }
      break;
    case 2:  // sawtooth
      for (int i = 0; i < len; i++) {
        int flag = ((i + sample_offset_) * 2 * frequency_) / sample_rate;
        if ((flag & 1) == 1) {  // odd -> minus;
          buffer_[i << 1] = buffer_[(i << 1) + 1] =
              ((i + sample_offset_) * 1.0 / sample_rate * 2.0 * frequency_ -
               flag - 1.0) *
              0x7fff;
          buffer_[(i << 1) + 1] = buffer_[i << 1];
        } else {
          buffer_[i << 1] = buffer_[(i << 1) + 1] =
              ((i + sample_offset_) * 1.0 / sample_rate * 2.0 * frequency_ -
               flag) *
              0x7fff;
        }
      }
      break;
    case 3:  // triangle
      for (int i = 0; i < len; i++) {
        int flag = ((i + sample_offset_) * frequency_) /
                   sample_rate;  // flag multiple wavelength
        float time = (i + sample_offset_) * 1.0 / sample_rate -
                     flag * 1.0 / (frequency_);
        float quat = 1.0 / (4 * frequency_);
        if (time >= 0 && time < quat) {  // up
          buffer_[i << 1] = buffer_[(i << 1) + 1] =
              (1.0 / quat) * time * 0x7fff;
        } else if (time >= quat && time < 3 * quat) {  // down
          buffer_[i << 1] = buffer_[(i << 1) + 1] =
              ((-1.0 / quat) * time + 2.0) * 0x7fff;
        } else {  // up
          buffer_[i << 1] = buffer_[(i << 1) + 1] =
              ((1.0 / quat) * time - 4.0) * 0x7fff;
        }
      }
      break;
    default:
      break;
  }

  sample_offset_ += len;
  return {len, buffer_};
}

void AudioContext::SetOscillatorFreq(AudioNodeID node_id, float freq) {
  AudioOscillatorNode &oslt = nodes[node_id].As<AudioOscillatorNode>();
  oslt.SetFrequency(freq);
}

void AudioContext::SetOscillatorDetune(AudioNodeID node_id, float detune) {
  /// todo
}

void AudioContext::SetOscillatorWave(AudioNodeID node_id, int waveform) {
  AudioOscillatorNode &oslt = nodes[node_id].As<AudioOscillatorNode>();
  oslt.SetWaveForm(waveform);
}

void AudioContext::StartOscillator(AudioNodeID node_id, float offset) {
  AudioOscillatorNode &oslt = nodes[node_id].As<AudioOscillatorNode>();
  oslt.SetStarted(true);
  oslt.SetSampleOffset(offset * AU_SAMPLE_RATE);
}

void AudioContext::StopOscillator(AudioNodeID node_id) {
  AudioOscillatorNode &oslt = nodes[node_id].As<AudioOscillatorNode>();
  oslt.SetStarted(false);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
