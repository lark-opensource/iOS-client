// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_UTIL_H_
#define ANIMAX_RENDER_SKIA_SKIA_UTIL_H_

#include "animax/model/basic_model.h"
#include "animax/render/skia/skia.h"

namespace lynx {
namespace animax {

static inline SkRect MakeRect(float left, float top, float right,
                              float bottom) {
  return SkRect::MakeLTRB(left, top, right, bottom);
}

static inline SkRect MakeRect(const RectF &rect) {
  return MakeRect(rect.GetLeft(), rect.GetTop(), rect.GetRight(),
                  rect.GetBottom());
}

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_UTIL_H_
