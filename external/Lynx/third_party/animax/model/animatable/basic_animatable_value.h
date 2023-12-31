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

#ifndef ANIMAX_MODEL_ANIMATABLE_BASIC_ANIMATABLE_VALUE_H_
#define ANIMAX_MODEL_ANIMATABLE_BASIC_ANIMATABLE_VALUE_H_

#include <memory>
#include <vector>

#include "animax/animation/basic_keyframe_animation.h"
#include "animax/animation/split_dimension_path_keyframe_animation.h"
#include "animax/model/animatable/animatable_value.h"
#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

class AnimatableFloatValue : public BaseAnimatableValue<Float, Float> {
 public:
  std::unique_ptr<BaseFloatKeyframeAnimation> CreateAnimation() override {
    return std::make_unique<FloatKeyframeAnimation>(frames_);
  }
};

class AnimatableIntegerValue : public BaseAnimatableValue<Integer, Integer> {
 public:
  std::unique_ptr<BaseIntegerKeyframeAnimation> CreateAnimation() override {
    return std::make_unique<IntegerKeyframeAnimation>(frames_);
  }
};

using BasePointFAnimatableValue = BaseAnimatableValue<PointF, PointF>;
class AnimatablePointValue : public BasePointFAnimatableValue {
 public:
  AnimatablePointValue(){};
  std::unique_ptr<BasePointFKeyframeAnimation> CreateAnimation() override {
    return std::make_unique<PointKeyframeAnimation>(frames_);
  }
};

class AnimatableScaleValue : public BaseAnimatableValue<ScaleXY, ScaleXY> {
 public:
  AnimatableScaleValue(){};
  std::unique_ptr<BaseScaleXYKeyframeAnimation> CreateAnimation() override {
    return std::make_unique<ScaleKeyframeAnimation>(frames_);
  }
};

class AnimatableColorValue : public BaseAnimatableValue<Color, Color> {
 public:
  std::unique_ptr<BaseColorKeyframeAnimation> CreateAnimation() override {
    return std::make_unique<ColorKeyframeAnimation>(frames_);
  }
};

class AnimatablePathValue : public BasePointFAnimatableValue {
 public:
  bool IsStatic() override {
    return frames_.size() == 1 && frames_[0]->IsStatic();
  }
  std::unique_ptr<BasePointFKeyframeAnimation> CreateAnimation() override {
    if (frames_[0]->IsStatic()) {
      return std::make_unique<PointKeyframeAnimation>(frames_);
    }
    return std::make_unique<PathKeyframeAnimation>(frames_);
  }
};

class AnimatableSplitDimensionPathValue : public BasePointFAnimatableValue {
 public:
  AnimatableSplitDimensionPathValue(
      std::unique_ptr<AnimatableFloatValue>& anim_x,
      std::unique_ptr<AnimatableFloatValue>& anim_y)
      : anim_x_dimen_(std::move(anim_x)), anim_y_dimen_(std::move(anim_y)) {}

  std::unique_ptr<BasePointFKeyframeAnimation> CreateAnimation() override {
    return std::make_unique<SplitDimensionPathKeyframeAnimation>(
        anim_x_dimen_->CreateAnimation(), anim_y_dimen_->CreateAnimation(),
        empty_frames_);
  }
  bool IsStatic() override {
    return anim_x_dimen_->IsStatic() && anim_y_dimen_->IsStatic();
  }
  AnimatableType Type() override { return AnimatableType::kSplitPath; }

 private:
  std::unique_ptr<AnimatableFloatValue> anim_x_dimen_;
  std::unique_ptr<AnimatableFloatValue> anim_y_dimen_;
  std::vector<std::unique_ptr<KeyframeModel<PointF>>> empty_frames_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_ANIMATABLE_BASIC_ANIMATABLE_VALUE_H_
