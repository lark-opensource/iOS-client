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

#ifndef ANIMAX_PARSER_KEYFRAME_JSON_PARSER_H_
#define ANIMAX_PARSER_KEYFRAME_JSON_PARSER_H_

#include <vector>

#include "animax/model/basic_model.h"
#include "animax/parser/base_parser.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace animax {

class JsonParser : public BaseParser<JsonParser> {
 public:
  void JsonToPoints(rapidjson::Value& value, float scale,
                    std::vector<PointF>& points);
  PointF JsonToPoint(rapidjson::Value& value, float scale);
  const PointF AddPoints(const PointF& point1, const PointF& point2);
  float ValueFromObject(rapidjson::Value& value);
  int32_t JsonToColor(rapidjson::Value& value);

 private:
  PointF JsonNumbersToPoint(rapidjson::Value& value, float scale);
  PointF JsonArrayToPoint(rapidjson::Value& value, float scale);
  PointF JsonObjectToPoint(rapidjson::Value& value, float scale);
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_PARSER_KEYFRAME_JSON_PARSER_H_
