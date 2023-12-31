//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect_bindings.h"

#include "canvas/base/log.h"
#include "effect/krypton_effect_detector.h"
#include "effect/krypton_effect_helper.h"
#include "jsbridge/bindings/canvas/napi_effect_detector.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {
namespace effect {

Napi::Value GetAmaz(const Napi::CallbackInfo& info) {
  Napi::Object amazing = Napi::Object::New(info.Env());
  if (!EffectHelper::Instance().InitAmazing(info.Env(), amazing) ||
      info.Env().IsExceptionPending()) {
    KRYPTON_LOGE("[Effect] init amazing failed");
    return Napi::Value();
  }
  return amazing;
}

Napi::Value GetEffect(const Napi::CallbackInfo& info) {
  Napi::Object effect = Napi::Object::New(info.Env());
  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  if (!EffectHelper::Instance().InitEffect(canvas_app)) {
    KRYPTON_LOGE("[Effect] init effect failed");
    return Napi::Value();
  }
  return effect;
}

Napi::Value CreateEffectDetector(const Napi::CallbackInfo& info) {
  if (info.Length() < 1) {
    Napi::TypeError::New(
        info.Env(),
        "Not enough arguments for CreateEffectDetector, expecting: 1")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  auto arg0_type =
      piper::NativeValueTraits<piper::IDLString>::NativeValue(info[0], 0);

  auto&& result = EffectHelper::Instance().CreateEffectDetector(arg0_type);
  return result ? (result->IsWrapped()
                       ? result->JsObject()
                       : NapiEffectDetector::Wrap(
                             std::unique_ptr<EffectDetector>(std::move(result)),
                             info.Env()))
                : info.Env().Null();
}

void RegisterEffectBindings(Napi::Object& obj) {
  obj["_getAmaz"] = Napi::Function::New(obj.Env(), &GetAmaz, "_getAmaz");
  obj["_getEffect"] = Napi::Function::New(obj.Env(), &GetEffect, "_getEffect");
  obj["_createDetector"] =
      Napi::Function::New(obj.Env(), &CreateEffectDetector, "_createDetector");
}

};  // namespace effect
};  // namespace canvas
}  // namespace lynx
