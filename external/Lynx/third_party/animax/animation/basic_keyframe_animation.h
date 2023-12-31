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

#ifndef ANIMAX_ANIMATION_BASIC_KEYFRAME_ANIMATION_H_
#define ANIMAX_ANIMATION_BASIC_KEYFRAME_ANIMATION_H_

#include "animax/animation/keyframe_animation.h"
#include "animax/model/gradient/gradient_color_model.h"
#include "animax/model/keyframe/path_keyframe_model.h"
#include "animax/render/include/path_measure.h"

namespace lynx {
namespace animax {

using BaseColorKeyframeAnimation = BaseKeyframeAnimation<Color, Color>;
class ColorKeyframeAnimation : public KeyframeAnimation<Color> {
 public:
  ColorKeyframeAnimation(
      std::vector<std::unique_ptr<KeyframeModel<Color>>>& frames)
      : KeyframeAnimation<Color>(frames) {}
  const Color& GetValue(KeyframeModel<Color>& keyframe,
                        float progress) const override;
  const Color& GetColorValue(KeyframeModel<Color>& keyframe,
                             float progress) const;
};

using BaseFloatKeyframeAnimation = BaseKeyframeAnimation<Float, Float>;
class FloatKeyframeAnimation : public KeyframeAnimation<Float> {
 public:
  FloatKeyframeAnimation(
      std::vector<std::unique_ptr<KeyframeModel<Float>>>& frames)
      : KeyframeAnimation<Float>(frames) {}
  const Float& GetValue(KeyframeModel<Float>& keyframe,
                        float progress) const override;
  const Float& GetFloatValue(KeyframeModel<Float>& keyframe,
                             float progress) const;
};

using BaseIntegerKeyframeAnimation = BaseKeyframeAnimation<Integer, Integer>;
class IntegerKeyframeAnimation : public KeyframeAnimation<Integer> {
 public:
  IntegerKeyframeAnimation(
      std::vector<std::unique_ptr<KeyframeModel<Integer>>>& frames)
      : KeyframeAnimation<Integer>(frames) {}
  const Integer& GetValue(KeyframeModel<Integer>& keyframe,
                          float progress) const override;
  const Integer& GetIntValue(KeyframeModel<Integer>& keyframe,
                             float progress) const;
};

using BasePointFKeyframeAnimation = BaseKeyframeAnimation<PointF, PointF>;
class PointKeyframeAnimation : public KeyframeAnimation<PointF> {
 public:
  PointKeyframeAnimation(
      std::vector<std::unique_ptr<KeyframeModel<PointF>>>& frames)
      : KeyframeAnimation<PointF>(frames) {}
  const PointF& GetValue(KeyframeModel<PointF>& keyframe,
                         float progress) const override;
  const PointF& GetValue(KeyframeModel<PointF>& keyframe, float progress,
                         float x_progress, float y_progress) const override;

 protected:
  const PointF& GetValueXY(KeyframeModel<PointF>& keyframe,
                           float linear_progress, float x_progress,
                           float y_progress) const;
};

using BaseScaleXYKeyframeAnimation = BaseKeyframeAnimation<ScaleXY, ScaleXY>;
class ScaleKeyframeAnimation : public KeyframeAnimation<ScaleXY> {
 public:
  ScaleKeyframeAnimation(
      std::vector<std::unique_ptr<KeyframeModel<ScaleXY>>>& frames)
      : KeyframeAnimation<ScaleXY>(frames) {}
  const ScaleXY& GetValue(KeyframeModel<ScaleXY>& keyframe,
                          float progress) const override;
};

class PathKeyframeAnimation : public KeyframeAnimation<PointF> {
 public:
  PathKeyframeAnimation(
      std::vector<std::unique_ptr<KeyframeModel<PointF>>>& frames);
  const PointF& GetValue(KeyframeModel<PointF>& keyframe,
                         float progress) const override;

 private:
  mutable PathKeyframeModel* path_measure_keyframe_ = nullptr;
  std::shared_ptr<PathMeasure> path_measure_;
};

using BaseGradientKeyframeAnimation =
    BaseKeyframeAnimation<GradientColorModel, GradientColorModel>;
class GradientColorKeyframeAnimation
    : public KeyframeAnimation<GradientColorModel> {
 public:
  using GradientColorKeyframeList =
      std::vector<std::unique_ptr<KeyframeModel<GradientColorModel>>>;

  GradientColorKeyframeAnimation(GradientColorKeyframeList& frames)
      : KeyframeAnimation<GradientColorModel>(frames) {
    auto size = frames[0]->IsStartValueEmpty()
                    ? 0
                    : frames[0]->GetStartValue().GetSize();
    intermediate_.Init(size);
  }
  const GradientColorModel& GetValue(
      KeyframeModel<GradientColorModel>& keyframe,
      float progress) const override;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATION_BASIC_KEYFRAME_ANIMATION_H_
