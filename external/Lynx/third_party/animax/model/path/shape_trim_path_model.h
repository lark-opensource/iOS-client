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

#ifndef ANIMAX_MODEL_PATH_SHAPE_TRIM_PATH_MODEL_H_
#define ANIMAX_MODEL_PATH_SHAPE_TRIM_PATH_MODEL_H_

#include "animax/content/path/trim_path_content.h"
#include "animax/model/animatable/basic_animatable_value.h"
#include "animax/model/content_model.h"

namespace lynx {
namespace animax {

enum class ShapeTrimType : uint8_t { kSimultaneously = 0, kIndividually };

class ShapeTrimPathModel : public ContentModel {
 public:
  ShapeTrimPathModel(std::string name, int32_t shape_trim_type_int,
                     std::unique_ptr<AnimatableFloatValue> start,
                     std::unique_ptr<AnimatableFloatValue> end,
                     std::unique_ptr<AnimatableFloatValue> offset, bool hidden)
      : start_(std::move(start)),
        end_(std::move(end)),
        offset_(std::move(offset)) {
    name_ = std::move(name);
    hidden_ = hidden;
    shape_trim_type_ = static_cast<ShapeTrimType>(shape_trim_type_int - 1);
  }

  std::unique_ptr<Content> ToContent(CompositionModel& composition,
                                     BaseLayer& layer) override {
    return std::make_unique<TrimPathContent>(layer, *this);
  }

 private:
  friend class TrimPathContent;

  ShapeTrimType shape_trim_type_;
  std::unique_ptr<AnimatableFloatValue> start_;
  std::unique_ptr<AnimatableFloatValue> end_;
  std::unique_ptr<AnimatableFloatValue> offset_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_PATH_SHAPE_TRIM_PATH_MODEL_H_
