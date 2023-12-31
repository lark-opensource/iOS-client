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

#include "animax/content/shape/ellipse_content.h"

#include "animax/content/path/trim_path_content.h"
#include "animax/model/path/shape_trim_path_model.h"
#include "animax/model/shape/circle_shape_model.h"
#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

EllipseContent::EllipseContent(BaseLayer& layer,
                               std::shared_ptr<CircleShapeModel> model)
    : path_(Context::MakePath()) {
  name_ = model->name_;
  size_animation_ = model->size_->CreateAnimation();
  position_animation_ = model->position_->CreateAnimation();
  circle_shape_ = std::move(model);

  layer.AddAnimation(size_animation_.get());
  layer.AddAnimation(position_animation_.get());
}

void EllipseContent::Init() {
  if (size_animation_) {
    size_animation_->AddUpdateListener(this);
  }

  if (position_animation_) {
    position_animation_->AddUpdateListener(this);
  }
}

Path* EllipseContent::GetPath() {
  if (is_path_valid_) {
    return path_.get();
  }

  path_->Reset();
  if (circle_shape_->hidden_) {
    is_path_valid_ = true;
    return path_.get();
  }

  const auto& size = size_animation_->GetValue();
  auto half_width = size.GetX() / 2.0;
  auto half_height = size.GetY() / 2.0;

  auto cp_w = half_width * kEllipseControlPointPercentage;
  auto cp_h = half_height * kEllipseControlPointPercentage;

  path_->Reset();
  if (circle_shape_->reversed_) {
    path_->CubicTo(0 - cp_w, -half_height, -half_width, 0 - cp_h, -half_width,
                   0);
    path_->CubicTo(-half_width, 0 + cp_h, 0 - cp_w, half_height, 0,
                   half_height);
    path_->CubicTo(0 + cp_w, half_height, half_width, 0 + cp_h, half_width, 0);
    path_->CubicTo(half_width, 0 - cp_h, 0 + cp_w, -half_height, 0,
                   -half_height);
  } else {
    path_->MoveTo(0, -half_height);
    path_->CubicTo(0 + cp_w, -half_height, half_width, 0 - cp_h, half_width, 0);
    path_->CubicTo(half_width, 0 + cp_h, 0 + cp_w, half_height, 0, half_height);
    path_->CubicTo(0 - cp_w, half_height, -half_width, 0 + cp_h, -half_width,
                   0);
    path_->CubicTo(-half_width, 0 - cp_h, 0 - cp_w, -half_height, 0,
                   -half_height);
  }

  const auto& position = position_animation_->GetValue();
  path_->Offset(position.GetX(), position.GetY());
  path_->Close();
  trim_paths_.Apply(*path_);

  is_path_valid_ = true;
  return path_.get();
}

void EllipseContent::OnValueChanged() { is_path_valid_ = false; }

void EllipseContent::ResolveKeyPath(KeyPathModel* key_path, int32_t depth,
                                    std::vector<KeyPathModel*> accumulator,
                                    KeyPathModel* current_partial_key_path) {
  // TODO(aiyongbiao): resolve key path p1
}

void EllipseContent::SetContents(std::vector<Content*>& contents_before,
                                 std::vector<Content*>& contents_after) {
  for (auto& content : contents_before) {
    trim_paths_.AddTrimPathIfNeeds(content, this);
  }
}

}  // namespace animax
}  // namespace lynx
