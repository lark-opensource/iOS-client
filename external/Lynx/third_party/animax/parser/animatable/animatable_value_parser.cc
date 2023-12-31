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

#include "animax/parser/animatable/animatable_value_parser.h"

#include <memory>

#include "animax/parser/gradient/gradient_color_parser.h"
#include "animax/parser/keyframe/basic_value_parser.h"
#include "animax/parser/shape/shape_data_parser.h"
#include "animax/parser/text/document_data_parser.h"

namespace lynx {
namespace animax {

std::unique_ptr<AnimatableShapeValue> AnimatableValueParser::ParseShapeData(
    rapidjson::Value& value, CompositionModel& composition) {
  auto shape_value = std::make_unique<AnimatableShapeValue>();
  Parse(value, composition, ShapeDataParser::Instance(), composition.GetScale(),
        shape_value->GetKeyframes());
  return shape_value;
}

std::unique_ptr<AnimatableFloatValue> AnimatableValueParser::ParseFloat(
    rapidjson::Value& value, CompositionModel& composition) {
  return ParseFloat(value, composition, true);
}

std::unique_ptr<AnimatableFloatValue> AnimatableValueParser::ParseFloat(
    rapidjson::Value& value, CompositionModel& composition, bool is_dp) {
  auto anim_value = std::make_unique<AnimatableFloatValue>();
  auto scale = is_dp ? composition.GetScale() : 1;
  Parse(value, composition, FloatValueParser::Instance(), scale,
        anim_value->GetKeyframes());
  return anim_value;
}

std::unique_ptr<AnimatableIntegerValue> AnimatableValueParser::ParseInteger(
    rapidjson::Value& value, CompositionModel& composition) {
  auto anim_value = std::make_unique<AnimatableIntegerValue>();
  Parse(value, composition, IntegerValueParser::Instance(),
        anim_value->GetKeyframes());
  return anim_value;
}

std::unique_ptr<AnimatablePointValue> AnimatableValueParser::ParsePoint(
    rapidjson::Value& value, CompositionModel& composition) {
  auto anim_value = std::make_unique<AnimatablePointValue>();
  Parse(value, composition, PointValueParser::Instance(),
        composition.GetScale(), anim_value->GetKeyframes());
  return anim_value;
}

std::unique_ptr<AnimatableScaleValue> AnimatableValueParser::ParseScale(
    rapidjson::Value& value, CompositionModel& composition) {
  auto anim_value = std::make_unique<AnimatableScaleValue>();
  Parse(value, composition, ScaleValueParser::Instance(),
        anim_value->GetKeyframes());
  return anim_value;
}

std::unique_ptr<AnimatableColorValue> AnimatableValueParser::ParseColor(
    rapidjson::Value& value, CompositionModel& composition) {
  auto anim_value = std::make_unique<AnimatableColorValue>();
  Parse(value, composition, ColorValueParser::Instance(),
        anim_value->GetKeyframes());
  return anim_value;
}

std::unique_ptr<AnimatableTextFrame> AnimatableValueParser::ParseDocumentData(
    rapidjson::Value& value, CompositionModel& composition) {
  auto anim_value = std::make_unique<AnimatableTextFrame>();
  Parse(value, composition, DocumentDataParser::Instance(),
        composition.GetScale(), anim_value->GetKeyframes());
  return anim_value;
}

std::unique_ptr<AnimatableGradientColorValue>
AnimatableValueParser::ParseGradientColor(rapidjson::Value& value,
                                          CompositionModel& composition,
                                          int32_t points) {
  auto anim_value = std::make_unique<AnimatableGradientColorValue>();
  auto parser = GradientColorParser(points);
  Parse(value, composition, parser, anim_value->GetKeyframes());
  return anim_value;
}

}  // namespace animax
}  // namespace lynx
