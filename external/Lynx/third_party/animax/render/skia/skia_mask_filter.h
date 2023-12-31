// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_MASK_FILTER_H_
#define ANIMAX_RENDER_SKIA_SKIA_MASK_FILTER_H_

#include "animax/render/include/mask_filter.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

class SkiaMaskFilter : public MaskFilter {
 public:
  SkiaMaskFilter(sk_sp<SkMaskFilter> sk_filter)
      : sk_filter_(std::move(sk_filter)) {}
  ~SkiaMaskFilter() override = default;

  sk_sp<SkMaskFilter> GetSkMaskFilter() const { return sk_filter_; }

  static std::unique_ptr<MaskFilter> MakeSkiaBlur(float radius);

 private:
  sk_sp<SkMaskFilter> sk_filter_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_MASK_FILTER_H_
