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

#ifndef ANIMAX_ANIMATION_TRANSFORM_KEYFRAME_ANIMATION_H_
#define ANIMAX_ANIMATION_TRANSFORM_KEYFRAME_ANIMATION_H_

#include <memory>

#include "animax/animation/basic_keyframe_animation.h"
#include "animax/animation/keyframe_animation.h"
#include "animax/render/include/matrix.h"

namespace lynx {
namespace animax {

class AnimatableTransformModel;
class BaseLayer;

class TransformKeyframeAnimation {
 public:
  TransformKeyframeAnimation(AnimatableTransformModel& model);

  void AddAnimationToLayer(BaseLayer& layer);
  void AddListener(AnimationListener* listener);

  Matrix& GetMatrix();
  Matrix& GetMatrixForRepeater(float amount);

  BaseIntegerKeyframeAnimation* GetOpacity() { return opacity_.get(); }
  BaseFloatKeyframeAnimation* GetStartOpacity() { return start_opacity_.get(); }
  BaseFloatKeyframeAnimation* GetEndOpacity() { return end_opacity_.get(); }

  void SetProgress(float progress);

 private:
  void ClearSkewValues();

  std::unique_ptr<Matrix> matrix_;
  std::unique_ptr<Matrix> skew_matrix1_;
  std::unique_ptr<Matrix> skew_matrix2_;
  std::unique_ptr<Matrix> skew_matrix3_;
  std::unique_ptr<float[]> skew_values_;

  std::unique_ptr<BasePointFKeyframeAnimation> anchor_point_;
  std::unique_ptr<BasePointFKeyframeAnimation> position_;
  std::unique_ptr<BaseScaleXYKeyframeAnimation> scale_;
  std::unique_ptr<BaseFloatKeyframeAnimation> rotation_;
  std::unique_ptr<BaseIntegerKeyframeAnimation> opacity_;

  std::unique_ptr<BaseFloatKeyframeAnimation> skew_;
  std::unique_ptr<BaseFloatKeyframeAnimation> skew_angle_;

  std::unique_ptr<BaseFloatKeyframeAnimation> start_opacity_;
  std::unique_ptr<BaseFloatKeyframeAnimation> end_opacity_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATION_TRANSFORM_KEYFRAME_ANIMATION_H_
