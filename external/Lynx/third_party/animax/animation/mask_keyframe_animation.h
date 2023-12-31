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

#ifndef ANIMAX_ANIMATION_MASK_KEYFRAME_ANIMATION_H_
#define ANIMAX_ANIMATION_MASK_KEYFRAME_ANIMATION_H_

#include <memory>
#include <vector>

#include "animax/animation/basic_keyframe_animation.h"
#include "animax/animation/keyframe_animation.h"
#include "animax/animation/shape_keyframe_animation.h"
#include "animax/model/basic_model.h"
#include "animax/model/mask_model.h"
#include "animax/model/shape/shape_data_model.h"
#include "animax/render/include/path.h"

namespace lynx {
namespace animax {

class MaskKeyframeAnimation {
 public:
  using MaskAnimationList =
      std::vector<std::unique_ptr<BaseShapeKeyframeAnimation>>;
  using OpacityAnimationList =
      std::vector<std::unique_ptr<BaseIntegerKeyframeAnimation>>;
  using MaskModelList = std::vector<std::unique_ptr<MaskModel>>;

  MaskKeyframeAnimation(MaskModelList& masks) : masks_(masks) {
    for (auto& mask : masks_) {
      mask_animations_.push_back(mask->mask_path_->CreateAnimation());
      opacity_animations_.push_back(mask->opacity_->CreateAnimation());
    }
  }

  const MaskAnimationList& GetMaskAnimations() const {
    return mask_animations_;
  }
  const OpacityAnimationList& GetOpacityAnimations() const {
    return opacity_animations_;
  }
  const MaskModelList& GetMasks() const { return masks_; }

 private:
  MaskAnimationList mask_animations_;
  OpacityAnimationList opacity_animations_;
  MaskModelList& masks_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATION_MASK_KEYFRAME_ANIMATION_H_
