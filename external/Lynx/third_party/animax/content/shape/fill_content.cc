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

#include "animax/content/shape/fill_content.h"

#include "animax/model/shape/shape_fill_model.h"
#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

FillContent::FillContent(BaseLayer& layer, ShapeFillModel& fill,
                         CompositionModel& composition)
    : layer_(layer), path_(Context::MakePath()), paint_(Context::MakePaint()) {
  name_ = fill.GetName();
  hidden_ = fill.IsHidden();

  if (layer.GetBlurEffect()) {
    blur_element_ = std::make_unique<BlurElement>(layer);
  }

  if (layer_.GetDropEffect()) {
    drop_shadow_element_ = std::make_unique<DropShadowElement>(layer);
  }

  if (fill.GetColor() == nullptr || fill.GetOpacity() == nullptr) {
    color_animation_ = nullptr;
    opacity_animation_ = nullptr;
    return;
  }

  paint_->SetAntiAlias(true);
  path_->SetFillType(fill.GetFillType());

  color_animation_ = fill.GetColor()->CreateAnimation();
  layer_.AddAnimation(color_animation_.get());

  opacity_animation_ = fill.GetOpacity()->CreateAnimation();
  layer_.AddAnimation(opacity_animation_.get());
}

void FillContent::Init() {
  if (blur_element_) {
    blur_element_->Init();
  }

  if (color_animation_) {
    color_animation_->AddUpdateListener(this);
  }

  if (opacity_animation_) {
    opacity_animation_->AddUpdateListener(this);
  }

  if (drop_shadow_element_) {
    drop_shadow_element_->Init();
  }
}

void FillContent::OnValueChanged() {}

void FillContent::Draw(Canvas& canvas, Matrix& parent_matrix,
                       int32_t parent_alpha) {
  if (hidden_) {
    return;
  }

  Color color_value;
  if (color_animation_) {
    color_value = color_animation_->GetValue();
  }

  auto opacity = 0;
  if (opacity_animation_) {
    opacity = opacity_animation_->GetValue().Get();
  }

  auto alpha = parent_alpha / 255.0 * opacity / 100.0 * 255.0;
  color_value.SetA(std::clamp(alpha, 0.0, 255.0));
  paint_->SetColor(color_value);

  if (color_filter_animation_) {
    paint_->SetColorFilter(*color_filter_animation_->GetValue());
  }

  if (blur_element_) {
    blur_element_->Draw(*paint_, layer_, false);
  }

  if (drop_shadow_element_) {
    drop_shadow_element_->Draw(*paint_);
  }

  path_->Reset();
  for (auto& path : paths_) {
    path_->AddPath(path->GetPath(), parent_matrix);
  }

  canvas.DrawPath(*path_, *paint_);
}

void FillContent::GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                            bool apply_parent) {
  path_->Reset();
  for (auto& path : paths_) {
    path_->AddPath(path->GetPath(), parent_matrix);
  }
  path_->ComputeBounds(out_bounds, false);
  out_bounds.Set(out_bounds.GetLeft() - 1, out_bounds.GetTop() - 1,
                 out_bounds.GetRight() + 1, out_bounds.GetBottom() + 1);

  if (blur_element_) {
    float radius = blur_element_->GetBlurRadius();
    if (radius != 0.f) {
      float l = out_bounds.GetLeft();
      float t = out_bounds.GetTop();
      float r = out_bounds.GetRight();
      float b = out_bounds.GetBottom();

      out_bounds.Set(l - radius, t - radius, r + radius, b + radius);
    }
  }
}

void FillContent::SetContents(std::vector<Content*>& contents_before,
                              std::vector<Content*>& contents_after) {
  for (auto& content : contents_after) {
    if (content->SubPathType()) {
      paths_.push_back(content);
    }
  }
}

}  // namespace animax
}  // namespace lynx
