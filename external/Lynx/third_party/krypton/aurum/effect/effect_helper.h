// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_EFFECT_HELPER_H_
#define LYNX_KRYPTON_AURUM_EFFECT_HELPER_H_

#include "aurum/audio_context.h"

namespace lynx {
namespace canvas {
namespace au {

class AudioEffectHelper {
 public:
  virtual int CreateF0DetectionNode(AudioContext& ctx, float min, float max) {
    return -1;
  }
  virtual void GetF0DetectionData(AudioContext& ctx, int node_id, int length,
                                  float* time_array, float* data_array) {}

  virtual int CreateVolumeDetectionNode(AudioContext& ctx) { return -1; }
  virtual void GetVolumeDetectionData(AudioContext& ctx, int node_id,
                                      int length, float* time_array,
                                      float* data_array) {}

  virtual int CreateDelayNode(AudioContext& ctx, float delay) { return -1; }
  virtual void SetDelay(AudioContext& ctx, int node_id, float new_delay) {}

  virtual int CreateEqualizerNode(AudioContext& ctx) { return -1; }
  virtual void SetEqualizerNodeParams(AudioContext& ctx, int node_id,
                                      float* params, int length) {}

  virtual int CreateReverbNode(AudioContext& ctx) { return -1; }
  virtual void SetReverbParam(AudioContext& ctx, int node_Id, int type,
                              float value) {}

  virtual int CreateFadingNode(AudioContext& ctx) { return -1; }
  virtual void SetFadingCurves(AudioContext& ctx, int node_id,
                               uint32_t in_curve, uint32_t out_curve) {}
  virtual void SetFadingPosition(AudioContext& ctx, int node_Id,
                                 uint64_t position_in_ms) {}
  virtual void SetFadingDurations(AudioContext& ctx, int node_Id,
                                  uint64_t total, uint64_t fading_in,
                                  uint64_t fading_out) {}

  virtual int CreateAECNode(AudioContext& ctx, int sample_rate) { return -1; }
};

extern AudioEffectHelper* GetAudioEffectHelper();

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_EFFECT_HELPER_H_
