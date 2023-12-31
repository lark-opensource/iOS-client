//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect_pfunc.h"

namespace lynx {
namespace canvas {
namespace effect {

#if !TARGET_IPHONE_SIMULATOR
#define DEFINE_FUNC(name) decltype(::name) *name##_local = nullptr;
DEFINE_EFFECT_FUNCS
#undef DEFINE_FUNC
#endif

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
