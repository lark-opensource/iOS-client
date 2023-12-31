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

#include "animax/parser/shape/shape_data_parser.h"

#include <vector>

#include "animax/model/basic_model.h"
#include "animax/model/shape/shape_data_model.h"
#include "animax/parser/keyframe/json_parser.h"

namespace lynx {
namespace animax {

ShapeDataModel ShapeDataParser::Parse(rapidjson::Value& value, float scale) {
  rapidjson::Value object;
  if (value.IsArray()) {
    object = value.GetArray().Begin()->GetObject();
  } else {
    object = value.GetObject();
  }

  bool closed;
  std::vector<PointF> points_array;
  std::vector<PointF> in_tangents;
  std::vector<PointF> out_tangents;
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    auto key = it->name.GetString();
    if (strcmp(key, "c") == 0) {
      closed = it->value.GetBool();
    } else if (strcmp(key, "v") == 0) {
      JsonParser::Instance().JsonToPoints(it->value, scale, points_array);
    } else if (strcmp(key, "i") == 0) {
      JsonParser::Instance().JsonToPoints(it->value, scale, in_tangents);
    } else if (strcmp(key, "o") == 0) {
      JsonParser::Instance().JsonToPoints(it->value, scale, out_tangents);
    }
  }

  auto shape_model = ShapeDataModel::MakeEmpty();
  if (points_array.empty()) {
    return shape_model;
  }

  auto& curves = shape_model.GetCurves();
  int32_t length = points_array.size();
  auto& initial_point = points_array[0];
  for (auto i = 1; i < length; i++) {
    auto& vertex = points_array[i];
    auto& previous_vertex = points_array[i - 1];
    auto& cp1 = out_tangents[i - 1];
    auto& cp2 = in_tangents[i];
    curves.emplace_back(
        CubicCurveModel(JsonParser::Instance().AddPoints(previous_vertex, cp1),
                        JsonParser::Instance().AddPoints(vertex, cp2), vertex));
  }

  if (closed) {
    auto& vertex = points_array[0];
    auto& previous_vertex = points_array[length - 1];
    auto& cp1 = out_tangents[length - 1];
    auto& cp2 = in_tangents[0];
    curves.emplace_back(
        CubicCurveModel(JsonParser::Instance().AddPoints(previous_vertex, cp1),
                        JsonParser::Instance().AddPoints(vertex, cp2), vertex));
  }

  shape_model.Init(initial_point, closed);
  return shape_model;
}

}  // namespace animax
}  // namespace lynx
