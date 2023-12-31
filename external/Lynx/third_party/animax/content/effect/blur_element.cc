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

#include "animax/content/effect/blur_element.h"

#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

BlurElement::BlurElement(BaseLayer& layer) {
  blur_animation_ = layer.GetBlurEffect()->GetBlurriness()->CreateAnimation();
  layer.AddAnimation(blur_animation_.get());
}

void BlurElement::Init() {
  if (blur_animation_) {
    blur_animation_->AddUpdateListener(this);
  }
}

void BlurElement::Draw(Paint& paint, BaseLayer& layer, bool create_directly) {
  if (blur_animation_) {
    auto blur_radius = blur_animation_->GetValue().Get();
    if (blur_radius == 0) {
      paint.SetMaskFilter(nullptr);
    } else if (blur_radius != blur_mask_filter_radius_) {
      if (create_directly) {
        auto blur = Context::MakeBlurFilter(blur_radius);
        paint.SetMaskFilter(blur.get());
      } else {
        paint.SetMaskFilter(layer.GetBlurMaskFilter(blur_radius));
      }
    }
    blur_mask_filter_radius_ = blur_radius;
  }
}

float BlurElement::GetBlurRadius() {
  if (blur_animation_) {
    return blur_animation_->GetValue().Get();
  } else {
    return blur_mask_filter_radius_;
  }
}

}  // namespace animax
}  // namespace lynx
