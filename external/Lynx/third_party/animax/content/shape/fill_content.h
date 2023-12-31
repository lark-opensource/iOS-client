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

#ifndef ANIMAX_CONTENT_SHAPE_FILL_CONTENT_H_
#define ANIMAX_CONTENT_SHAPE_FILL_CONTENT_H_

#include "animax/animation/keyframe_animation.h"
#include "animax/content/effect/blur_element.h"
#include "animax/content/effect/drop_shadow_element.h"
#include "animax/layer/base_layer.h"
#include "animax/render/include/color_filter.h"
#include "animax/render/include/paint.h"
#include "animax/render/include/path.h"

namespace lynx {
namespace animax {

class ShapeFillModel;

class FillContent : public Content, public AnimationListener {
 public:
  FillContent(BaseLayer& layer, ShapeFillModel& fill,
              CompositionModel& composition);
  ~FillContent() override = default;

  void Init() override;

  void OnValueChanged() override;

  void Draw(Canvas& canvas, Matrix& parent_matrix,
            int32_t parent_alpha) override;
  void GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                 bool apply_parent) override;

  void SetContents(std::vector<Content*>& contents_before,
                   std::vector<Content*>& contents_after) override;

  bool SubDrawingType() override { return true; }

 private:
  BaseLayer& layer_;

  std::unique_ptr<Path> path_;
  std::unique_ptr<Paint> paint_;

  std::vector<Content*> paths_;

  std::unique_ptr<BaseColorKeyframeAnimation> color_animation_;
  std::unique_ptr<BaseIntegerKeyframeAnimation> opacity_animation_;
  std::shared_ptr<BaseKeyframeAnimation<std::shared_ptr<ColorFilter>,
                                        std::shared_ptr<ColorFilter>>>
      color_filter_animation_;

  std::unique_ptr<BlurElement> blur_element_;
  std::unique_ptr<DropShadowElement> drop_shadow_element_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_CONTENT_SHAPE_FILL_CONTENT_H_
