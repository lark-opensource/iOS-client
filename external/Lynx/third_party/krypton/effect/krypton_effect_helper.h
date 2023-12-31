// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_EFFECT_HELPER_H_
#define LYNX_KRYPTON_EFFECT_HELPER_H_

#include <memory>

#include "base/base_export.h"
#include "canvas/platform/camera_context.h"
#include "canvas/webgl/webgl_texture.h"

namespace lynx {
namespace canvas {

class EffectDetector;

class EffectHelper {
 public:
  BASE_EXPORT static EffectHelper& Instance();
  BASE_EXPORT static bool IsValid() { return Instance().valid_; }

  virtual void RegisterImpl(EffectHelper* ptr){};
  virtual bool InitEffect(const std::shared_ptr<CanvasApp>& canvas_app) = 0;
  virtual bool InitAmazing(Napi::Env env, Napi::Object amazing) = 0;
  virtual EffectDetector* CreateEffectDetector(const std::string& type) = 0;

  virtual void RegistryTexture(unsigned int id, WebGLTexture* texture) = 0;
  virtual void UnRegistryTexture(unsigned int id) = 0;
  virtual std::pair<WebGLTexture*, int>* FindEffectTextureRegistryLine(
      unsigned int id) = 0;

  virtual void SetBeautifyParam(VideoContext* context, float whiten,
                                float smoothen, float enlarge_eye,
                                float slim_face) = 0;

  virtual void RequestUserMediaWithEffect(
      const std::shared_ptr<CanvasApp>& canvas_app,
      std::unique_ptr<CameraOption> option,
      const CameraContext::UserMediaCallback& callback) = 0;

 protected:
  std::atomic<bool> valid_ = false;
};

}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_EFFECT_HELPER_H_
