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

#ifndef ANIMAX_LAYER_COMPOSITION_LAYER_H_
#define ANIMAX_LAYER_COMPOSITION_LAYER_H_

#include <memory>
#include <vector>

#include "animax/layer/base_layer.h"
#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

class CompositionModel;
class LayerModel;

class CompositionLayer : public BaseLayer,
                         public std::enable_shared_from_this<CompositionLayer> {
 public:
  CompositionLayer(std::shared_ptr<LayerModel>& layer_model,
                   CompositionModel& composition);
  ~CompositionLayer() override = default;

  void Init() override;

  void DrawLayer(Canvas& canvas, Matrix& matrix, int32_t alpha) override;

  void SetProgress(float progress) override;

  void SetLayerModels(const std::shared_ptr<LayerModelList>& layers) {
    layer_models_ = layers;
  }

  void GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                 bool apply_parent) override;

 private:
  std::vector<std::unique_ptr<BaseLayer>> layers_;
  std::shared_ptr<LayerModelList> layer_models_;

  RectF rect_;
  RectF new_clip_rect_;
  std::unique_ptr<Paint> layer_paint_;

  std::unique_ptr<BaseFloatKeyframeAnimation> time_remapping_animation_;

  bool has_matte_ = false;
  bool has_masks_ = false;
  bool clip_to_composition_bounds_ = true;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_LAYER_COMPOSITION_LAYER_H_
