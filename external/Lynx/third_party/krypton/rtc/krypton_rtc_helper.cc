// Copyright 2023 The Lynx Authors. All rights reserved.

#include "rtc/krypton_rtc_helper.h"

namespace lynx {
namespace canvas {
namespace rtc {

Napi::Value CreateRtcEngineFunc(const Napi::CallbackInfo& info) {
  return RtcHelper::Instance().CreateRtcEngine(info);
}

void RtcHelper::RegisterRtcBindings(Napi::Object& obj) {
  obj["_createRtcEngine"] =
      Napi::Function::New(obj.Env(), &CreateRtcEngineFunc, "_createRtcEngine");
}

}  // namespace rtc
}  // namespace canvas
}  // namespace lynx
