// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_PATH_EFFECT_H_
#define ANIMAX_RENDER_SKIA_SKIA_PATH_EFFECT_H_

#include "animax/render/include/path_effect.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

class SkiaDashPathEffect : public DashPathEffect {
 public:
  static std::shared_ptr<DashPathEffect> Make(const float* values, size_t size,
                                              float offset);

  SkiaDashPathEffect(sk_sp<SkPathEffect> effect);
  ~SkiaDashPathEffect() override = default;

  sk_sp<SkPathEffect> GetEffect() { return skia_dpe_; }

 private:
  sk_sp<SkPathEffect> skia_dpe_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_PATH_EFFECT_H_
