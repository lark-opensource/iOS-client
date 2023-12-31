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

#include "animax/model/composition_model.h"

#include "animax/model/layer_model.h"

namespace lynx {
namespace animax {

CompositionModel::CompositionModel(float scale) : scale_(scale) {}

void CompositionModel::Init(std::unique_ptr<Rect> bounds, float start_frame,
                            float end_frame, float frame_rate) {
  bounds_ = std::move(bounds);
  start_frame_ = start_frame;
  end_frame_ = end_frame;
  frame_rate_ = frame_rate;
}

long CompositionModel::GetDuration() {
  auto duration = (end_frame_ - start_frame_) / frame_rate_ * 1000;
  return duration < 0 ? 0 : duration;
}

void CompositionModel::SetHashDashPattern(bool has_dash_patern) {
  has_dash_pattern_ = has_dash_patern;
}

void CompositionModel::IncrementMatteOrMaskCount(int32_t count) {
  mask_and_matte_count_ += count;
}

std::shared_ptr<MarkerModel> CompositionModel::GetMarker(
    const std::string& marker_name) {
  for (auto& marker : markers_) {
    if (marker->MatchesName(marker_name)) {
      return marker;
    }
  }
  return nullptr;
}

bool CompositionModel::UseTextGlyphs() {
  bool has_font_asset = false;
  for (auto& font : fonts_) {
    if (font.second->GetFont()) {
      has_font_asset = true;
      break;
    }
  }
  return !has_font_asset && !characters_.empty();
}

}  // namespace animax
}  // namespace lynx
