// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_path_effect.h"

namespace lynx {
namespace animax {

std::shared_ptr<DashPathEffect> SkityDashPathEffect::Make(const float* values,
                                                          size_t size,
                                                          float offset) {
  return std::make_shared<SkityDashPathEffect>(
      skity::PathEffect::MakeDashPathEffect(values, size, offset));
}

SkityDashPathEffect::SkityDashPathEffect(
    std::shared_ptr<skity::PathEffect> effect)
    : skity_effect_(std::move(effect)) {}

}  // namespace animax
}  // namespace lynx
