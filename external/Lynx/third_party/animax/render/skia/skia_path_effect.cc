// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_path_effect.h"

namespace lynx {
namespace animax {

std::shared_ptr<DashPathEffect> SkiaDashPathEffect::Make(const float* values,
                                                         size_t size,
                                                         float offset) {
  return std::make_shared<SkiaDashPathEffect>(
      SkDashPathEffect::Make(values, size, offset));
}

SkiaDashPathEffect::SkiaDashPathEffect(sk_sp<SkPathEffect> effect)
    : skia_dpe_(std::move(effect)) {}

}  // namespace animax
}  // namespace lynx
