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

#ifndef ANIMAX_PARSER_KEYFRAME_BASIC_VALUE_PARSER_H_
#define ANIMAX_PARSER_KEYFRAME_BASIC_VALUE_PARSER_H_

#include "animax/model/basic_model.h"
#include "animax/parser/base_parser.h"
#include "animax/parser/value_parser.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace animax {

class FloatValueParser : public ValueParser<Float>,
                         public BaseParser<FloatValueParser> {
 public:
  Float Parse(rapidjson::Value& value, float scale);
};

class IntegerValueParser : public ValueParser<Integer>,
                           public BaseParser<IntegerValueParser> {
 public:
  Integer Parse(rapidjson::Value& value, float scale);
};

class PointValueParser : public ValueParser<PointF>,
                         public BaseParser<PointValueParser> {
 public:
  PointF Parse(rapidjson::Value& value, float scale);
};

class ScaleValueParser : public ValueParser<ScaleXY>,
                         public BaseParser<ScaleValueParser> {
 public:
  ScaleXY Parse(rapidjson::Value& value, float scale);
};

class ColorValueParser : public ValueParser<Color>,
                         public BaseParser<ColorValueParser> {
 public:
  Color Parse(rapidjson::Value& value, float scale);
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_PARSER_KEYFRAME_BASIC_VALUE_PARSER_H_
