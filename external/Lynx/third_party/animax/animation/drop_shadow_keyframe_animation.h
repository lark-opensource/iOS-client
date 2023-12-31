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

#ifndef ANIMAX_ANIMATION_DROP_SHADOW_KEYFRAME_ANIMATION_H_
#define ANIMAX_ANIMATION_DROP_SHADOW_KEYFRAME_ANIMATION_H_

#include <memory>
#include <vector>

#include "animax/animation/basic_keyframe_animation.h"
#include "animax/animation/keyframe_animation.h"
#include "animax/content/path/path_util.h"
#include "animax/model/basic_model.h"
#include "animax/model/effect/drop_shadow_effect_model.h"
#include "animax/render/include/paint.h"

namespace lynx {
namespace animax {

class BaseLayer;

class DropShadowKeyframeAnimation : public AnimationListener {
 public:
  DropShadowKeyframeAnimation(AnimationListener* listener, BaseLayer& layer,
                              DropShadowEffectModel& model);

  void Init();
  void OnValueChanged() override;

  void ApplyTo(Paint& paint);

  // TODO(aiyongbiao): set callback p1
 private:
  AnimationListener* listener_ = nullptr;
  std::unique_ptr<BaseColorKeyframeAnimation> color_;
  std::unique_ptr<BaseFloatKeyframeAnimation> opacity_;
  std::unique_ptr<BaseFloatKeyframeAnimation> direction_;
  std::unique_ptr<BaseFloatKeyframeAnimation> distance_;
  std::unique_ptr<BaseFloatKeyframeAnimation> radius_;

  bool is_dirty_ = true;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATION_DROP_SHADOW_KEYFRAME_ANIMATION_H_
