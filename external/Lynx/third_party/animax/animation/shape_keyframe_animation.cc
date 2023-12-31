// Copyright 2023 The Lynx Authors. All rights reserved.
// Copyright 2018 Airbnb, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "animax/animation/shape_keyframe_animation.h"

#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

const std::unique_ptr<Path>& ShapeKeyframeAnimation::GetValue(
    KeyframeModel<ShapeDataModel>& keyframe, float progress) const {
  if (intermediate_ == nullptr) {
    intermediate_ = Context::MakePath();
  }

  auto& start_data = keyframe.GetStartValue();
  auto& end_data = keyframe.GetEndValue();

  temp_shape_data_.InterpolateBetween(start_data, end_data, progress);

  auto not_modified = true;
  for (auto it = shape_modifiers_.rbegin(); it != shape_modifiers_.rend();
       it++) {
    auto modified_shape_data = (*it)->ModifyShape(temp_shape_data_);
    if (!modified_shape_data.IsEmpty()) {
      GetPathFromData(modified_shape_data, intermediate_.get());
      not_modified = false;
    }
  }

  if (not_modified) {
    GetPathFromData(temp_shape_data_, intermediate_.get());
  }
  return intermediate_;
}

void ShapeKeyframeAnimation::GetPathFromData(ShapeDataModel& shape_data,
                                             Path* out_path) const {
  out_path->Reset();
  auto& initial_point = shape_data.GetInitialPoint();
  out_path->MoveTo(initial_point.GetX(), initial_point.GetY());
  temp_point_.Set(initial_point.GetX(), initial_point.GetY());
  for (auto& curve_data : shape_data.GetCurves()) {
    auto& cp1 = curve_data.GetControlPoint1();
    auto& cp2 = curve_data.GetControlPoint2();
    auto& vertex = curve_data.GetVertex();

    if (cp1.Equals(temp_point_) && cp2.Equals(vertex)) {
      out_path->LineTo(vertex.GetX(), vertex.GetY());
    } else {
      out_path->CubicTo(cp1.GetX(), cp1.GetY(), cp2.GetX(), cp2.GetY(),
                        vertex.GetX(), vertex.GetY());
    }
    temp_point_.Set(vertex.GetX(), vertex.GetY());
  }

  if (shape_data.IsClosed()) {
    out_path->Close();
  }
}

}  // namespace animax
}  // namespace lynx
