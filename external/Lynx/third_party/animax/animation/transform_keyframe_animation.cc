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

#include "animax/animation/transform_keyframe_animation.h"

#include "animax/content/path/path_util.h"
#include "animax/layer/base_layer.h"
#include "animax/model/animatable/animatable_transform_model.h"
#include "animax/model/basic_model.h"
#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

TransformKeyframeAnimation::TransformKeyframeAnimation(
    AnimatableTransformModel& model)
    : matrix_(Context::MakeMatrix()) {
  auto* anchor = model.GetAnchorPoint();
  if (anchor) {
    anchor_point_ = anchor->CreateAnimation();
  }

  auto* position = model.GetPosition();
  if (position) {
    position_ = position->CreateAnimation();
  }

  auto* scale = model.GetScale();
  if (scale) {
    scale_ = scale->CreateAnimation();
  }

  auto* rotation = model.GetRotation();
  if (rotation) {
    rotation_ = rotation->CreateAnimation();
  }

  auto* skew = model.GetSkew();
  if (skew) {
    skew_matrix1_ = Context::MakeMatrix();
    skew_matrix2_ = Context::MakeMatrix();
    skew_matrix3_ = Context::MakeMatrix();
    skew_ = skew->CreateAnimation();
  }

  if (skew_) {
    skew_values_ = std::make_unique<float[]>(9);
  }

  auto* skew_angle = model.GetSkewAngle();
  if (skew_angle) {
    skew_angle_ = skew_angle->CreateAnimation();
  }

  auto* opacity = model.GetOpacity();
  if (opacity) {
    opacity_ = opacity->CreateAnimation();
  }

  auto* start_opacity = model.GetStartOpacity();
  if (start_opacity) {
    start_opacity_ = start_opacity->CreateAnimation();
  }

  auto* end_opacity = model.GetEndOpacity();
  if (end_opacity) {
    end_opacity_ = end_opacity->CreateAnimation();
  }
}

void TransformKeyframeAnimation::AddAnimationToLayer(BaseLayer& layer) {
  layer.AddAnimation(opacity_.get());
  layer.AddAnimation(start_opacity_.get());
  layer.AddAnimation(end_opacity_.get());

  layer.AddAnimation(anchor_point_.get());
  layer.AddAnimation(position_.get());
  layer.AddAnimation(scale_.get());
  layer.AddAnimation(rotation_.get());

  layer.AddAnimation(skew_.get());
  layer.AddAnimation(skew_angle_.get());
}

void TransformKeyframeAnimation::AddListener(AnimationListener* listener) {
  if (opacity_) {
    opacity_->AddUpdateListener(listener);
  }

  if (start_opacity_) {
    start_opacity_->AddUpdateListener(listener);
  }

  if (end_opacity_) {
    end_opacity_->AddUpdateListener(listener);
  }

  if (anchor_point_) {
    anchor_point_->AddUpdateListener(listener);
  }

  if (position_) {
    position_->AddUpdateListener(listener);
  }

  if (scale_) {
    scale_->AddUpdateListener(listener);
  }

  if (rotation_) {
    rotation_->AddUpdateListener(listener);
  }

  if (skew_) {
    skew_->AddUpdateListener(listener);
  }

  if (skew_angle_) {
    skew_angle_->AddUpdateListener(listener);
  }
}

Matrix& TransformKeyframeAnimation::GetMatrixForRepeater(float amount) {
  auto position = position_ == nullptr ? nullptr : &position_->GetValue();
  auto scale = scale_ == nullptr ? nullptr : &scale_->GetValue();

  matrix_->Reset();
  if (position) {
    matrix_->PreTranslate(position->GetX() * amount, position->GetY() * amount);
  }
  if (scale) {
    matrix_->PreScale(std::pow(scale->GetScaleX(), amount),
                      std::pow(scale->GetScaleY(), amount));
  }
  if (rotation_) {
    auto rotation = rotation_->GetValue().Get();
    auto anchor_point =
        anchor_point_ == nullptr ? nullptr : &anchor_point_->GetValue();
    matrix_->PreRotate(rotation * amount,
                       anchor_point == nullptr ? 0 : anchor_point->GetX(),
                       anchor_point == nullptr ? 0 : anchor_point->GetY());
  }
  return *matrix_;
}

Matrix& TransformKeyframeAnimation::GetMatrix() {
  matrix_->Reset();
  if (position_) {
    const auto& position_value = position_->GetValue();
    if (!position_value.IsEmpty() &&
        (position_value.GetX() != 0 || position_value.GetY() != 0)) {
      matrix_->PreTranslate(position_value.GetX(), position_value.GetY());
    }
  }

  if (rotation_) {
    const auto& rotation_value = rotation_->GetValue();
    // TODO(aiyongbiao): use callback and GetFloatValue p1

    if (!rotation_value.IsEmpty() && rotation_value.Get() != 0) {
      matrix_->PreRotate(rotation_value.Get());
    }
  }

  if (skew_) {
    auto cos = skew_angle_ == nullptr
                   ? 0.0
                   : std::cos(PathUtil::ToRadians(
                         -skew_angle_->GetValue().Get() + 90.0));
    auto sin = skew_angle_ == nullptr
                   ? 1.0
                   : std::sin(PathUtil::ToRadians(
                         -skew_angle_->GetValue().Get() + 90.0));
    auto tan = std::tan(PathUtil::ToRadians(skew_->GetValue().Get()));

    ClearSkewValues();
    skew_values_[0] = cos;
    skew_values_[1] = sin;
    skew_values_[3] = -sin;
    skew_values_[4] = cos;
    skew_values_[8] = 1.0;
    skew_matrix1_->SetValues(skew_values_.get());
    ClearSkewValues();
    skew_values_[0] = 1.0;
    skew_values_[3] = tan;
    skew_values_[4] = 1.0;
    skew_values_[8] = 1.0;
    skew_matrix2_->SetValues(skew_values_.get());
    ClearSkewValues();
    skew_values_[0] = cos;
    skew_values_[1] = -sin;
    skew_values_[3] = sin;
    skew_values_[4] = cos;
    skew_values_[8] = 1.0;
    skew_matrix3_->SetValues(skew_values_.get());
    skew_matrix2_->PreConcat(*skew_matrix1_);
    skew_matrix3_->PreConcat(*skew_matrix2_);

    matrix_->PreConcat(*skew_matrix3_);
  }

  if (scale_) {
    const auto& scale_value = scale_->GetValue();
    if (!scale_value.IsEmpty() &&
        (scale_value.GetScaleX() != 1 || scale_value.GetScaleY() != 1)) {
      matrix_->PreScale(scale_value.GetScaleX(), scale_value.GetScaleY());
    }
  }

  if (anchor_point_) {
    const auto& anchor_value = anchor_point_->GetValue();
    if (!anchor_value.IsEmpty() &&
        (anchor_value.GetX() != 0 || anchor_value.GetY() != 0)) {
      matrix_->PreTranslate(-anchor_value.GetX(), -anchor_value.GetY());
    }
  }

  return *matrix_;
}

void TransformKeyframeAnimation::SetProgress(float progress) {
  if (opacity_) {
    opacity_->SetProgress(progress);
  }

  if (start_opacity_) {
    start_opacity_->SetProgress(progress);
  }

  if (end_opacity_) {
    end_opacity_->SetProgress(progress);
  }

  if (anchor_point_) {
    anchor_point_->SetProgress(progress);
  }

  if (position_) {
    position_->SetProgress(progress);
  }

  if (scale_) {
    scale_->SetProgress(progress);
  }

  if (rotation_) {
    rotation_->SetProgress(progress);
  }

  if (skew_) {
    skew_->SetProgress(progress);
  }

  if (skew_angle_) {
    skew_angle_->SetProgress(progress);
  }
}

void TransformKeyframeAnimation::ClearSkewValues() {
  for (auto i = 0; i < 9; i++) {
    skew_values_[i] = 0.0;
  }
}

}  // namespace animax
}  // namespace lynx
