// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_H
#define LYNX_KRYPTON_AURUM_H

#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace canvas {
namespace au {
class AudioEngine;
}  // namespace au

Napi::Value GetAurumAutoInit(Napi::Env env);
std::weak_ptr<au::AudioEngine> GetAudioEngine(const Napi::CallbackInfo &info);
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_H
