// Copyright 2021 The Lynx Authors. All rights reserved.

#include "starlight/style/perspective_data.h"

namespace lynx {
namespace starlight {
PerspectiveData::PerspectiveData()
    : length_(NLength::MakeAutoNLength()),
      pattern_(tasm::CSSValuePattern::EMPTY) {}
void PerspectiveData::Reset() {
  length_ = NLength::MakeAutoNLength();
  pattern_ = tasm::CSSValuePattern::EMPTY;
}

}  // namespace starlight
}  // namespace lynx
