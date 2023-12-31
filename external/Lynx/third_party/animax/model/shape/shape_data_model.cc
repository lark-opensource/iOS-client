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

#include "animax/model/shape/shape_data_model.h"

#include "animax/base/log.h"
#include "animax/base/misc_util.h"
#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

void ShapeDataModel::InterpolateBetween(ShapeDataModel& shape_data1,
                                        ShapeDataModel& shape_data2,
                                        float percentage) {
  closed_ = shape_data1.IsClosed() || shape_data2.IsClosed();

  if (shape_data1.GetCurves().size() != shape_data2.GetCurves().size()) {
    ANIMAX_LOGI("curves not same size");
  }

  auto point_size =
      std::min(shape_data1.GetCurves().size(), shape_data2.GetCurves().size());
  if (curves_.size() < point_size) {
    for (auto i = curves_.size(); i < point_size; i++) {
      curves_.push_back(CubicCurveModel::Make());
    }
  } else if (curves_.size() > point_size) {
    auto index = curves_.size() - 1;
    for (auto it = curves_.rbegin(); it != curves_.rend(); it++) {
      if (index >= point_size) {
        curves_.pop_back();
        index--;
      } else {
        break;
      }
    }
  }

  auto& initial_point1 = shape_data1.GetInitialPoint();
  auto& initial_point2 = shape_data2.GetInitialPoint();

  SetInitialPoint(
      Lerp(initial_point1.GetX(), initial_point2.GetX(), percentage),
      Lerp(initial_point1.GetY(), initial_point2.GetY(), percentage));

  auto index = curves_.size() - 1;
  for (auto it = curves_.rbegin(); it != curves_.rend(); it++) {
    auto& curve1 = shape_data1.GetCurves()[index];
    auto& curve2 = shape_data2.GetCurves()[index];

    auto& cp11 = curve1.GetControlPoint1();
    auto& cp21 = curve1.GetControlPoint2();
    auto& vertex1 = curve1.GetVertex();

    auto& cp12 = curve2.GetControlPoint1();
    auto& cp22 = curve2.GetControlPoint2();
    auto& vertex2 = curve2.GetVertex();

    curves_[index].SetControlPoint1(Lerp(cp11.GetX(), cp12.GetX(), percentage),
                                    Lerp(cp11.GetY(), cp12.GetY(), percentage));
    curves_[index].SetControlPoint2(Lerp(cp21.GetX(), cp22.GetX(), percentage),
                                    Lerp(cp21.GetY(), cp22.GetY(), percentage));
    curves_[index].SetVertex(Lerp(vertex1.GetX(), vertex2.GetX(), percentage),
                             Lerp(vertex1.GetY(), vertex2.GetY(), percentage));

    index--;
  }
}

void ShapeDataModel::SetInitialPoint(float x, float y) {
  initial_point_.Set(x, y);
}

}  // namespace animax
}  // namespace lynx
