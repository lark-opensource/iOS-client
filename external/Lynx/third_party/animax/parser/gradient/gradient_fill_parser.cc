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

#include "animax/parser/gradient/gradient_fill_parser.h"

#include <string>

#include "animax/parser/animatable/animatable_value_parser.h"

namespace lynx {
namespace animax {

std::shared_ptr<GradientFillModel> GradientFillParser::Parse(
    rapidjson::Value& value, CompositionModel& composition) {
  std::string model_name;
  std::unique_ptr<AnimatableGradientColorValue> color;
  std::unique_ptr<AnimatableIntegerValue> opacity;
  GradientType gradient_type;
  std::unique_ptr<AnimatablePointValue> start_point;
  std::unique_ptr<AnimatablePointValue> end_point;
  PathFillType fill_type = PathFillType::kWinding;
  bool hidden = false;

  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& name = it->name.GetString();
    if (strcmp(name, "nm") == 0) {
      model_name = it->value.GetString();
    } else if (strcmp(name, "g") == 0) {
      auto points = -1;
      const auto& point_object = it->value.GetObject();
      for (auto point_it = point_object.MemberBegin();
           point_it != point_object.MemberEnd(); point_it++) {
        const auto& point_name = point_it->name.GetString();
        if (strcmp(point_name, "p") == 0) {
          points = point_it->value.GetInt();
        } else if (strcmp(point_name, "k") == 0) {
          color = AnimatableValueParser::Instance().ParseGradientColor(
              point_it->value, composition, points);
        }
      }
    } else if (strcmp(name, "o") == 0) {
      opacity = AnimatableValueParser::Instance().ParseInteger(it->value,
                                                               composition);
    } else if (strcmp(name, "t") == 0) {
      gradient_type = it->value.GetInt() == 1 ? GradientType::kLinear
                                              : GradientType::kRadial;
    } else if (strcmp(name, "s") == 0) {
      start_point =
          AnimatableValueParser::Instance().ParsePoint(it->value, composition);
    } else if (strcmp(name, "e") == 0) {
      end_point =
          AnimatableValueParser::Instance().ParsePoint(it->value, composition);
    } else if (strcmp(name, "r") == 0) {
      fill_type = it->value.GetInt() == 1 ? PathFillType::kWinding
                                          : PathFillType::kEvenOdd;
    } else if (strcmp(name, "hd") == 0) {
      hidden = it->value.GetBool();
    }
  }
  // TODO(aiyongbiao): opacity p1
  return std::make_shared<GradientFillModel>(
      gradient_type, fill_type, std::move(color), std::move(opacity),
      std::move(start_point), std::move(end_point), std::move(model_name),
      nullptr, nullptr, hidden);
}

}  // namespace animax
}  // namespace lynx
