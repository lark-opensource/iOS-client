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

#ifndef ANIMAX_PARSER_KEYFRAME_KEYFRAMES_PARSER_H_
#define ANIMAX_PARSER_KEYFRAME_KEYFRAMES_PARSER_H_

#include <memory>
#include <vector>

#include "animax/base/log.h"
#include "animax/model/composition_model.h"
#include "animax/model/keyframe/keyframe_model.h"
#include "animax/model/keyframe/path_keyframe_model.h"
#include "animax/parser/base_parser.h"
#include "animax/parser/keyframe/keyframe_parser.h"
#include "animax/parser/value_parser.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace animax {

class KeyframesParser : public BaseParser<KeyframesParser> {
 public:
  template <typename T>
  void Parse(rapidjson::Value& value, CompositionModel& composition,
             ValueParser<T>& value_parser, bool multi_dimen, float scale,
             std::vector<std::unique_ptr<KeyframeModel<T>>>& keyframes) {
    const auto& object = value.GetObject();
    for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
      if (strcmp(it->name.GetString(), "k") == 0) {
        if (it->value.IsArray()) {
          const auto& value_array = it->value.GetArray();
          if (value_array.Empty()) {
            ANIMAX_LOGI("KeyframesParser array is empty");
            break;
          }

          if (value_array.Begin()->IsNumber()) {
            keyframes.emplace_back(KeyframeParser::Instance().Parse(
                it->value, composition, scale, value_parser, false,
                multi_dimen));
          } else {
            for (auto array_it = value_array.Begin();
                 array_it != value_array.End(); array_it++) {
              keyframes.emplace_back(KeyframeParser::Instance().Parse(
                  array_it->Move(), composition, scale, value_parser, true,
                  multi_dimen));
            }
          }
        } else {
          keyframes.emplace_back(KeyframeParser::Instance().Parse(
              it->value, composition, scale, value_parser, false, multi_dimen));
        }
      }
    }

    SetEndFrames(keyframes);
  }

  template <typename T>
  void SetEndFrames(std::vector<std::unique_ptr<KeyframeModel<T>>>& frames) {
    auto size = frames.size();
    if (size == 0) {
      return;
    }

    for (auto i = 0; i < size - 1; i++) {
      auto& keyframe = frames[i];
      auto& next_keyframe = frames[i + 1];
      keyframe->SetEndFrame(next_keyframe->GetStartFrame());
      if (keyframe->IsEndValueEmpty() && !next_keyframe->IsStartValueEmpty()) {
        keyframe->SetEndValue(next_keyframe->GetStartValue());
        if (keyframe->GetType() == KeyframeType::kPath) {
          keyframe->CreatePath();
        }
      }
    }

    auto& last_frame = frames[size - 1];
    if ((last_frame->IsStartValueEmpty() || last_frame->IsEndValueEmpty()) &&
        size > 1) {
      frames.pop_back();
    }
  }
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_PARSER_KEYFRAME_KEYFRAMES_PARSER_H_
