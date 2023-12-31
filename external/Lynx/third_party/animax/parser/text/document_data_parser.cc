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

#include "animax/parser/text/document_data_parser.h"

#include <memory>
#include <string>

#include "animax/parser/keyframe/json_parser.h"

namespace lynx {
namespace animax {

DocumentDataModel DocumentDataParser::Parse(rapidjson::Value& value,
                                            float scale) {
  std::string text;
  std::string font_name;
  float size = 0;
  DocumentJustification justification = DocumentJustification::kCenter;
  int32_t tracking = 0;
  float line_height = 0;
  float baseline_shift = 0;
  int32_t fill_color = 0;
  int32_t stroke_color = 0;
  float stroke_width = 0;
  bool stroke_overfill = true;
  PointF box_position = PointF::MakeEmpty();
  PointF box_size = PointF::MakeEmpty();

  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& key = it->name.GetString();
    if (strcmp(key, "t") == 0) {
      text = it->value.GetString();
    } else if (strcmp(key, "f") == 0) {
      font_name = it->value.GetString();
    } else if (strcmp(key, "s") == 0) {
      size = it->value.GetFloat();
    } else if (strcmp(key, "j") == 0) {
      auto justification_int = it->value.GetInt();
      if (justification_int >
              static_cast<int32_t>(DocumentJustification::kCenter) ||
          justification_int < 0) {
        justification = DocumentJustification::kCenter;
      } else {
        justification = static_cast<DocumentJustification>(justification_int);
      }
    } else if (strcmp(key, "tr") == 0) {
      tracking = it->value.GetInt();
    } else if (strcmp(key, "lh") == 0) {
      line_height = it->value.GetFloat();
    } else if (strcmp(key, "ls") == 0) {
      baseline_shift = it->value.GetFloat();
    } else if (strcmp(key, "fc") == 0) {
      fill_color = JsonParser::Instance().JsonToColor(it->value);
    } else if (strcmp(key, "sc") == 0) {
      stroke_color = JsonParser::Instance().JsonToColor(it->value);
    } else if (strcmp(key, "sw") == 0) {
      stroke_width = it->value.GetFloat();
    } else if (strcmp(key, "of") == 0) {
      stroke_overfill = it->value.GetBool();
    } else if (strcmp(key, "ps") == 0) {
      box_position = JsonParser::Instance().JsonToPoint(it->value, scale);
    } else if (strcmp(key, "sz") == 0) {
      box_size = JsonParser::Instance().JsonToPoint(it->value, scale);
    }
  }
  return DocumentDataModel(
      std::move(text), std::move(font_name), size, justification, tracking,
      line_height, baseline_shift, fill_color, stroke_color, stroke_width,
      stroke_overfill, std::move(box_position), std::move(box_size));
}

}  // namespace animax
}  // namespace lynx
