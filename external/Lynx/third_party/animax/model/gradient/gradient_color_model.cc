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

#include "animax/model/gradient/gradient_color_model.h"

namespace lynx {
namespace animax {

GradientColorModel::GradientColorModel(const GradientColorModel& rhs) {
  Copy(rhs);
}

GradientColorModel& GradientColorModel::operator=(
    const GradientColorModel& rhs) {
  Copy(rhs);
  return *this;
}

void GradientColorModel::LerpColor(GradientColorModel& gc1,
                                   GradientColorModel& gc2, float progress) {
  if (gc1.size_ != gc2.size_) {
    ANIMAX_LOGE("gradient color size not same.");
  }
  for (auto i = 0; i < gc1.size_; i++) {
    positions_[i] = Lerp(gc1.positions_[i], gc2.positions_[i], progress);
    colors_[i] = GammaEvaluate(gc1.colors_[i], gc2.colors_[i], progress);
  }
}

void GradientColorModel::Init(int32_t size) {
  if (size == size_ && positions_ && colors_) {
    return;
  }

  size_ = size;
  if (IsEmpty()) {
    return;
  }
  positions_ = std::make_unique<float[]>(size);
  colors_ = std::make_unique<int32_t[]>(size);
}

void GradientColorModel::Copy(const GradientColorModel& rhs) {
  if (rhs.IsEmpty()) {
    size_ = Float::Min();
    return;
  }
  Init(rhs.size_);
  std::copy(rhs.positions_.get(), rhs.positions_.get() + size_,
            positions_.get());
  std::copy(rhs.colors_.get(), rhs.colors_.get() + size_, colors_.get());
}

}  // namespace animax
}  // namespace lynx
