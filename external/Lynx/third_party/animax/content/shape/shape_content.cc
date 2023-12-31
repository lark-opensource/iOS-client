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

#include "animax/content/shape/shape_content.h"

#include "animax/content/path/trim_path_content.h"
#include "animax/model/path/shape_trim_path_model.h"
#include "animax/model/shape/shape_path_model.h"
#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

ShapeContent::ShapeContent(BaseLayer& layer, ShapePathModel& model)
    : path_(Context::MakePath()) {
  name_ = model.GetName();
  hidden_ = model.IsHidden();

  shape_animation_ = model.GetShapePath()->CreateAnimation();
  if (shape_animation_) {
    layer.AddAnimation(shape_animation_.get());
  }
}

void ShapeContent::Init() {
  if (shape_animation_) {
    shape_animation_->AddUpdateListener(this);
  }
}

void ShapeContent::OnValueChanged() { is_path_valid_ = false; }

void ShapeContent::SetContents(std::vector<Content*>& contents_before,
                               std::vector<Content*>& contents_after) {
  for (auto& content : contents_before) {
    trim_paths_.AddTrimPathIfNeeds(content, this);

    if (content->MainType() == ContentType::kShapeModifier) {
      auto shape_modifier_content = static_cast<ShapeModifierContent*>(content);
      shape_modifier_contents_.push_back(shape_modifier_content);
    }
  }

  if (shape_animation_->Type() == AnimationType::kShape) {
    auto shape_animation =
        static_cast<ShapeKeyframeAnimation*>(shape_animation_.get());
    shape_animation->SetShapeModifiers(shape_modifier_contents_);
  }
}

Path* ShapeContent::GetPath() {
  if (is_path_valid_ && shape_modifier_contents_.empty()) {
    return path_.get();
  }

  path_->Reset();
  if (hidden_) {
    is_path_valid_ = true;
    return path_.get();
  }

  const auto& anim_path = shape_animation_->GetValue();
  //    if (anim_path == nullptr) {
  //        return path_.get();
  //    }

  path_->Set(anim_path.get());
  path_->SetFillType(PathFillType::kEvenOdd);

  trim_paths_.Apply(*path_);

  is_path_valid_ = true;
  return path_.get();
}

}  // namespace animax
}  // namespace lynx
