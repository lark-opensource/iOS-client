//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "canvas/platform/camera_context.h"

#if ENABLE_KRYPTON_EFFECT
#include "effect/krypton_effect_helper.h"
#endif

namespace lynx {
namespace canvas {

CameraContext::CameraContext(const std::shared_ptr<CanvasApp>& canvas_app)
    : VideoContext(canvas_app) {}

void CameraContext::RequestUserMedia(
    const std::shared_ptr<CanvasApp>& canvas_app, const Napi::Object& js_option,
    const UserMediaCallback& callback) {
  auto option = std::make_unique<CameraOption>();

  Napi::Value js_facing_mode = js_option.Get("facingMode");
  if (js_facing_mode.IsString()) {
    option->face_mode = js_facing_mode.ToString().Utf8Value();
    if (option->face_mode == "environment") {
      option->face_mode = "back";
    }
  }

  Napi::Value js_resolution = js_option.Get("resolution");
  if (js_resolution.IsString()) {
    option->resolution = js_resolution.ToString().Utf8Value();
  }

#if ENABLE_KRYPTON_EFFECT
  if (EffectHelper::IsValid()) {
    Napi::Value enable_face = js_option.Get("face");
    if (enable_face.IsBoolean() && enable_face.ToBoolean()) {
      option->effect_algorithms |= EffectAlgorithms::kEffectFace;
    }

    Napi::Value enable_hand = js_option.Get("hand");
    if (enable_hand.IsBoolean() && enable_hand.ToBoolean()) {
      option->effect_algorithms |= EffectAlgorithms::kEffectHand;
    }

    Napi::Value enable_skeleton = js_option.Get("skeleton");
    if (enable_skeleton.IsBoolean() && enable_skeleton.ToBoolean()) {
      option->effect_algorithms |= EffectAlgorithms::kEffectSkeleton;
    }

    Napi::Value enable_beautify = js_option.Get("beautify");
    if (enable_beautify.IsBoolean() && enable_beautify.ToBoolean()) {
      option->effect_algorithms |= EffectAlgorithms::kEffectBeautify;
    }

    if ((option->effect_algorithms | EffectAlgorithms::kEffectNone) == 0) {
      DoRequestUserMedia(canvas_app, std::move(option), callback);
    } else {
      EffectHelper::Instance().RequestUserMediaWithEffect(
          canvas_app, std::move(option), callback);
    }
  } else {
    DoRequestUserMedia(canvas_app, std::move(option), callback);
  }
#else
  DoRequestUserMedia(canvas_app, std::move(option), callback);
#endif  // ENABLE_KRYPTON_EFFECT
}
};  // namespace canvas
}  // namespace lynx
