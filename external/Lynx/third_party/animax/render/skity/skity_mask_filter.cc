// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_mask_filter.h"

namespace lynx {
namespace animax {

std::unique_ptr<MaskFilter> SkityMaskFilter::MakeBlur(float radius) {
  return std::make_unique<SkityMaskFilter>(
      skity::MaskFilter::MakeBlur(skity::BlurStyle::kNormal, radius));
}

}  // namespace animax
}  // namespace lynx
