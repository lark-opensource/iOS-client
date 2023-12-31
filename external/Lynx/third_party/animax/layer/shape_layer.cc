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

#include "animax/layer/shape_layer.h"

#include <memory>
#include <vector>

#include "animax/layer/composition_layer.h"
#include "animax/model/shape/shape_group_model.h"

namespace lynx {
namespace animax {

ShapeLayer::ShapeLayer(std::shared_ptr<LayerModel>& layer_model,
                       CompositionLayer& composition_layer,
                       CompositionModel& composition)
    : BaseLayer(layer_model, composition),
      composition_layer_(&composition_layer) {}

void ShapeLayer::Init() {
  BaseLayer::Init();

  std::string name = "__container";
  shape_group_model_ =
      std::make_shared<ShapeGroupModel>(name, layer_model_->GetShapes(), false);
  content_group_ =
      std::make_unique<ContentGroup>(*this, *shape_group_model_, composition_);
  content_group_->Init();

  auto empty_contents = std::vector<Content*>();
  content_group_->SetContents(empty_contents, empty_contents);
}

void ShapeLayer::DrawLayer(Canvas& canvas, Matrix& matrix, int32_t alpha) {
  if (content_group_) {
    content_group_->Draw(canvas, matrix, alpha);
  }
  // TODO(aiyongbiao): need check at else
}

void ShapeLayer::GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                           bool apply_parent) {
  BaseLayer::GetBounds(out_bounds, parent_matrix, apply_parent);
  if (content_group_) {
    content_group_->GetBounds(out_bounds, *bounds_matrix_, apply_parent);
  }
}

BlurEffectModel* ShapeLayer::GetBlurEffect() {
  auto* effect = BaseLayer::GetBlurEffect();
  if (effect) {
    return effect;
  }
  return composition_layer_->GetBlurEffect();
}

DropShadowEffectModel* ShapeLayer::GetDropEffect() {
  auto* drop = BaseLayer::GetDropEffect();
  if (drop) {
    return drop;
  }
  return composition_layer_->GetDropEffect();
}

}  // namespace animax
}  // namespace lynx
