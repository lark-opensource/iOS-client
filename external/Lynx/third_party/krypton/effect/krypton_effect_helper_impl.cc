// Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect_helper_impl.h"

#include <mutex>

#include "effect/krypton_effect.h"
#include "effect/krypton_effect_bindings.h"
#include "effect/krypton_effect_camera_context.h"
#include "effect/krypton_effect_detector_impl.h"
#include "effect/krypton_effect_texture_registry.h"
#include "effect/krypton_effect_video_context.h"

namespace lynx {
namespace canvas {
namespace effect {

bool EffectHelperImpl::InitEffect(
    const std::shared_ptr<CanvasApp>& canvas_app) {
  return effect::InitEffect(canvas_app);
}

bool EffectHelperImpl::InitAmazing(Napi::Env env, Napi::Object amazing) {
  return effect::InitAmazing(env, amazing);
}

EffectDetector* EffectHelperImpl::CreateEffectDetector(
    const std::string& type) {
  return new EffectDetectorImpl(type);
}

void EffectHelperImpl::RegistryTexture(unsigned int id, WebGLTexture* texture) {
  EffectTextureRegistry::Instance()->Registry(id, texture);
}

void EffectHelperImpl::UnRegistryTexture(unsigned int id) {
  EffectTextureRegistry::Instance()->UnRegistry(id);
}

std::pair<WebGLTexture*, int>* EffectHelperImpl::FindEffectTextureRegistryLine(
    unsigned int id) {
  return EffectTextureRegistry::Instance()->Find(id);
}

void EffectHelperImpl::RequestUserMediaWithEffect(
    const std::shared_ptr<CanvasApp>& canvas_app,
    std::unique_ptr<CameraOption> option,
    const CameraContext::UserMediaCallback& callback) {
  RequestUserMediaWithEffectForCameraContext(canvas_app, std::move(option),
                                             callback);
}

void EffectHelperImpl::SetBeautifyParam(VideoContext* context, float whiten,
                                        float smoothen, float enlarge_eye,
                                        float slim_face) {
  auto effect_video_context = static_cast<effect::EffectVideoContext*>(context);
  effect_video_context->SetBeautifyParam(whiten, smoothen, enlarge_eye,
                                         slim_face);
}

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
