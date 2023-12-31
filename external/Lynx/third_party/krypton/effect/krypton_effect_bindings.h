//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_BINDINGS_H
#define KRYPTON_EFFECT_BINDINGS_H

#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {
namespace effect {

void RegisterEffectBindings(Napi::Object& obj);

}
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_BINDINGS_H */
