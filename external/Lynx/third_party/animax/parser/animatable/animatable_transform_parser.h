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

#ifndef ANIMAX_PARSER_ANIMATABLE_ANIMATABLE_TRANSFORM_PARSER_H_
#define ANIMAX_PARSER_ANIMATABLE_ANIMATABLE_TRANSFORM_PARSER_H_

#include <memory>

#include "animax/model/animatable/animatable_transform_model.h"
#include "animax/model/composition_model.h"
#include "animax/parser/base_parser.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace animax {

class AnimatableTransformParser : public BaseParser<AnimatableTransformParser> {
 public:
  std::shared_ptr<AnimatableTransformModel> Parse(
      rapidjson::Value& value, CompositionModel& composition);

 private:
  bool IsAnchorPointIdentity(AnimatablePathValue* anchor);
  bool IsPositionIdentity(BasePointFAnimatableValue* position);
  bool IsFloatValueIdentity(AnimatableFloatValue* float_value);
  bool IsScaleIdentity(AnimatableScaleValue* scale);
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_PARSER_ANIMATABLE_ANIMATABLE_TRANSFORM_PARSER_H_
