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

#ifndef ANIMAX_MODEL_ANIMATABLE_ANIMATABLE_SHAPE_VALUE_H_
#define ANIMAX_MODEL_ANIMATABLE_ANIMATABLE_SHAPE_VALUE_H_

#include <animax/model/composition_model.h>

#include <memory>

#include "animax/animation/shape_keyframe_animation.h"
#include "animax/model/animatable/animatable_value.h"
#include "animax/model/shape/shape_data_model.h"
#include "animax/render/include/path.h"

namespace lynx {
namespace animax {

class AnimatableShapeValue
    : public BaseAnimatableValue<ShapeDataModel, std::unique_ptr<Path>> {
 public:
  AnimatableShapeValue(){};
  bool IsStatic() { return false; }
  std::unique_ptr<BaseShapeKeyframeAnimation> CreateAnimation() {
    return std::make_unique<ShapeKeyframeAnimation>(frames_);
  }
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_ANIMATABLE_ANIMATABLE_SHAPE_VALUE_H_
