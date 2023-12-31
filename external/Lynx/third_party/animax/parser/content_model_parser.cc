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

#include "animax/parser/content_model_parser.h"

#include "animax/base/log.h"
#include "animax/parser/animatable/animatable_transform_parser.h"
#include "animax/parser/gradient/gradient_fill_parser.h"
#include "animax/parser/gradient/gradient_stroke_parser.h"
#include "animax/parser/path/merge_paths_parser.h"
#include "animax/parser/path/shape_trim_path_parser.h"
#include "animax/parser/shape/circle_shape_parser.h"
#include "animax/parser/shape/polystar_shape_parser.h"
#include "animax/parser/shape/rectangle_shape_parser.h"
#include "animax/parser/shape/repeater_parser.h"
#include "animax/parser/shape/rounded_corners_parser.h"
#include "animax/parser/shape/shape_fill_parser.h"
#include "animax/parser/shape/shape_group_parser.h"
#include "animax/parser/shape/shape_path_parser.h"
#include "animax/parser/shape/shape_stroke_parser.h"

namespace lynx {
namespace animax {

std::shared_ptr<ContentModel> ContentModelParser::Parse(
    rapidjson::Value& value, CompositionModel& composition) {
  std::string type;
  int32_t d = 2;

  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& key = it->name.GetString();
    if (strcmp(key, "ty") == 0) {
      type = it->value.GetString();
    } else if (strcmp(key, "d") == 0) {
      if (it->value.IsNumber()) {
        d = it->value.GetInt();
      }
    }
  }

  if (type.empty()) {
    ANIMAX_LOGI("type is null");
    return nullptr;
  }

  char* type_name = type.data();
  if (strcmp(type_name, "gr") == 0) {
    return ShapeGroupParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "st") == 0) {
    return ShapeStrokeParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "gs") == 0) {
    return GradientStrokeParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "fl") == 0) {
    return ShapeFillParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "gf") == 0) {
    return GradientFillParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "tr") == 0) {
    return AnimatableTransformParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "sh") == 0) {
    return ShapePathParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "el") == 0) {
    return CircleShapeParser::Instance().Parse(value, composition, d);
  } else if (strcmp(type_name, "rc") == 0) {
    return RectangleShapeParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "tm") == 0) {
    return ShapeTrimPathParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "sr") == 0) {
    return PolystarShapeParser::Instance().Parse(value, composition, d);
  } else if (strcmp(type_name, "mm") == 0) {
    return MergePathsParser::Instance().Parse(value);
  } else if (strcmp(type_name, "rp") == 0) {
    return RepeaterParser::Instance().Parse(value, composition);
  } else if (strcmp(type_name, "rd") == 0) {
    return RoundedCornersParser::Instance().Parse(value, composition);
  } else {
    ANIMAX_LOGI("no valid type:") << type;
  }

  return nullptr;
}

}  // namespace animax
}  // namespace lynx
