//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "recorder/media_recorder_bindings.h"

#include "canvas/base/log.h"
#include "canvas/canvas_element.h"
#include "config/config.h"
#include "jsbridge/bindings/canvas/napi_canvas_element.h"
#include "jsbridge/bindings/canvas/napi_media_recorder.h"
#include "jsbridge/bindings/canvas/napi_media_recorder_config.h"
#include "jsbridge/napi/exception_message.h"
#include "recorder/media_recorder.h"
#if ENABLE_KRYPTON_AURUM
#include "aurum/krypton_aurum.h"
#endif

using lynx::piper::IDLDictionary;
using lynx::piper::IDLObject;

namespace lynx {
namespace canvas {
namespace recorder {

Napi::Value CreateMediaRecorder(const Napi::CallbackInfo& info) {
  if (info.Length() < 1) {
    piper::ExceptionMessage::NotEnoughArguments(info.Env(), "",
                                                "CreateMediaRecorder", "1");
    return Napi::Value();
  }

  if (!info[0].IsObject() || !info[0].As<Napi::Object>().InstanceOf(
                                 NapiCanvasElement::Constructor(info.Env()))) {
    piper::ExceptionMessage::InvalidType(info.Env(), "argument 0",
                                         "'CanvasElement*'");
    return Napi::Value();
  }

  MediaRecorderConfig config;
  if (info.Length() >= 2) {
    auto arg1_config = piper::NativeValueTraits<
        IDLDictionary<MediaRecorderConfig>>::NativeValue(info, 1);
    if (info.Env().IsExceptionPending()) {
      return Napi::Value();
    }
    config = *arg1_config;
  }

  auto canvas_element =
      Napi::ObjectWrap<NapiCanvasElement>::Unwrap(info[0].As<Napi::Object>())
          ->ToImplUnsafe();
  auto weak_guard = std::weak_ptr<InstanceGuard<CanvasElement>>(
      canvas_element->GetInstanceGuard());

  MediaRecorder::Config recorder_config(config, canvas_element->GetWidth(),
                                        canvas_element->GetHeight());

#if ENABLE_KRYPTON_AURUM
  if (config.audio()) {
    GetAurumAutoInit(info.Env());
    recorder_config.SetAudioConfig(GetAudioEngine(info));
  }
#endif
  KRYPTON_LOGI("create media recorder with element ") << canvas_element;
  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  auto result = MediaRecorder::CreateInstance(
      recorder_config, [canvas_app_ = canvas_app, weak_guard](
                           uintptr_t key, std::unique_ptr<Surface> surface) {
        auto shared_guard = weak_guard.lock();
        if (!shared_guard) {
          KRYPTON_LOGE("error: canvas element is null ");
          return false;
        }
        if (key == 0) {
          KRYPTON_LOGE("add or surface callback error: key = 0 ");
          return false;
        }

        auto canvas = shared_guard->Get();

        if (surface != nullptr) {
          KRYPTON_LOGE("add recorder surface to canvas ")
              << canvas->GetCanvasId();
          canvas_app_->platform_view_observer()->OnSurfaceCreated(
              std::move(surface), key, canvas->GetCanvasId(), 0, 0);

        } else {
          KRYPTON_LOGE("remove recorder surface to canvas ")
              << canvas->GetCanvasId();
          canvas_app_->platform_view_observer()->OnSurfaceDestroyed(
              canvas->GetCanvasId(), key);
        }
        return true;
      });

  return result ? (result->IsWrapped()
                       ? result->JsObject()
                       : NapiMediaRecorder::Wrap(
                             std::unique_ptr<MediaRecorder>(std::move(result)),
                             info.Env()))
                : info.Env().Null();
}

void RegisterMediaRecorderBindings(Napi::Object& obj) {
  obj["createMediaRecorder"] = Napi::Function::New(
      obj.Env(), &CreateMediaRecorder, "createMediaRecorder");
}

};  // namespace recorder
};  // namespace canvas
}  // namespace lynx
