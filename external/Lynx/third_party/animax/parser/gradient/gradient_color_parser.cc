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

#include "animax/parser/gradient/gradient_color_parser.h"

#include <vector>

#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

GradientColorModel GradientColorParser::Parse(rapidjson::Value& value,
                                              float scale) {
  std::vector<float> array;
  if (value.IsArray()) {
    const auto& value_array = value.GetArray();
    for (auto array_it = value_array.Begin(); array_it != value_array.End();
         array_it++) {
      array.push_back(array_it->GetFloat());
    }
    if (array.size() == 4 && array[0] == 1.0) {
      array[0] = 0;
      array.push_back(1.0);
      array.push_back(array[1]);
      array.push_back(array[2]);
      array.push_back(array[3]);
      color_points_ = 2;
    }
  }
  if (color_points_ == -1) {
    color_points_ = array.size() / 4;
  }
  auto positions = std::make_unique<float[]>(color_points_);
  auto colors = std::make_unique<int32_t[]>(color_points_);
  int32_t r = 0, g = 0;
  for (auto i = 0; i < color_points_ * 4; i++) {
    auto color_index = i / 4;
    auto color_value = array[i];
    switch (i % 4) {
      case 0: {
        if (color_index > 0 && positions[color_index - 1] >= color_value) {
          positions[color_index] = color_value + 0.01;
        } else {
          positions[color_index] = color_value;
        }
        break;
      }
      case 1:
        r = color_value * 255.0;
        break;
      case 2:
        g = color_value * 255.0;
        break;
      case 3: {
        int32_t b = static_cast<int32_t>(color_value * 255.0);
        colors[color_index] = Color::ToInt(255, r, g, b);
        break;
      }
    }
  }
  auto gradient_color = GradientColorModel::Make(
      std::move(positions), std::move(colors), color_points_);
  // TODO(aiyongbiao): addOpacityStopsToGradientIfNeeded p1
  return gradient_color;
}

}  // namespace animax
}  // namespace lynx
