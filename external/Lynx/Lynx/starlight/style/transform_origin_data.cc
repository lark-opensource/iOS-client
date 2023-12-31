// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/transform_origin_data.h"

namespace lynx {
namespace starlight {
TransformOriginData::TransformOriginData()
    : x(NLength::MakePercentageNLength(50.f)),
      y(NLength::MakePercentageNLength(50.f)) {}
void TransformOriginData::Reset() {
  x = NLength::MakePercentageNLength(50.f);
  y = NLength::MakePercentageNLength(50.f);
}

}  // namespace starlight
}  // namespace lynx
