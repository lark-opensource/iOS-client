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

#include "animax/parser/shape/rectangle_shape_parser.h"

#include <string>

#include "animax/model/animatable/basic_animatable_value.h"
#include "animax/parser/animatable/animatable_path_value_parser.h"
#include "animax/parser/animatable/animatable_value_parser.h"

namespace lynx {
namespace animax {

std::shared_ptr<RectangleShapeModel> RectangleShapeParser::Parse(
    rapidjson::Value& value, CompositionModel& composition) {
  std::string name;
  std::unique_ptr<BasePointFAnimatableValue> position;
  std::unique_ptr<AnimatablePointValue> size;
  std::unique_ptr<AnimatableFloatValue> roundedness;
  bool hidden = false;

  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& key = it->name.GetString();
    if (strcmp(key, "nm") == 0) {
      name = it->value.GetString();
    } else if (strcmp(key, "p") == 0) {
      position = AnimatablePathValueParser::Instance().ParseSplitPath(
          it->value, composition);
    } else if (strcmp(key, "s") == 0) {
      size =
          AnimatableValueParser::Instance().ParsePoint(it->value, composition);
    } else if (strcmp(key, "r") == 0) {
      roundedness =
          AnimatableValueParser::Instance().ParseFloat(it->value, composition);
    } else if (strcmp(key, "nd") == 0) {
      hidden = it->value.GetBool();
    }
  }

  return std::make_shared<RectangleShapeModel>(name, std::move(position),
                                               std::move(size),
                                               std::move(roundedness), hidden);
}

}  // namespace animax
}  // namespace lynx
