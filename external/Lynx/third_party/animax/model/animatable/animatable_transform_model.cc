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

#include "animax/model/animatable/animatable_transform_model.h"

namespace lynx {
namespace animax {

AnimatableTransformModel::AnimatableTransformModel(
    std::unique_ptr<AnimatablePathValue> anchor_point,
    std::unique_ptr<BasePointFAnimatableValue> position,
    std::unique_ptr<AnimatableScaleValue> scale,
    std::unique_ptr<AnimatableFloatValue> rotation,
    std::unique_ptr<AnimatableIntegerValue> opacity,
    std::unique_ptr<AnimatableFloatValue> skew,
    std::unique_ptr<AnimatableFloatValue> skewAngle,
    std::unique_ptr<AnimatableFloatValue> start_opacity,
    std::unique_ptr<AnimatableFloatValue> end_opacity)
    : anchor_point_(std::move(anchor_point)),
      position_(std::move(position)),
      scale_(std::move(scale)),
      rotation_(std::move(rotation)),
      opacity_(std::move(opacity)),
      skew_(std::move(skew)),
      skew_angle_(std::move(skewAngle)),
      start_opacity_(std::move(start_opacity)),
      end_opacity_(std::move(end_opacity)) {}

std::unique_ptr<TransformKeyframeAnimation>
AnimatableTransformModel::CreateAnimation() {
  return std::make_unique<TransformKeyframeAnimation>(*this);
}

}  // namespace animax
}  // namespace lynx
