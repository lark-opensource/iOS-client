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

#ifndef ANIMAX_MODEL_GRADIENT_GRADIENT_FILL_MODEL_H_
#define ANIMAX_MODEL_GRADIENT_GRADIENT_FILL_MODEL_H_

#include <memory>

#include "animax/content/gradient/gradient_fill_content.h"
#include "animax/model/animatable/animatable_gradient_color_value.h"
#include "animax/model/basic_model.h"
#include "animax/model/content_model.h"
#include "animax/model/gradient/gradient_color_model.h"

namespace lynx {
namespace animax {

class GradientFillModel : public ContentModel {
 public:
  GradientFillModel(
      GradientType gradient_type, PathFillType fill_type,
      std::unique_ptr<AnimatableGradientColorValue> gradient_color,
      std::unique_ptr<AnimatableIntegerValue> opacity,
      std::unique_ptr<AnimatablePointValue> start_point,
      std::unique_ptr<AnimatablePointValue> end_point, std::string name,
      std::unique_ptr<AnimatableFloatValue> highlight_length,
      std::unique_ptr<AnimatableFloatValue> hightlight_angle, bool hidden)
      : gradient_type_(gradient_type),
        fill_type_(fill_type),
        gradient_color_(std::move(gradient_color)),
        opacity_(std::move(opacity)),
        start_point_(std::move(start_point)),
        end_point_(std::move(end_point)),
        highlight_length_(std::move(highlight_length)),
        hightlight_angle_(std::move(hightlight_angle)) {
    name_ = std::move(name);
    hidden_ = hidden;
  }

  std::unique_ptr<Content> ToContent(CompositionModel& composition,
                                     BaseLayer& layer) override {
    return std::make_unique<GradientFillContent>(layer, *this);
  }

 private:
  friend class GradientFillContent;

  GradientType gradient_type_;
  PathFillType fill_type_;
  std::unique_ptr<AnimatableGradientColorValue> gradient_color_;
  std::unique_ptr<AnimatableIntegerValue> opacity_;
  std::unique_ptr<AnimatablePointValue> start_point_;
  std::unique_ptr<AnimatablePointValue> end_point_;
  std::unique_ptr<AnimatableFloatValue> highlight_length_;
  std::unique_ptr<AnimatableFloatValue> hightlight_angle_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_GRADIENT_GRADIENT_FILL_MODEL_H_
