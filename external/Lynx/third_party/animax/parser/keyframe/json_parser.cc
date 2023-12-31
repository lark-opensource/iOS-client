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

#include "animax/parser/keyframe/json_parser.h"

#include "animax/base/log.h"
#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

void JsonParser::JsonToPoints(rapidjson::Value& value, float scale,
                              std::vector<PointF>& points) {
  const auto& array = value.GetArray();
  if ((array.Size() == 2 || array.Size() == 3) && array[0].IsNumber()) {
    auto point = JsonToPoint(value, scale);
    if (!point.IsEmpty()) {
      points.push_back(point);
    }
  } else {
    for (auto it = array.Begin(); it != array.End(); it++) {
      auto point = JsonToPoint(it->Move(), scale);
      if (!point.IsEmpty()) {
        points.push_back(point);
      }
    }
  }
}

PointF JsonParser::JsonToPoint(rapidjson::Value& value, float scale) {
  if (value.IsNumber()) {
    return JsonNumbersToPoint(value, scale);
  } else if (value.IsArray()) {
    return JsonArrayToPoint(value, scale);
  } else if (value.IsObject()) {
    return JsonObjectToPoint(value, scale);
  } else {
    ANIMAX_LOGI("unknown points");
  }
  return PointF::MakeEmpty();
}

PointF JsonParser::JsonNumbersToPoint(rapidjson::Value& value, float scale) {
  // TODO(aiyongbiao): tmp impl p1
  ANIMAX_LOGI("JsonNumbersToPoint should not be here, pls check!");
  auto v = value.GetFloat();
  return PointF::Make(v * scale, v * scale);
}

PointF JsonParser::JsonArrayToPoint(rapidjson::Value& value, float scale) {
  auto it = value.GetArray().Begin();

  float x = it->GetFloat();
  it += 1;
  float y = it->GetFloat();

  return PointF::Make(x * scale, y * scale);
}

PointF JsonParser::JsonObjectToPoint(rapidjson::Value& value, float scale) {
  const auto& object = value.GetObject();
  float x = 0, y = 0;
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& key = it->name.GetString();
    if (strcmp(key, "x") == 0) {
      x = ValueFromObject(it->value);
    } else if (strcmp(key, "y") == 0) {
      y = ValueFromObject(it->value);
    }
  }
  return PointF::Make(x * scale, y * scale);
}

float JsonParser::ValueFromObject(rapidjson::Value& value) {
  if (value.IsNumber()) {
    return value.GetFloat();
  } else if (value.IsArray()) {
    if (value.GetArray().Empty()) {
      ANIMAX_LOGI("Point array is empty");
      return 0;
    }
    return value.GetArray().Begin()->GetFloat();
  }
  return 0;
}

int32_t JsonParser::JsonToColor(rapidjson::Value& value) {
  const auto& array = value.GetArray();
  int32_t r = 255, g = 255, b = 255;
  for (auto i = 0; i < array.Size(); i++) {
    auto color_value = array[i].GetFloat() * 255;
    if (i == 0) {
      r = color_value;
    } else if (i == 1) {
      g = color_value;
    } else if (i == 2) {
      b = color_value;
    }
  }
  return Color::ToInt(255, r, g, b);
}

const PointF JsonParser::AddPoints(const PointF& point1, const PointF& point2) {
  return PointF::Make(point1.GetX() + point2.GetX(),
                      point1.GetY() + point2.GetY());
}

}  // namespace animax
}  // namespace lynx
