//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_VIDEO_CONTEXT_H
#define KRYPTON_EFFECT_VIDEO_CONTEXT_H

#include "canvas/gpu/gl/gl_texture.h"
#include "canvas/instance_guard.h"
#include "canvas/media/video_context.h"
#include "effect/krypton_effect_output_struct.h"
#include "effect/krypton_effect_video_output.h"
#include "effect/krypton_effect_wrapper.h"

namespace lynx {
namespace canvas {
struct BeautifyOption;
namespace effect {

class EffectVideoContext : public VideoContext {
 public:
  EffectVideoContext(const std::shared_ptr<CanvasApp>& canvas_app,
                     std::unique_ptr<VideoContext> video_impl,
                     uint32_t algorithms);

  ~EffectVideoContext();

  void Play() override;

  void Pause() override;

  double Timestamp() override;

  bool CanDetect() override { return true; }

  std::shared_ptr<shell::LynxActor<TextureSource>> GetNewTextureSource()
      override;

  std::shared_ptr<EffectDetectResult> GetSharedMemory(uint32_t type);

  void SetBeautifyParam(float whiten, float smoothen, float enlargeEye,
                        float slimFace);

 private:
  uint32_t algorithms_{0};
  std::unique_ptr<VideoContext> video_impl_;
  std::shared_ptr<shell::LynxActor<TextureSource>> output_actor_;
  std::shared_ptr<InstanceGuard<EffectVideoContext>> instance_guard_;
  std::shared_ptr<EffectDetectResult> face_info_res_;
  std::shared_ptr<EffectDetectResult> skeleton_info_res_;
  std::shared_ptr<EffectDetectResult> hand_info_res_;
};

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_VIDEO_CONTEXT_H */
