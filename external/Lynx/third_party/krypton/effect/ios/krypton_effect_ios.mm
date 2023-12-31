//  Copyright 2022 The Lynx Authors. All rights reserved.

#include <targetconditionals.h>

#include "canvas/canvas_app.h"
#include "effect/krypton_effect_helper_impl.h"
#include "effect/krypton_effect_pfunc.h"

namespace lynx {
namespace canvas {

EffectHelper& EffectHelper::Instance() {
  static effect::EffectHelperImpl instance;
  return instance;
}

namespace effect {

bool LoadEffectSymbols(const std::shared_ptr<CanvasApp>& canvas_app) {
#define DEFINE_FUNC(name) effect::name##_local = ::name;
#if !TARGET_IPHONE_SIMULATOR
  DEFINE_EFFECT_FUNCS
#endif
#undef DEFINE_FUNC
  return true;
}

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
