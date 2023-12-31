// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_mask_filter.h"

namespace lynx {
namespace animax {

std::unique_ptr<MaskFilter> SkiaMaskFilter::MakeSkiaBlur(float radius) {
  return std::make_unique<SkiaMaskFilter>(
      SkMaskFilter::MakeBlur(SkBlurStyle::kNormal_SkBlurStyle, radius));
}

}  // namespace animax
}  // namespace lynx
