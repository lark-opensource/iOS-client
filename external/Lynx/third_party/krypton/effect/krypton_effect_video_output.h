//  Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_VIDEO_OUTPUT_H
#define KRYPTON_EFFECT_VIDEO_OUTPUT_H

#include "canvas/base/data_holder.h"
#include "canvas/gpu/gl/gl_texture.h"
#include "canvas/texture_source.h"
#include "effect/krypton_effect_wrapper.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {
namespace effect {

class EffectDetectResult {
 public:
  EffectDetectResult(uint32_t size) { mem_ = DataHolder::MakeWithMalloc(size); }

  void Write(std::function<void(std::unique_ptr<DataHolder>&)> fn) {
    std::lock_guard<std::mutex> lk(lock_);
    fn(mem_);
  }

  void CopyTo(std::unique_ptr<DataHolder>& data_holder) {
    std::lock_guard<std::mutex> lk(lock_);
    memcpy(data_holder->WritableData(), mem_->Data(), mem_->Size());
  }

 private:
  std::unique_ptr<DataHolder> mem_;
  std::mutex lock_;
};

class EffectVideoOutput : public TextureSource {
 public:
  EffectVideoOutput(uint32_t algorithms);

  ~EffectVideoOutput();

  void InitOnGPU(
      std::shared_ptr<shell::LynxActor<TextureSource>> texture_source_actor);

  void SetBeautifyParam(float whiten, float smoothen, float enlargeEye,
                        float slimFace);

  void Play();
  void Pause();

  std::shared_ptr<EffectDetectResult> GetSharedMemory(uint32_t type);

  uint32_t reading_fbo() override;
  void UpdateTextureOrFramebufferOnGPU() override;
  uint32_t Texture() override;

  void UpdateTextureSource(
      std::shared_ptr<shell::LynxActor<TextureSource>> texture_source_actor);

 private:
  uint32_t texture_{0};
  std::unique_ptr<Framebuffer> fbo_;

  uint32_t algorithms_{0};
  bool should_update_beautify_param_{false};
  float whiten_{0};
  float smoothen_{0};
  float enlargeEye_{0};
  float slimFace_{0};
  std::unique_ptr<EffectWrapper> wrapper_{nullptr};
  std::shared_ptr<shell::LynxActor<TextureSource>> texture_source_actor_;
  std::unique_ptr<GLTexture> processed_tex_;
  std::unique_ptr<Framebuffer> processed_fbo_;

  std::shared_ptr<EffectDetectResult> face_info_res_;
  std::shared_ptr<EffectDetectResult> skeleton_info_res_;
  std::shared_ptr<EffectDetectResult> hand_info_res_;

  void UpdateFaceDetectResult();
  void UpdateSkeletonDetectResult();
  void UpdateHandDetectResult();
};

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_VIDEO_OUTPUT_H */
