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

#ifndef ANIMAX_MODEL_SHAPE_CIRCLE_SHAPE_MODEL_H_
#define ANIMAX_MODEL_SHAPE_CIRCLE_SHAPE_MODEL_H_

#include <string>

#include "animax/content/shape/ellipse_content.h"
#include "animax/model/animatable/animatable_value.h"
#include "animax/model/animatable/basic_animatable_value.h"
#include "animax/model/content_model.h"

namespace lynx {
namespace animax {

class CircleShapeModel : public ContentModel,
                         public std::enable_shared_from_this<CircleShapeModel> {
 public:
  CircleShapeModel(std::string name,
                   std::unique_ptr<BasePointFAnimatableValue> position,
                   std::unique_ptr<AnimatablePointValue> size, bool reversed,
                   bool hidden)
      : position_(std::move(position)),
        size_(std::move(size)),
        reversed_(reversed) {
    name_ = std::move(name);
    hidden_ = hidden;
  }

  std::unique_ptr<Content> ToContent(CompositionModel& composition,
                                     BaseLayer& layer) override {
    return std::make_unique<EllipseContent>(layer, shared_from_this());
  }

 private:
  friend class EllipseContent;

  std::unique_ptr<BasePointFAnimatableValue> position_;
  std::unique_ptr<AnimatablePointValue> size_;
  bool reversed_ = false;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_SHAPE_CIRCLE_SHAPE_MODEL_H_
