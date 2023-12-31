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

#include "animax/animation/drop_shadow_keyframe_animation.h"

#include "animax/animation/keyframe_animation.h"
#include "animax/content/path/path_util.h"
#include "animax/layer/base_layer.h"

namespace lynx {
namespace animax {

DropShadowKeyframeAnimation::DropShadowKeyframeAnimation(
    AnimationListener* listener, BaseLayer& layer,
    DropShadowEffectModel& model) {
  listener_ = listener;

  color_ = model.color_->CreateAnimation();
  layer.AddAnimation(color_.get());

  opacity_ = model.opacity_->CreateAnimation();
  layer.AddAnimation(opacity_.get());

  direction_ = model.direction_->CreateAnimation();
  layer.AddAnimation(direction_.get());

  distance_ = model.distance_->CreateAnimation();
  layer.AddAnimation(distance_.get());

  radius_ = model.radius_->CreateAnimation();
  layer.AddAnimation(radius_.get());
}

void DropShadowKeyframeAnimation::Init() {
  if (color_) {
    color_->AddUpdateListener(this);
  }
  if (opacity_) {
    opacity_->AddUpdateListener(this);
  }
  if (direction_) {
    direction_->AddUpdateListener(this);
  }
  if (distance_) {
    distance_->AddUpdateListener(this);
  }
  if (radius_) {
    radius_->AddUpdateListener(this);
  }
}

void DropShadowKeyframeAnimation::OnValueChanged() {
  is_dirty_ = true;
  listener_->OnValueChanged();
}

void DropShadowKeyframeAnimation::ApplyTo(Paint& paint) {
  if (!is_dirty_) {
    return;
  }
  is_dirty_ = false;

  auto direct_rad = direction_->GetValue().Get() * kDegreesToRadians;
  auto distance = distance_->GetValue().Get();
  auto x = std::sin(direct_rad) * distance;
  auto y = std::cos(direct_rad + kPI) * distance;
  const auto& color = color_->GetValue();
  auto opacity = std::round(opacity_->GetValue().Get());
  auto new_color =
      Color::ToInt(opacity, color.GetR(), color.GetG(), color.GetB());
  auto radius = radius_->GetValue().Get();
  paint.SetShadowLayer(radius, x, y, new_color);
}

}  // namespace animax
}  // namespace lynx
