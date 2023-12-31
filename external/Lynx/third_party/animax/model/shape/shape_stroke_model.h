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

#ifndef ANIMAX_MODEL_SHAPE_SHAPE_STROKE_MODEL_H_
#define ANIMAX_MODEL_SHAPE_SHAPE_STROKE_MODEL_H_

#include <string>

#include "Lynx/base/compiler_specific.h"
#include "animax/content/shape/stroke_content.h"
#include "animax/model/animatable/basic_animatable_value.h"
#include "animax/model/content_model.h"
#include "animax/render/include/paint.h"

namespace lynx {
namespace animax {

enum class LineCapType : uint8_t {
  kButt = 0,
  kRound,
  kUnknown,
};

enum class LineJoinType : uint8_t {
  kMiter = 0,
  kRound,
  kBevel,
};

static ALLOW_UNUSED_TYPE PaintCap ToPaintCap(LineCapType type) {
  switch (type) {
    case LineCapType::kButt:
      return PaintCap::kButt;
    case LineCapType::kRound:
      return PaintCap::kRound;
    default:
      return PaintCap::kSquare;
  }
}

static ALLOW_UNUSED_TYPE PaintJoin ToPaintJoin(LineJoinType type) {
  switch (type) {
    case LineJoinType::kBevel:
      return PaintJoin::kBevel;
    case LineJoinType::kMiter:
      return PaintJoin::kMiter;
    default:
      return PaintJoin::kRound;
  }
}

class BaseStrokeContent;

class ShapeStrokeModel : public ContentModel {
 public:
  ShapeStrokeModel() {}

  void Init(std::string name, std::shared_ptr<AnimatableFloatValue> offset,
            std::unique_ptr<AnimatableColorValue> color,
            std::unique_ptr<AnimatableIntegerValue> opacity,
            std::unique_ptr<AnimatableFloatValue> width, int32_t cap_type_int,
            int32_t join_type_int, float miter_limit, bool hidden) {
    name_ = std::move(name);
    offset_ = std::move(offset);
    color_ = std::move(color);
    opacity_ = std::move(opacity);
    width_ = std::move(width);

    cap_type_ = static_cast<PaintCap>(cap_type_int - 1);
    join_type_ = static_cast<PaintJoin>(join_type_int - 1);
    miter_limit_ = miter_limit;

    hidden_ = hidden;
  }

  std::vector<std::shared_ptr<AnimatableFloatValue>>& GetLineDashPattern() {
    return line_dash_pattern_;
  }

  std::unique_ptr<Content> ToContent(CompositionModel& composition,
                                     BaseLayer& layer) override {
    return std::make_unique<StrokeContent>(layer, *this);
  }

 private:
  friend class StrokeContent;

  std::shared_ptr<AnimatableFloatValue> offset_;
  std::vector<std::shared_ptr<AnimatableFloatValue>> line_dash_pattern_;
  std::unique_ptr<AnimatableColorValue> color_;
  std::unique_ptr<AnimatableIntegerValue> opacity_;
  std::unique_ptr<AnimatableFloatValue> width_;
  PaintCap cap_type_;
  PaintJoin join_type_;
  float miter_limit_ = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_SHAPE_SHAPE_STROKE_MODEL_H_
