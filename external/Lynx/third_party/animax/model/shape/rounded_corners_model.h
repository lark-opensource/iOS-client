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

#ifndef ANIMAX_MODEL_SHAPE_ROUNDED_CORNERS_MODEL_H_
#define ANIMAX_MODEL_SHAPE_ROUNDED_CORNERS_MODEL_H_

#include "animax/content/shape/rounded_corners_content.h"
#include "animax/model/animatable/animatable_value.h"
#include "animax/model/content_model.h"

namespace lynx {
namespace animax {

class RoundedCornersModel : public ContentModel {
 public:
  RoundedCornersModel(std::string name,
                      std::unique_ptr<AnimatableFloatValue> corner_radius,
                      bool hidden)
      : corner_radius_(std::move(corner_radius)) {
    name_ = std::move(name);
    hidden_ = hidden;
  }

  std::unique_ptr<Content> ToContent(CompositionModel& composition,
                                     BaseLayer& layer) override {
    return std::make_unique<RoundedCornersContent>(layer, *this);
  }

 private:
  friend class RoundedCornersContent;

  std::unique_ptr<AnimatableFloatValue> corner_radius_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_SHAPE_ROUNDED_CORNERS_MODEL_H_
