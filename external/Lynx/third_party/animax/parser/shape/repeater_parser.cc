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

#include "animax/parser/shape/repeater_parser.h"

#include <string>

#include "animax/model/animatable/animatable_transform_model.h"
#include "animax/model/animatable/basic_animatable_value.h"
#include "animax/parser/animatable/animatable_transform_parser.h"
#include "animax/parser/animatable/animatable_value_parser.h"

namespace lynx {
namespace animax {

std::shared_ptr<RepeaterModel> RepeaterParser::Parse(
    rapidjson::Value& value, CompositionModel& composition) {
  std::string name;
  std::unique_ptr<AnimatableFloatValue> copies;
  std::unique_ptr<AnimatableFloatValue> offset;
  std::shared_ptr<AnimatableTransformModel> transform;
  bool hidden = false;

  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& key = it->name.GetString();
    if (strcmp(key, "nm") == 0) {
      name = it->value.GetString();
    } else if (strcmp(key, "c") == 0) {
      copies = AnimatableValueParser::Instance().ParseFloat(it->value,
                                                            composition, false);
    } else if (strcmp(key, "o") == 0) {
      offset = AnimatableValueParser::Instance().ParseFloat(it->value,
                                                            composition, false);
    } else if (strcmp(key, "tr") == 0) {
      transform =
          AnimatableTransformParser::Instance().Parse(it->value, composition);
    } else if (strcmp(key, "hd") == 0) {
      hidden = it->value.GetBool();
    }
  }

  return std::make_shared<RepeaterModel>(std::move(name), std::move(copies),
                                         std::move(offset),
                                         std::move(transform), hidden);
}

}  // namespace animax
}  // namespace lynx
