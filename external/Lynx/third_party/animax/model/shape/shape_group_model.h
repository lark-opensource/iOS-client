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

#ifndef ANIMAX_MODEL_SHAPE_SHAPE_GROUP_MODEL_H_
#define ANIMAX_MODEL_SHAPE_SHAPE_GROUP_MODEL_H_

#include <memory>
#include <string>
#include <vector>

#include "animax/content/content_group.h"
#include "animax/model/content_model.h"

namespace lynx {
namespace animax {

class ShapeGroupModel : public ContentModel {
 public:
  ShapeGroupModel(){};
  ShapeGroupModel(std::string name,
                  std::vector<std::shared_ptr<ContentModel>>& items,
                  bool hidden) {
    Init(std::move(name), hidden);
    items_ = items;
  };

  ~ShapeGroupModel() = default;

  void Init(std::string name, bool hidden) {
    name_ = std::move(name);
    hidden_ = hidden;
  };
  std::vector<std::shared_ptr<ContentModel>>& GetItems() { return items_; }

  std::unique_ptr<Content> ToContent(CompositionModel& composition,
                                     BaseLayer& layer) override {
    return std::make_unique<ContentGroup>(layer, *this, composition);
  }

  ModelType Type() override { return ModelType::kShapeGroup; }

 private:
  std::vector<std::shared_ptr<ContentModel>> items_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_SHAPE_SHAPE_GROUP_MODEL_H_
