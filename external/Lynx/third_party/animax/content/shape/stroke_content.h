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

#ifndef ANIMAX_CONTENT_SHAPE_STROKE_CONTENT_H_
#define ANIMAX_CONTENT_SHAPE_STROKE_CONTENT_H_

#include "animax/content/shape/base_stroke_content.h"
#include "animax/layer/base_layer.h"

namespace lynx {
namespace animax {

class ShapeStrokeModel;

class StrokeContent : public BaseStrokeContent {
 public:
  StrokeContent(BaseLayer& layer, ShapeStrokeModel& model);

  void Init() override;
  void Draw(Canvas& canvas, Matrix& parent_matrix,
            int32_t parent_alpha) override;
  // TODO(aiyongbiao): add value callback p1
 private:
  BaseLayer& layer_;

  std::unique_ptr<BaseColorKeyframeAnimation> color_animation_;
  std::shared_ptr<BaseKeyframeAnimation<std::shared_ptr<ColorFilter>,
                                        std::shared_ptr<ColorFilter>>>
      color_filter_animation_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_CONTENT_SHAPE_STROKE_CONTENT_H_
