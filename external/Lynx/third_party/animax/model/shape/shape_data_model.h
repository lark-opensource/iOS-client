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

#ifndef ANIMAX_MODEL_SHAPE_SHAPE_DATA_MODEL_H_
#define ANIMAX_MODEL_SHAPE_SHAPE_DATA_MODEL_H_

#include <memory>
#include <vector>

#include "animax/model/basic_model.h"
#include "animax/model/shape/cubic_curve_model.h"

namespace lynx {
namespace animax {

class ShapeDataModel {
 public:
  static ShapeDataModel MakeEmpty() {
    auto model = ShapeDataModel();
    model.initial_point_ = PointF::MakeEmpty();
    return model;
  }

  ShapeDataModel() = default;

  void Init(PointF initial_point, bool closed) {
    initial_point_ = initial_point;
    closed_ = closed;
  }

  std::vector<CubicCurveModel>& GetCurves() const { return curves_; }
  PointF& GetInitialPoint() { return initial_point_; }

  void InterpolateBetween(ShapeDataModel& shape_data1,
                          ShapeDataModel& shape_data2, float percentage);

  bool IsClosed() const { return closed_; }
  void SetInitialPoint(float x, float y);
  void SetClosed(bool closed) { closed_ = closed; };

  bool IsEmpty() const { return initial_point_.IsEmpty(); }

 private:
  PointF initial_point_;
  bool closed_ = false;
  mutable std::vector<CubicCurveModel> curves_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_SHAPE_SHAPE_DATA_MODEL_H_
