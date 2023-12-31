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

#include "animax/layer/solid_layer.h"

#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

SolidLayer::SolidLayer(std::shared_ptr<LayerModel>& layer,
                       CompositionModel& composition)
    : BaseLayer(layer, composition),
      paint_(Context::MakePaint()),
      path_(Context::MakePath()) {}

void SolidLayer::Init() {
  BaseLayer::Init();

  paint_->SetAlpha(0);
  paint_->SetStyle(PaintStyle::kFill);
  paint_->SetColor(layer_model_->GetSolidColor());
}

void SolidLayer::DrawLayer(Canvas& canvas, Matrix& parent_matrix,
                           int32_t parent_alpha) {
  auto background_alpha = layer_model_->GetSolidColor().GetA();
  if (background_alpha == 0) {
    return;
  }

  auto opacity = transform_->GetOpacity() == nullptr
                     ? 100
                     : transform_->GetOpacity()->GetValue().Get();
  auto alpha = parent_alpha / 255.0 *
               (background_alpha / 255.0 * opacity / 100.0) * 255.0;
  paint_->SetAlpha(alpha);
  if (color_filter_animation_) {
    paint_->SetColorFilter(*color_filter_animation_->GetValue());
  }

  if (alpha > 0) {
    points_[0] = 0;
    points_[1] = 0;
    points_[2] = layer_model_->GetSolidWidth();
    points_[3] = 0;
    points_[4] = layer_model_->GetSolidWidth();
    points_[5] = layer_model_->GetSolidHeight();
    points_[6] = 0;
    points_[7] = layer_model_->GetSolidHeight();

    parent_matrix.MapPoints(points_, 4);
    path_->Reset();
    path_->MoveTo(points_[0], points_[1]);
    path_->LineTo(points_[2], points_[3]);
    path_->LineTo(points_[4], points_[5]);
    path_->LineTo(points_[6], points_[7]);
    path_->LineTo(points_[0], points_[1]);
    path_->Close();
    canvas.DrawPath(*path_, *paint_);
  }
}

void SolidLayer::GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                           bool apply_parent) {
  BaseLayer::GetBounds(out_bounds, parent_matrix, apply_parent);
  rect_.Set(0, 0, layer_model_->GetSolidWidth(),
            layer_model_->GetSolidHeight());
  bounds_matrix_->MapRect(rect_);
  out_bounds.Set(rect_);
}

}  // namespace animax
}  // namespace lynx
