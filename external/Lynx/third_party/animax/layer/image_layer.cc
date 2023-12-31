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

#include "animax/layer/image_layer.h"

#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

ImageLayer::ImageLayer(std::shared_ptr<LayerModel>& layer_model,
                       CompositionModel& composition)
    : BaseLayer(layer_model, composition),
      paint_(Context::MakePaint()),
      scale_(composition.GetScale()) {
  auto id = layer_model_->GetRefId();
  image_asset_ = composition.GetImages()[id];

  paint_->SetAntiAlias(true);
}

void ImageLayer::GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                           bool apply_parent) {
  BaseLayer::GetBounds(out_bounds, parent_matrix, apply_parent);
  if (image_asset_) {
    out_bounds.Set(0, 0, image_asset_->width_ * scale_,
                   image_asset_->height_ * scale_);
    bounds_matrix_->MapRect(out_bounds);
  }
}

void ImageLayer::DrawLayer(Canvas& canvas, Matrix& parent_matrix,
                           int32_t parent_alpha) {
  auto image = GetImage(canvas.GetRealContext());
  if (image == nullptr || image_asset_ == nullptr) {
    return;
  }

  paint_->SetAlpha(parent_alpha);
  if (color_filter_animation_) {
    paint_->SetColorFilter(*color_filter_animation_->GetValue());
  }

  canvas.Save();
  canvas.Concat(parent_matrix);
  src_.Set(0, 0, static_cast<int>(image->GetWidth()),
           static_cast<int>(image->GetHeight()));
  dst_.Set(0, 0, static_cast<int>(image_asset_->width_ * scale_),
           static_cast<int>(image_asset_->height_ * scale_));

  canvas.DrawImageRect(*image, src_, dst_, *paint_);
  canvas.Restore();
}

Image* ImageLayer::GetImage(RealContext* real_context) {
  if (image_animation_) {
    //        const auto& image = image_animation_->GetValue();
    return nullptr;  // TODO(aiyongbiao): implement this
  }

  if (image_asset_) {
    return image_asset_->GetImage(real_context);
  }

  return nullptr;
}

}  // namespace animax
}  // namespace lynx
