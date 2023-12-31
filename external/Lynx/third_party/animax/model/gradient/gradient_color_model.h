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

#ifndef ANIMAX_MODEL_GRADIENT_GRADIENT_COLOR_MODEL_H_
#define ANIMAX_MODEL_GRADIENT_GRADIENT_COLOR_MODEL_H_

#include <memory>

#include "animax/base/log.h"
#include "animax/base/misc_util.h"
#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

enum class GradientType : uint8_t { kLinear = 0, kRadial };

class GradientColorModel {
 public:
  static GradientColorModel Make(std::unique_ptr<float[]> positions,
                                 std::unique_ptr<int32_t[]> colors,
                                 int32_t size) {
    return GradientColorModel(std::move(positions), std::move(colors), size);
  }
  static GradientColorModel MakeEmpty() {
    return GradientColorModel(Integer::Min());
  }

  GradientColorModel() = default;
  GradientColorModel(int32_t size) { Init(size); };
  GradientColorModel(std::unique_ptr<float[]> positions,
                     std::unique_ptr<int32_t[]> colors, int32_t size)
      : size_(size),
        positions_(std::move(positions)),
        colors_(std::move(colors)) {}

  GradientColorModel(const GradientColorModel& rhs);
  GradientColorModel& operator=(const GradientColorModel& rhs);

  void Init(int32_t size);

  float* GetPositions() const { return positions_.get(); }
  int32_t* GetColors() const { return colors_.get(); }
  int32_t GetSize() const { return size_; }

  void LerpColor(GradientColorModel& gc1, GradientColorModel& gc2,
                 float progress);
  bool IsEmpty() const { return size_ <= 0; }

 private:
  void Copy(const GradientColorModel& rhs);

  int32_t size_;
  std::unique_ptr<float[]> positions_;
  std::unique_ptr<int32_t[]> colors_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_GRADIENT_GRADIENT_COLOR_MODEL_H_
