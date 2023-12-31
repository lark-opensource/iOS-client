// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_EFFECT_HELPER_IMPL_H_
#define LYNX_KRYPTON_AURUM_EFFECT_HELPER_IMPL_H_

#include "aurum/effect/effect_helper.h"

namespace lynx {
namespace canvas {
namespace au {

class AudioEffectHelperImpl : public AudioEffectHelper {
 public:
  int CreateF0DetectionNode(AudioContext& ctx, float min, float max) override;
  void GetF0DetectionData(AudioContext& ctx, int node_id, int length,
                          float* time_array, float* data_array) override;

  int CreateVolumeDetectionNode(AudioContext& ctx) override;
  void GetVolumeDetectionData(AudioContext& ctx, int node_id, int length,
                              float* time_array, float* data_array) override;

  int CreateDelayNode(AudioContext& ctx, float delay) override;
  void SetDelay(AudioContext& ctx, int node_id, float new_delay) override;

  int CreateEqualizerNode(AudioContext& ctx) override;
  void SetEqualizerNodeParams(AudioContext& ctx, int node_id, float* params,
                              int length) override;

  int CreateReverbNode(AudioContext& ctx) override;
  void SetReverbParam(AudioContext& ctx, int node_id, int type,
                      float value) override;

  int CreateFadingNode(AudioContext& ctx) override;
  void SetFadingCurves(AudioContext& ctx, int node_id, uint32_t in_curve,
                       uint32_t out_curve) override;
  void SetFadingPosition(AudioContext& ctx, int node_Id,
                         uint64_t position_in_ms) override;
  void SetFadingDurations(AudioContext& ctx, int node_Id, uint64_t total,
                          uint64_t fading_in, uint64_t fading_out) override;

  int CreateAECNode(AudioContext& ctx, int sample_rate) override;
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_EFFECT_HELPER_IMPL_H_
