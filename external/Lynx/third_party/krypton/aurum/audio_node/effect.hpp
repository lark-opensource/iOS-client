// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef AUDIO_NODE_IMPL

#include "aurum/audio_context.h"
#include "aurum/binding.h"
#include "aurum/config.h"
#include "aurum/util/time.hpp"

#endif

#include "aurum/effect/effect_helper.h"

namespace lynx {
namespace canvas {
namespace au {

#ifdef OS_ANDROID
static AudioEffectHelper *&InnerAudioEffectHelperInstance() {
  static AudioEffectHelper *helper = new AudioEffectHelper();
  return helper;
}

AudioEffectHelper *GetAudioEffectHelper() {
  return InnerAudioEffectHelperInstance();
}

__attribute__((visibility("default"))) void RegisterAudioEffectHelper(
    AudioEffectHelper *helper) {
  if (helper) {
    InnerAudioEffectHelperInstance() = helper;
  }
}
#endif

int AudioContext::CreateF0DetectionNode(float min, float max) {
  auto helper = GetAudioEffectHelper();
  return helper->CreateF0DetectionNode(*this, min, max);
}

int AudioContext::CreateVolumeDetectionNode() {
  auto helper = GetAudioEffectHelper();
  return helper->CreateVolumeDetectionNode(*this);
}

void AudioContext::GetF0DetectionData(int node_id, int length,
                                      float *time_array, float *data_array) {
  auto helper = GetAudioEffectHelper();
  return helper->GetF0DetectionData(*this, node_id, length, time_array,
                                    data_array);
}

void AudioContext::GetVolumeDetectionData(int node_id, int length,
                                          float *time_array,
                                          float *data_array) {
  auto helper = GetAudioEffectHelper();
  return helper->GetVolumeDetectionData(*this, node_id, length, time_array,
                                        data_array);
}

void AudioContext::SetReverbParam(int node_id, int type, float value) {
  auto helper = GetAudioEffectHelper();
  return helper->SetReverbParam(*this, node_id, type, value);
}

void AudioContext::SetEqualizerNodeParams(int node_id, float *params,
                                          int length) {
  auto helper = GetAudioEffectHelper();
  return helper->SetEqualizerNodeParams(*this, node_id, params, length);
}

AudioContext::AudioNodeID AudioContext::CreateDelayNode(float delay) {
  auto helper = GetAudioEffectHelper();
  return helper->CreateDelayNode(*this, delay);
}

void AudioContext::SetDelay(AudioContext::AudioNodeID node_id, float newDelay) {
  auto helper = GetAudioEffectHelper();
  return helper->SetDelay(*this, node_id, newDelay);
}

void AudioContext::SetFadingDurations(int node_id, uint64_t total,
                                      uint64_t fading_in, uint64_t fading_out) {
  auto helper = GetAudioEffectHelper();
  return helper->SetFadingDurations(*this, node_id, total, fading_in,
                                    fading_out);
}

int AudioContext::CreateEqualizerNode() {
  auto helper = GetAudioEffectHelper();
  return helper->CreateEqualizerNode(*this);
}

AudioContext::AudioNodeID AudioContext::CreateReverbNode() {
  auto helper = GetAudioEffectHelper();
  return helper->CreateReverbNode(*this);
}

AudioContext::AudioNodeID AudioContext::CreateFadingNode() {
  auto helper = GetAudioEffectHelper();
  return helper->CreateFadingNode(*this);
}

void AudioContext::SetFadingCurves(int node_id, uint32_t in_curve,
                                   uint32_t out_curve) {
  auto helper = GetAudioEffectHelper();
  return helper->SetFadingCurves(*this, node_id, in_curve, out_curve);
}

void AudioContext::SetFadingPosition(int node_id, uint64_t position_in_ms) {
  auto helper = GetAudioEffectHelper();
  return helper->SetFadingPosition(*this, node_id, position_in_ms);
}

int AudioContext::CreateAECNode(int sample_rate) {
  auto helper = GetAudioEffectHelper();
  return helper->CreateAECNode(*this, sample_rate);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
