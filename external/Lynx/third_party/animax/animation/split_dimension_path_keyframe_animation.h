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

#ifndef ANIMAX_ANIMATION_SPLIT_DIMENSION_PATH_KEYFRAME_ANIMATION_H_
#define ANIMAX_ANIMATION_SPLIT_DIMENSION_PATH_KEYFRAME_ANIMATION_H_

#include "animax/animation/basic_keyframe_animation.h"
#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

class SplitDimensionPathKeyframeAnimation : public BasePointFKeyframeAnimation {
 public:
  SplitDimensionPathKeyframeAnimation(
      std::unique_ptr<BaseFloatKeyframeAnimation> x_animation,
      std::unique_ptr<BaseFloatKeyframeAnimation> y_animation,
      std::vector<std::unique_ptr<KeyframeModel<PointF>>>& frames);

  void Init();
  void SetProgress(float progress) override;
  const PointF& GetValue(KeyframeModel<PointF>& keyframe,
                         float progress) const override;
  const PointF& GetValue() const override;

 private:
  PointF point_;
  std::unique_ptr<BaseFloatKeyframeAnimation> x_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> y_animation_;

  std::vector<std::unique_ptr<KeyframeModel<PointF>>> empty_frames_;

  // TODO(aiyongbiao): value callbacks p1
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATION_SPLIT_DIMENSION_PATH_KEYFRAME_ANIMATION_H_
