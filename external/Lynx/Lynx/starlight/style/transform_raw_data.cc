// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/transform_raw_data.h"

namespace lynx {
namespace starlight {

TransformRawData::TransformRawData()
    : type(TransformType::kNone),
      p0(NLength::MakeUnitNLength(0.0f)),
      p1(NLength::MakeUnitNLength(0.0f)),
      p2(NLength::MakeUnitNLength(0.0f)) {}

void TransformRawData::Reset() {
  type = TransformType::kNone;
  p0 = NLength::MakeUnitNLength(0.0f);
  p1 = NLength::MakeUnitNLength(0.0f);
  p2 = NLength::MakeUnitNLength(0.0f);
}
}  // namespace starlight
}  // namespace lynx
