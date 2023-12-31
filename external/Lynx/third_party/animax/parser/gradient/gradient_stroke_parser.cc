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

#include "animax/parser/gradient/gradient_stroke_parser.h"

#include <memory>
#include <string>

#include "animax/model/animatable/animatable_gradient_color_value.h"
#include "animax/model/shape/shape_stroke_model.h"
#include "animax/parser/animatable/animatable_value_parser.h"

namespace lynx {
namespace animax {

std::shared_ptr<GradientStrokeModel> GradientStrokeParser::Parse(
    rapidjson::Value& value, CompositionModel& composition) {
  std::string model_name;
  std::unique_ptr<AnimatableGradientColorValue> color;
  std::unique_ptr<AnimatableIntegerValue> opacity;
  GradientType gradient_type;
  std::unique_ptr<AnimatablePointValue> start_point;
  std::unique_ptr<AnimatablePointValue> end_point;
  std::unique_ptr<AnimatableFloatValue> width;
  LineCapType cap_type;
  LineJoinType join_type;
  std::shared_ptr<AnimatableFloatValue> offset;
  float miter_limit = 0;
  bool hidden = false;

  auto stroke_model = std::make_shared<GradientStrokeModel>();
  auto& line_dash_pattern = stroke_model->GetDashOffset();

  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& name = it->name.GetString();
    if (strcmp(name, "nm") == 0) {
      model_name = it->value.GetString();
    } else if (strcmp(name, "g") == 0) {
      int32_t points = -1;
      const auto& gradient_object = it->value.GetObject();
      for (auto gradient_it = gradient_object.MemberBegin();
           gradient_it != gradient_object.MemberEnd(); gradient_it++) {
        const auto& gradient_name = gradient_it->name.GetString();
        if (strcmp(gradient_name, "p") == 0) {
          points = gradient_it->value.GetInt();
        } else if (strcmp(gradient_name, "k") == 0) {
          color = AnimatableValueParser::Instance().ParseGradientColor(
              gradient_it->value, composition, points);
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
    } else if (strcmp(name, "w") == 0) {
      width =
          AnimatableValueParser::Instance().ParseFloat(it->value, composition);
    } else if (strcmp(name, "lc") == 0) {
      cap_type = static_cast<LineCapType>(it->value.GetInt() - 1);
    } else if (strcmp(name, "lj") == 0) {
      join_type = static_cast<LineJoinType>(it->value.GetInt() - 1);
    } else if (strcmp(name, "ml") == 0) {
      miter_limit = it->value.GetFloat();
    } else if (strcmp(name, "hd") == 0) {
      hidden = it->value.GetBool();
    } else if (strcmp(name, "d") == 0) {
      std::string n;
      std::shared_ptr<AnimatableFloatValue> val;
      const auto& pattern_object = it->value.GetObject();
      for (auto pattern_it = pattern_object.MemberBegin();
           pattern_it != pattern_object.MemberEnd(); pattern_it++) {
        const auto& pattern_name = pattern_it->name.GetString();
        if (strcmp(pattern_name, "n") == 0) {
          n = pattern_it->value.GetString();
        } else if (strcmp(pattern_name, "v") == 0) {
          val = AnimatableValueParser::Instance().ParseFloat(pattern_it->value,
                                                             composition);
        }
      }

      if (n == "o") {
        offset = val;
      } else if (n == "d" || n == "g") {
        composition.SetHashDashPattern(true);
        line_dash_pattern.push_back(val);
      }

      if (line_dash_pattern.size() == 1) {
        line_dash_pattern.push_back(line_dash_pattern[0]);
      }
    }
  }

  // TODO(aiyongbiao): opacity wr p1

  stroke_model->Init(model_name, gradient_type, std::move(color),
                     std::move(opacity), std::move(start_point),
                     std::move(end_point), std::move(width), cap_type,
                     join_type, miter_limit, offset, hidden);
  return stroke_model;
}

}  // namespace animax
}  // namespace lynx
