// Copyright (c) 2023 The Lynx Authors. All rights reserved.

#ifndef THIRD_PARTY_KRYPTON_CANVAS_WORKAROUND_RUNTIME_FLAGS_FOR_WORKAROUND_H_
#define THIRD_PARTY_KRYPTON_CANVAS_WORKAROUND_RUNTIME_FLAGS_FOR_WORKAROUND_H_

#include <atomic>

#include "base/no_destructor.h"

namespace lynx {
namespace canvas {
namespace workaround {
// actually we need flag for each surface, but for minimize changes we use one
// flag now.
// TODO(luchengxuan) replaced with surface related flag.
extern std::atomic_bool any_surface_resized;
}  // namespace workaround
}  // namespace canvas
}  // namespace lynx

#endif  // THIRD_PARTY_KRYPTON_CANVAS_WORKAROUND_RUNTIME_FLAGS_FOR_WORKAROUND_H_
