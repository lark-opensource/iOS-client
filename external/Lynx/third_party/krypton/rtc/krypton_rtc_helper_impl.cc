// Copyright 2023 The Lynx Authors. All rights reserved.

#include "rtc/krypton_rtc_helper_impl.h"

#include "canvas/base/log.h"
#include "config/config.h"
#include "jsbridge/bindings/canvas/napi_rtc_engine.h"
#include "jsbridge/napi/exception_message.h"
#include "rtc/krypton_rtc_engine.h"
#if ENABLE_KRYPTON_AURUM
#include "aurum/krypton_aurum.h"
#endif

using lynx::piper::IDLDictionary;
using lynx::piper::IDLObject;

namespace lynx {
namespace canvas {
namespace rtc {

Napi::Value RtcHelperImpl::CreateRtcEngine(const Napi::CallbackInfo& info) {
  if (info.Length() < 1) {
    piper::ExceptionMessage::NotEnoughArguments(info.Env(), "",
                                                "CreateRtcEngine", "1");
    return info.Env().Null();
  }

  std::string app_id = "";
  if (info[0].IsString()) {
    app_id = info[0].ToString().Utf8Value();
  }
  if (app_id.empty()) {
    KRYPTON_LOGE("Krypton CreateRtcEngine param error: no appId for param 0");
    return info.Env().Null();
  }

  auto result = RtcEngine::CreateInstance(app_id);
  if (!result) {
    KRYPTON_LOGE("Krypton CreateRtcEngine null");
    return info.Env().Null();
  }

#if ENABLE_KRYPTON_AURUM
  // if aurum is using, krypton.aurum() should be called before CreateRtcEngine
  auto audio_engine = GetAudioEngine(info);
  if (audio_engine.lock()) {
    result->SetAudioEngine(audio_engine);
  }
  KRYPTON_LOGI("Krypton CreateRtcEngine success width aurum");
#else
  KRYPTON_LOGI("Krypton CreateRtcEngine success");
#endif

  return NapiRtcEngine::Wrap(std::unique_ptr<RtcEngine>(std::move(result)),
                             info.Env());
}

};  // namespace rtc
};  // namespace canvas
}  // namespace lynx
