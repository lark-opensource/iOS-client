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

#include "animax/parser/mask_parser.h"

#include "animax/parser/animatable/animatable_value_parser.h"

namespace lynx {
namespace animax {

std::unique_ptr<MaskModel> MaskParser::Parse(rapidjson::Value& value,
                                             CompositionModel& composition) {
  MaskMode mask_mode;
  std::unique_ptr<AnimatableShapeValue> mask_path;
  std::unique_ptr<AnimatableIntegerValue> opacity;
  bool inverted = false;

  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& name =
        it->name.GetString();  // TODO(aiyongbiao): may not correct p0
    if (strcmp(name, "mode") == 0) {
      const auto& mode_name = it->value.GetString();
      if (strcmp(mode_name, "a") == 0) {
        mask_mode = MaskMode::kAdd;
      } else if (strcmp(mode_name, "s") == 0) {
        mask_mode = MaskMode::kSubtract;
      } else if (strcmp(mode_name, "n") == 0) {
        mask_mode = MaskMode::kNone;
      } else if (strcmp(mode_name, "i") == 0) {
        // TODO(aiyongbiao): intersect not support, temp treat as add
        mask_mode = MaskMode::kAdd;
      } else {
        mask_mode = MaskMode::kAdd;
      }
    } else if (strcmp(name, "pt") == 0) {
      mask_path = AnimatableValueParser::Instance().ParseShapeData(it->value,
                                                                   composition);
    } else if (strcmp(name, "o") == 0) {
      opacity = AnimatableValueParser::Instance().ParseInteger(it->value,
                                                               composition);
    } else if (strcmp(name, "inv") == 0) {
      inverted = it->value.GetBool();
    }
  }

  return std::make_unique<MaskModel>(mask_mode, std::move(mask_path),
                                     std::move(opacity), inverted);
}

}  // namespace animax
}  // namespace lynx
