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

#include "animax/animation/split_dimension_path_keyframe_animation.h"

namespace lynx {
namespace animax {

SplitDimensionPathKeyframeAnimation::SplitDimensionPathKeyframeAnimation(
    std::unique_ptr<BaseFloatKeyframeAnimation> x_animation,
    std::unique_ptr<BaseFloatKeyframeAnimation> y_animation,
    std::vector<std::unique_ptr<KeyframeModel<PointF>>>& frames)
    : BasePointFKeyframeAnimation(frames),
      x_animation_(std::move(x_animation)),
      y_animation_(std::move(y_animation)) {
  Init();
}

void SplitDimensionPathKeyframeAnimation::Init() { SetProgress(GetProgress()); }

void SplitDimensionPathKeyframeAnimation::SetProgress(float progress) {
  x_animation_->SetProgress(progress);
  y_animation_->SetProgress(progress);
  point_.Set(x_animation_->GetValue().Get(), y_animation_->GetValue().Get());
  for (auto& listener : listeners_) {
    listener->OnValueChanged();
  }
}

const PointF& SplitDimensionPathKeyframeAnimation::GetValue(
    KeyframeModel<PointF>& keyframe, float progress) const {
  // TODO(aiyongbiao): x, y callback p1
  intermediate_.Set(point_.GetX(), 0);
  intermediate_.Set(intermediate_.GetX(), point_.GetY());
  return intermediate_;
}

const PointF& SplitDimensionPathKeyframeAnimation::GetValue() const {
  // TODO(aiyongbiao): reuse above code
  intermediate_.Set(point_.GetX(), 0);
  intermediate_.Set(intermediate_.GetX(), point_.GetY());
  return intermediate_;
}

}  // namespace animax
}  // namespace lynx
