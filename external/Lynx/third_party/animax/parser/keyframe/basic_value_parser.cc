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

#include "animax/parser/keyframe/basic_value_parser.h"

#include <cmath>

#include "animax/base/log.h"
#include "animax/parser/keyframe/json_parser.h"

namespace lynx {
namespace animax {
Float FloatValueParser::Parse(rapidjson::Value &value, float scale) {
  auto round = JsonParser::Instance().ValueFromObject(value) * scale;
  return Float::Make(round);
}

Integer IntegerValueParser::Parse(rapidjson::Value &value, float scale) {
  auto round =
      std::round(JsonParser::Instance().ValueFromObject(value) * scale);
  return Integer::Make(static_cast<int32_t>(round));
}

PointF PointValueParser::Parse(rapidjson::Value &value, float scale) {
  if (value.IsArray() || value.IsObject()) {
    return JsonParser::Instance().JsonToPoint(value, scale);
  } else if (value.IsNumber()) {
    // TODO(aiyongbiao): tmp impl p1
    ANIMAX_LOGI("warn, should not go to there basicvalueparser");
    auto v = value.GetFloat();
    return PointF::Make(v * scale, v * scale);
  }
  return PointF::MakeEmpty();
}

ScaleXY ScaleValueParser::Parse(rapidjson::Value &value, float scale) {
  auto it = value.GetArray().Begin();
  auto x = it->GetFloat();
  it += 1;
  auto y = it->GetFloat();
  return ScaleXY::Make(x / 100 * scale, y / 100 * scale);
}

Color ColorValueParser::Parse(rapidjson::Value &value, float scale) {
  const auto &array = value.GetArray();
  auto it = array.Begin();
  float r, g, b, a = 1;
  for (auto index = 0; index < array.Size(); index++) {
    if (index == 0) {
      r = (it + index)->GetFloat();
    } else if (index == 1) {
      g = (it + index)->GetFloat();
    } else if (index == 2) {
      b = (it + index)->GetFloat();
    } else if (index == 3) {
      a = (it + index)->GetFloat();
    }
  }

  if (r <= 1 && g <= 1 && b <= 1) {
    r *= 255;
    g *= 255;
    b *= 255;

    if (a <= 1) {
      a *= 255;
    }
  }

  return Color::Make(static_cast<uint8_t>(a), static_cast<uint8_t>(r),
                     static_cast<uint8_t>(g), static_cast<uint8_t>(b));
}
}  // namespace animax
}  // namespace lynx
