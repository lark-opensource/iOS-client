// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_UTIL_H_
#define ANIMAX_RENDER_SKITY_SKITY_UTIL_H_

#include "animax/model/basic_model.h"
#include "skity/skity.hpp"

namespace lynx {
namespace animax {

class SkityUtil final {
 public:
  SkityUtil() = delete;
  ~SkityUtil() = delete;

  static skity::Rect MakeSkityRect(RectF const &rec);
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_UTIL_H_
