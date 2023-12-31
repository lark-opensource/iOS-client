// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_PATH_EFFECT_H_
#define ANIMAX_RENDER_SKITY_SKITY_PATH_EFFECT_H_

#include <memory>

#include "animax/render/include/path_effect.h"
#include "skity/skity.hpp"

namespace lynx {
namespace animax {

class SkityDashPathEffect : public DashPathEffect {
 public:
  static std::shared_ptr<DashPathEffect> Make(const float* values, size_t size,
                                              float offset);

  SkityDashPathEffect(std::shared_ptr<skity::PathEffect> effect);
  ~SkityDashPathEffect() override = default;

  std::shared_ptr<skity::PathEffect> GetEffect() { return skity_effect_; }

 private:
  std::shared_ptr<skity::PathEffect> skity_effect_ = {};
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_PATH_EFFECT_H_
