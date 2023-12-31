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

#ifndef ANIMAX_LAYER_SOLID_LAYER_H_
#define ANIMAX_LAYER_SOLID_LAYER_H_

#include "animax/layer/base_layer.h"
#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

class SolidLayer : public BaseLayer {
 public:
  SolidLayer(std::shared_ptr<LayerModel>& layer, CompositionModel& composition);

  void Init() override;
  void DrawLayer(Canvas& canvas, Matrix& matrix, int32_t alpha) override;
  void GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                 bool apply_parent) override;

 private:
  RectF rect_;
  std::unique_ptr<Paint> paint_;
  std::unique_ptr<Path> path_;

  float points_[8];
  std::shared_ptr<BaseKeyframeAnimation<std::shared_ptr<ColorFilter>,
                                        std::shared_ptr<ColorFilter>>>
      color_filter_animation_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_LAYER_SOLID_LAYER_H_
