// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_STARLIGHT_STYLE_PERSPECTIVE_DATA_H_
#define LYNX_STARLIGHT_STYLE_PERSPECTIVE_DATA_H_

#include "css/css_value.h"
#include "starlight/style/css_type.h"
#include "starlight/types/nlength.h"

namespace lynx {
namespace starlight {
struct PerspectiveData {
  NLength length_;
  mutable tasm::CSSValuePattern pattern_;
  PerspectiveData();
  ~PerspectiveData() = default;

  void Reset();

  bool operator==(const PerspectiveData& rhs) const {
    return length_ == rhs.length_ && pattern_ == rhs.pattern_;
  }
};

}  // namespace starlight
}  // namespace lynx
#endif  // LYNX_STARLIGHT_STYLE_PERSPECTIVE_DATA_H_
