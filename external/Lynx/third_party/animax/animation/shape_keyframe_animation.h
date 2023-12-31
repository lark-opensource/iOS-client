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

#ifndef ANIMAX_ANIMATION_SHAPE_KEYFRAME_ANIMATION_H_
#define ANIMAX_ANIMATION_SHAPE_KEYFRAME_ANIMATION_H_

#include "animax/animation/keyframe_animation.h"
#include "animax/content/shape/shape_modifier_content.h"
#include "animax/model/shape/shape_data_model.h"
#include "animax/render/include/path.h"

namespace lynx {
namespace animax {

using BaseShapeKeyframeAnimation =
    BaseKeyframeAnimation<ShapeDataModel, std::unique_ptr<Path>>;
class ShapeKeyframeAnimation : public BaseShapeKeyframeAnimation {
 public:
  ShapeKeyframeAnimation(
      std::vector<std::unique_ptr<KeyframeModel<ShapeDataModel>>>& frames)
      : BaseShapeKeyframeAnimation(frames) {}

  const std::unique_ptr<Path>& GetValue(KeyframeModel<ShapeDataModel>& keyframe,
                                        float progress) const override;

  void SetShapeModifiers(std::vector<ShapeModifierContent*>& contents) {
    shape_modifiers_ = contents;
  }

  AnimationType Type() override { return AnimationType::kShape; }

 private:
  void GetPathFromData(ShapeDataModel& shape_data, Path* out_path) const;

  mutable ShapeDataModel temp_shape_data_;
  mutable PointF temp_point_;

  std::vector<ShapeModifierContent*> shape_modifiers_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATION_SHAPE_KEYFRAME_ANIMATION_H_
