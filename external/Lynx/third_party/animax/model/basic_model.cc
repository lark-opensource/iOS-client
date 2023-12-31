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

#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

Color Color::ParseColor(std::string& color) {
  if (color[0] == '#') {
    color.erase(0, 1);
  }

  if (color.length() == 6) {
    color = "ff" + color;
  }

  auto split_length = 2;
  auto num_sub_color = color.length() / split_length;

  int32_t a = 255, r = 0, g = 0, b = 0;
  for (int i = 0; i < num_sub_color; i++) {
    auto sub_color = color.substr(i * split_length, split_length);
    auto value = stoi(sub_color, nullptr, 16);
    switch (i) {
      case 0:
        a = value;
        break;
      case 1:
        r = value;
        break;
      case 2:
        g = value;
        break;
      case 3:
        b = value;
        break;
      default:
        break;
    }
  }
  return Color::Make(a, r, g, b);
}

}  // namespace animax
}  // namespace lynx
