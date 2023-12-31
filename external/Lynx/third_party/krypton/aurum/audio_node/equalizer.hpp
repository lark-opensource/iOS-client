// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif
#include "ae_eq.h"

namespace lynx {
namespace canvas {
namespace au {

int AudioEffectHelperImpl::CreateEqualizerNode(AudioContext& ctx) {
  return ctx.AllocActiveNode(new AudioEqualizerNode());
}

void AudioEffectHelperImpl::SetEqualizerNodeParams(AudioContext& ctx,
                                                   int node_id, float* params,
                                                   int length) {
  AudioEqualizerNode& equalizer = ctx.nodes[node_id].As<AudioEqualizerNode>();
  std::lock_guard<std::mutex> lock(equalizer.param_lock);
  if (!params || length < 21) {
    return;
  }

  // The data format of JS is: preamp(0), amps(1~10), freqs(11~20)
  equalizer.params["pre_amplitude_gain"] = params[0];

  equalizer.params["gain0"] = params[1];
  equalizer.params["gain1"] = params[2];
  equalizer.params["gain2"] = params[3];
  equalizer.params["gain3"] = params[4];
  equalizer.params["gain4"] = params[5];
  equalizer.params["gain5"] = params[6];
  equalizer.params["gain6"] = params[7];
  equalizer.params["gain7"] = params[8];
  equalizer.params["gain8"] = params[9];
  equalizer.params["gain9"] = params[10];

  equalizer.params["width0"] = params[11];
  equalizer.params["width1"] = params[12];
  equalizer.params["width2"] = params[13];
  equalizer.params["width3"] = params[14];
  equalizer.params["width4"] = params[15];
  equalizer.params["width5"] = params[16];
  equalizer.params["width6"] = params[17];
  equalizer.params["width7"] = params[18];
  equalizer.params["width8"] = params[19];
  equalizer.params["width9"] = params[20];

  equalizer.need_update_param = true;
}

void AudioEqualizerNode::DoPostProcess(AudioContext& ctx, Sample output) {
  std::lock_guard<std::mutex> lock(param_lock);

  if (need_update_param) {
    need_update_param = false;
    processor_->setParameters(params);
  }

  int len = output.length;
  float* left_channel = input_buffer_;         // pointer to left channel data
  float* right_channel = input_buffer_ + len;  // pointer to right channel data
  // Pointer to audio data
  float* data_refer_to[2] = {left_channel, right_channel};

  ConvertToNonInterlaced(output.data, left_channel, len);
  ConvertToNonInterlaced(output.data + 1, right_channel, len);

  // bus count
  constexpr int num_bus = 1;
  // create bus array
  std::vector<mammon::Bus> bus_array(num_bus);
  bus_array[0] = mammon::Bus("master", data_refer_to, 2, len);

  // processing, the result will overwrites into left_channel and right_channel
  processor_->process(bus_array);

  for (int i = 0; i < len; i++) {
    output.data[2 * i] = left_channel[i] * 0x7fff;
    output.data[2 * i + 1] = right_channel[i] * 0x7fff;
  }
}

AudioEqualizerNode::AudioEqualizerNode() {
  constexpr int sample_rate = 44100;
  constexpr int num_channels = 2;
  processor_ = std::make_unique<mammon::EqualizerX>(sample_rate, num_channels);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
