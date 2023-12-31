// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_SURROUND_DATA_H_
#define LYNX_STARLIGHT_STYLE_SURROUND_DATA_H_

#include "starlight/style/borders_data.h"
#include "starlight/style/css_type.h"
#include "starlight/types/nlength.h"

namespace lynx {
namespace starlight {

class SurroundData {
 public:
  SurroundData();
  ~SurroundData() = default;
  void Reset();
  NLength left_;
  NLength right_;
  NLength top_;
  NLength bottom_;

  NLength margin_left_;
  NLength margin_right_;
  NLength margin_top_;
  NLength margin_bottom_;

  NLength padding_left_;
  NLength padding_right_;
  NLength padding_top_;
  NLength padding_bottom_;

  std::optional<BordersData> border_data_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_SURROUND_DATA_H_
