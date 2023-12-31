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

#include "animax/layer/composition_layer.h"

#include <unordered_map>

#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

CompositionLayer::CompositionLayer(std::shared_ptr<LayerModel>& layer_model,
                                   CompositionModel& composition)
    : BaseLayer(layer_model, composition), layer_paint_(Context::MakePaint()) {}

void CompositionLayer::Init() {
  BaseLayer::Init();

  auto* time_remapping = layer_model_->GetTimeRemapping();
  if (time_remapping) {
    time_remapping_animation_ = time_remapping->CreateAnimation();
    AddAnimation(time_remapping_animation_.get());
    time_remapping_animation_->AddUpdateListener(this);
  } else {
    time_remapping_animation_ = nullptr;
  }

  auto layer_map = std::unordered_map<int32_t, BaseLayer*>();
  BaseLayer* matted_layer = nullptr;
  for (auto it = layer_models_->rbegin(); it != layer_models_->rend(); it++) {
    auto cur_model = *it;
    auto layer = BaseLayer::forModel(*this, cur_model, composition_);
    if (layer == nullptr) {
      continue;
    }

    auto layer_ptr = layer.get();
    layer_map[layer->GetLayerModel()->GetId()] = layer_ptr;
    if (matted_layer) {
      matted_layer->SetMattedLayer(layer);
      matted_layer = nullptr;
    } else {
      layers_.insert(layers_.begin(), std::move(layer));
      switch (cur_model->GetMatteType()) {
        case MatteType::kAdd:
        case MatteType::kInvert:
          matted_layer = layer_ptr;
          break;
        default:
          break;
      }
    }
  }

  for (auto& it : layer_map) {
    auto id = it.first;
    auto layer = it.second;

    if (layer == nullptr) {
      continue;
    }

    auto parent_id = layer->GetLayerModel()->GetParentId();
    auto parent_layer = layer_map[parent_id];
    if (parent_layer) {
      layer->SetParentLayer(parent_layer);
    }
  }

  if (time_remapping_animation_) {
    time_remapping_animation_->AddUpdateListener(this);
  }
}

void CompositionLayer::DrawLayer(Canvas& canvas, Matrix& parent_matrix,
                                 int32_t parent_alpha) {
  new_clip_rect_.Set(0, 0, layer_model_->GetPreCompWidth(),
                     layer_model_->GetPreCompHeight());
  parent_matrix.MapRect(new_clip_rect_);

  // TODO(aiyongbiao): is drawing with offscreen p1
  canvas.Save();

  bool non_empty_rect = true;
  auto layer_name = layer_model_->GetName().data();
  bool ignore_clip = !clip_to_composition_bounds_ &&
                     std::strcmp("__container", layer_name) == 0;
  if (!ignore_clip && !new_clip_rect_.IsEmpty()) {
    non_empty_rect = canvas.ClipRect(new_clip_rect_);
  }

  auto child_alpha =
      parent_alpha;  // TODO(aiyongbiao): drawing with off screen p1
  for (auto it = layers_.rbegin(); it != layers_.rend(); it++) {
    if (non_empty_rect) {
      (*it)->Draw(canvas, parent_matrix, child_alpha);
    }
  }
  canvas.Restore();
}

void CompositionLayer::SetProgress(float progress) {
  BaseLayer::SetProgress(progress);

  if (time_remapping_animation_) {
    auto duration_frames = composition_.GetDurationFrames() + 0.01;
    auto delay_frames = composition_.GetStartFrame();
    auto remapped_frames = time_remapping_animation_->GetValue().Get() *
                               composition_.GetFrameRate() -
                           delay_frames;
    progress = remapped_frames / duration_frames;
  }

  if (time_remapping_animation_ == nullptr) {
    progress -= layer_model_->GetStartProgress();
  }

  if (layer_model_->GetTimeStretch() != 0 &&
      layer_model_->GetName() == "__container") {
    progress /= layer_model_->GetTimeStretch();
  }

  for (auto it = layers_.rbegin(); it != layers_.rend(); it++) {
    (*it)->SetProgress(progress);
  }
}

void CompositionLayer::GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                                 bool apply_parent) {
  BaseLayer::GetBounds(out_bounds, parent_matrix, apply_parent);
  for (auto it = layers_.rbegin(); it != layers_.rend(); it++) {
    rect_.Set(0, 0, 0, 0);
    (*it)->GetBounds(rect_, *bounds_matrix_, true);
    out_bounds.Union(rect_);
  }
}

}  // namespace animax
}  // namespace lynx
