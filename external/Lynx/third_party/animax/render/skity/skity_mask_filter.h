// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_MASK_FILTER_H_
#define ANIMAX_RENDER_SKITY_SKITY_MASK_FILTER_H_

#include "animax/render/include/mask_filter.h"
#include "skity/skity.hpp"

namespace lynx {
namespace animax {

class SkityMaskFilter : public MaskFilter {
 public:
  explicit SkityMaskFilter(std::shared_ptr<skity::MaskFilter> filter)
      : mask_filter_(std::move(filter)) {}

  ~SkityMaskFilter() override = default;

  std::shared_ptr<skity::MaskFilter> const& GetMaskFilter() const {
    return mask_filter_;
  }

  static std::unique_ptr<MaskFilter> MakeBlur(float radius);

 private:
  std::shared_ptr<skity::MaskFilter> mask_filter_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_MASK_FILTER_H_
