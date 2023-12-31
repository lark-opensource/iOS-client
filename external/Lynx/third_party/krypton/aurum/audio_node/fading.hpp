// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL
#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"
#endif
#include "audio_fading.h"

namespace lynx {
namespace canvas {
namespace au {

void AudioFadingNode::DoPostProcess(AudioContext& ctx, Sample output) {
  if (!fading_ptr_) {
    fading_ptr_ = audio_fading_create(AU_SAMPLE_RATE, channels_);
    if (!fading_ptr_) {
      KRYPTON_LOGE("init fo detector failed!");
      return;
    }
  }

  int32_t len = output.length;
  ConvertToFloat(output.data, input_buffer_, len, channels_);

  audio_fading_process_interleaving(fading_ptr_, input_buffer_, output_buffer_,
                                    len);

  ConvertToShort(output_buffer_, output.data, len, channels_);
}

void AudioFadingNode::DoPreDestroy() {
  if (fading_ptr_) {
    audio_fading_destroy(fading_ptr_);
    fading_ptr_ = nullptr;
  }
}

AudioContext::AudioNodeID AudioEffectHelperImpl::CreateFadingNode(
    AudioContext& ctx) {
  return ctx.AllocNode(new AudioFadingNode());
}

void AudioEffectHelperImpl::SetFadingDurations(AudioContext& ctx, int node_id,
                                               uint64_t total,
                                               uint64_t fading_in,
                                               uint64_t fading_out) {
  AudioFadingNode& fading = ctx.nodes[node_id].As<AudioFadingNode>();

  if (total > 0) {
    audio_fading_set_content_duration(fading.GetAudioFadingPointer(), total);
  }

  if (fading_in > 0) {
    audio_fading_set_fadein_duration(fading.GetAudioFadingPointer(), fading_in);
  }

  if (fading_out > 0) {
    audio_fading_set_fadeout_duration(fading.GetAudioFadingPointer(),
                                      fading_out);
  }
}

void AudioEffectHelperImpl::SetFadingPosition(AudioContext& ctx, int node_id,
                                              uint64_t position_in_ms) {
  AudioFadingNode& fading = ctx.nodes[node_id].As<AudioFadingNode>();
  if (position_in_ms > 0) {
    audio_fading_seek(fading.GetAudioFadingPointer(), position_in_ms);
  }
}

void AudioEffectHelperImpl::SetFadingCurves(AudioContext& ctx, int node_id,
                                            uint32_t in_curve,
                                            uint32_t out_curve) {
  AudioFadingNode& fading = ctx.nodes[node_id].As<AudioFadingNode>();

  switch (in_curve) {
    case 0:
      audio_fading_set_fadein_curve(fading.GetAudioFadingPointer(),
                                    audio_fading_curve_log);
      break;
    case 1:
      audio_fading_set_fadein_curve(fading.GetAudioFadingPointer(),
                                    audio_fading_curve_linear);
      break;
    case 2:
      audio_fading_set_fadein_curve(fading.GetAudioFadingPointer(),
                                    audio_fading_curve_exp);
      break;
    default:
      break;
  }

  switch (out_curve) {
    case 0:
      audio_fading_set_fadeout_curve(fading.GetAudioFadingPointer(),
                                     audio_fading_curve_log);
      break;
    case 1:
      audio_fading_set_fadeout_curve(fading.GetAudioFadingPointer(),
                                     audio_fading_curve_linear);
      break;
    case 2:
      audio_fading_set_fadeout_curve(fading.GetAudioFadingPointer(),
                                     audio_fading_curve_exp);
      break;
    default:
      break;
  }
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
