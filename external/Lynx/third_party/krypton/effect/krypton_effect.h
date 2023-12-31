//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_H
#define KRYPTON_EFFECT_H

#include "canvas/canvas_app.h"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace canvas {
namespace effect {
bool& EffectLoaded();

bool LoadEffectSymbols(const std::shared_ptr<CanvasApp>& canvas_app);

bool InitEffect(const std::shared_ptr<CanvasApp>& canvas_app);

bool InitAmazing(Napi::Env env, Napi::Object amazing);

#ifdef __ANDROID__
#include <jni.h>
void RegisterJNI(JNIEnv* env);
#endif
}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_H */
