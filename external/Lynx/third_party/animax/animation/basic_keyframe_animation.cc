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

#include "animax/animation/basic_keyframe_animation.h"

#include "animax/base/log.h"
#include "animax/base/misc_util.h"
#include "animax/render/include/context.h"

namespace lynx {
namespace animax {
const Color& ColorKeyframeAnimation::GetValue(KeyframeModel<Color>& keyframe,
                                              float progress) const {
  return ColorKeyframeAnimation::GetColorValue(keyframe, progress);
}

const Color& ColorKeyframeAnimation::GetColorValue(
    KeyframeModel<Color>& keyframe, float progress) const {
  intermediate_.Reset();
  if (KeyframeAnimation::CheckNullValue(keyframe)) {
    return intermediate_;
  }

  GammaEvaluate(keyframe.GetStartValue(), keyframe.GetEndValue(), progress,
                &intermediate_);
  return intermediate_;
}

const Float& FloatKeyframeAnimation::GetValue(KeyframeModel<Float>& keyframe,
                                              float progress) const {
  return FloatKeyframeAnimation::GetFloatValue(keyframe, progress);
}

const Float& FloatKeyframeAnimation::GetFloatValue(
    KeyframeModel<Float>& keyframe, float progress) const {
  intermediate_.Reset();
  if (KeyframeAnimation::CheckNullValue(keyframe)) {
    return intermediate_;
  }

  // TODO(aiyongbiao): value callback p1
  Lerp(keyframe.GetStartValue(), keyframe.GetEndValue(), progress,
       &intermediate_);
  return intermediate_;
}

const Integer& IntegerKeyframeAnimation::GetValue(
    KeyframeModel<Integer>& keyframe, float progress) const {
  return IntegerKeyframeAnimation::GetIntValue(keyframe, progress);
}

const Integer& IntegerKeyframeAnimation::GetIntValue(
    KeyframeModel<Integer>& keyframe, float progress) const {
  intermediate_.Reset();
  if (KeyframeAnimation::CheckNullValue(keyframe)) {
    return intermediate_;
  }

  // TODO(aiyongbiao): value callback p1

  Lerp(keyframe.GetStartValue(), keyframe.GetEndValue(), progress,
       &intermediate_);
  return intermediate_;
}

const PointF& PointKeyframeAnimation::GetValue(KeyframeModel<PointF>& keyframe,
                                               float progress) const {
  return PointKeyframeAnimation::GetValueXY(keyframe, progress, progress,
                                            progress);
}

const PointF& PointKeyframeAnimation::GetValue(KeyframeModel<PointF>& keyframe,
                                               float progress, float x_progress,
                                               float y_progress) const {
  return PointKeyframeAnimation::GetValueXY(keyframe, progress, x_progress,
                                            y_progress);
}

const PointF& PointKeyframeAnimation::GetValueXY(
    KeyframeModel<PointF>& keyframe, float linear_progress, float x_progress,
    float y_progress) const {
  intermediate_.Reset();
  if (KeyframeAnimation::CheckNullValue(keyframe)) {
    return intermediate_;
  }

  auto& start_point = keyframe.GetStartValue();
  auto& end_point = keyframe.GetEndValue();

  // TODO(aiyongbiao): value callback p1

  intermediate_.Set(Lerp(start_point.GetX(), end_point.GetX(), x_progress),
                    Lerp(start_point.GetY(), end_point.GetY(), y_progress));
  return intermediate_;
}

const ScaleXY& ScaleKeyframeAnimation::GetValue(
    KeyframeModel<ScaleXY>& keyframe, float progress) const {
  intermediate_.Reset();
  if (KeyframeAnimation::CheckNullValue(keyframe)) {
    return intermediate_;
  }

  auto& start_trans = keyframe.GetStartValue();
  auto& end_trans = keyframe.GetEndValue();

  // TODO(aiyongbiao): value callback is null p1

  intermediate_.Set(
      Lerp(start_trans.GetScaleX(), end_trans.GetScaleX(), progress),
      Lerp(start_trans.GetScaleY(), end_trans.GetScaleY(), progress));

  return intermediate_;
}

PathKeyframeAnimation::PathKeyframeAnimation(
    std::vector<std::unique_ptr<KeyframeModel<PointF>>>& frames)
    : KeyframeAnimation<PointF>(frames),
      path_measure_(Context::MakePathMeasure()) {}

const PointF& PathKeyframeAnimation::GetValue(KeyframeModel<PointF>& keyframe,
                                              float progress) const {
  intermediate_.Reset();
  if (keyframe.GetType() != KeyframeType::kPath) {
    return keyframe.GetStartValue();
  }

  auto path_keyframe = static_cast<PathKeyframeModel*>(&keyframe);
  const auto path = path_keyframe->GetPath();
  if (path == nullptr) {
    return keyframe.GetStartValue();
  }

  // TODO(aiyongbiao): value callback p1

  if (path_measure_keyframe_ != path_keyframe) {
    path_measure_->SetPath(*path, false);
    path_measure_keyframe_ = path_keyframe;
  }

  path_measure_->GetPosTan(progress * path_measure_->GetLength(),
                           &intermediate_);
  return intermediate_;
}

const GradientColorModel& GradientColorKeyframeAnimation::GetValue(
    KeyframeModel<GradientColorModel>& keyframe, float progress) const {
  intermediate_.LerpColor(keyframe.GetStartValue(), keyframe.GetEndValue(),
                          progress);
  return intermediate_;
}

}  // namespace animax
}  // namespace lynx
