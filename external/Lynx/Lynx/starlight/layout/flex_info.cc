// Copyright 2017 The Lynx Authors. All rights reserved.

#include "starlight/layout/flex_info.h"

namespace lynx {
namespace starlight {
FlexInfo::~FlexInfo() {
  if (!line_info_.empty()) {
    for (LineInfo* line_info : line_info_) {
      delete line_info;
      line_info = nullptr;
    }
    line_info_.clear();
  }
}

void FlexInfo::Reset() {
  std::fill(flex_base_size_.begin(), flex_base_size_.end(), 0);
  std::fill(hypothetical_main_size_.begin(), hypothetical_main_size_.end(), 0);
  std::fill(hypothetical_cross_size_.begin(), hypothetical_cross_size_.end(),
            0);
  std::fill(flex_main_size_.begin(), flex_main_size_.end(), 0);
  std::fill(flex_cross_size_.begin(), flex_cross_size_.end(), 0);
  std::fill(apply_stretch_later_.begin(), apply_stretch_later_.end(), false);

  for (LineInfo* line_info : line_info_) {
    delete line_info;
    line_info = nullptr;
  }
  line_info_.clear();
}
}  // namespace starlight
}  // namespace lynx
