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

#include "animax/parser/text/font_parser.h"

namespace lynx {
namespace animax {

std::shared_ptr<FontAsset> FontParser::Parse(rapidjson::Value& value,
                                             CompositionModel& composition) {
  std::string family;
  std::string name;
  std::string style;
  std::string path;
  float ascent = 0;

  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& key = it->name.GetString();
    if (strcmp(key, "fFamily") == 0) {
      family = it->value.GetString();
    } else if (strcmp(key, "fName") == 0) {
      name = it->value.GetString();
    } else if (strcmp(key, "fStyle") == 0) {
      style = it->value.GetString();
    } else if (strcmp(key, "ascent") == 0) {
      ascent = it->value.GetFloat();
    } else if (strcmp(key, "fPath") == 0) {
      path = it->value.GetString();
    }
  }

  return std::make_shared<FontAsset>(family, name, style, ascent, path);
}

}  // namespace animax
}  // namespace lynx
