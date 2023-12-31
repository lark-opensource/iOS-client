// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_EFFECT_HELPER_IMPL_H_
#define LYNX_KRYPTON_EFFECT_HELPER_IMPL_H_

#include "effect/krypton_effect_helper.h"

namespace lynx {
namespace canvas {
namespace effect {

class EffectHelperImpl : public EffectHelper {
 public:
  EffectHelperImpl() { valid_ = true; }
  bool InitEffect(const std::shared_ptr<CanvasApp>& canvas_app) override;
  bool InitAmazing(Napi::Env env, Napi::Object amazing) override;
  EffectDetector* CreateEffectDetector(const std::string& type) override;

  void RegistryTexture(unsigned int id, WebGLTexture* texture) override;
  void UnRegistryTexture(unsigned int id) override;
  std::pair<WebGLTexture*, int>* FindEffectTextureRegistryLine(
      unsigned int id) override;

  void RequestUserMediaWithEffect(
      const std::shared_ptr<CanvasApp>& canvas_app,
      std::unique_ptr<CameraOption> option,
      const CameraContext::UserMediaCallback& callback) override;

  void SetBeautifyParam(VideoContext* context, float whiten, float smoothen,
                        float enlarge_eye, float slim_face) override;
};

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_EFFECT_HELPER_H_
