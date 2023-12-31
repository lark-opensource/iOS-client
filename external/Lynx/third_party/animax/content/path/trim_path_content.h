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

#ifndef ANIMAX_CONTENT_PATH_TRIM_PATH_CONTENT_H_
#define ANIMAX_CONTENT_PATH_TRIM_PATH_CONTENT_H_

#include <vector>

#include "animax/animation/keyframe_animation.h"
#include "animax/content/content.h"
#include "animax/content/path/path_util.h"
#include "animax/layer/base_layer.h"

namespace lynx {
namespace animax {

class BaseStrokeContent;
class EllipseContent;
class RectangleContent;
class PolystarContent;

class ShapeTrimPathModel;
enum class ShapeTrimType : uint8_t;

class TrimPathContent : public Content, public AnimationListener {
 public:
  TrimPathContent(BaseLayer& layer, ShapeTrimPathModel& model);

  void Init() override;

  ContentType MainType() override { return ContentType::kTrimPath; }

  void SetContents(std::vector<Content*>& contents_before,
                   std::vector<Content*>& contents_after) override {}

  void OnValueChanged() override {
    for (auto& listener : listeners_) {
      listener->OnValueChanged();
    }
  }

  void AddListener(AnimationListener* listener) {
    listeners_.push_back(listener);
  }

  bool IsHidden() const { return hidden_; }

  ShapeTrimType& GetType() { return type_; }

  BaseFloatKeyframeAnimation& GetStart() const;
  BaseFloatKeyframeAnimation& GetEnd() const;
  BaseFloatKeyframeAnimation& GetOffset() const;

 private:
  friend BaseStrokeContent;
  friend EllipseContent;
  friend RectangleContent;
  friend PolystarContent;

  std::vector<AnimationListener*> listeners_;
  ShapeTrimType type_;
  std::unique_ptr<BaseFloatKeyframeAnimation> start_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> end_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> offset_animation_;
};

class CompoundTrimPathContent {
 public:
  void AddTrimPathIfNeeds(Content* content, AnimationListener* listener);

  void Apply(Path& path) {
    for (auto it = contents_.rbegin(); it != contents_.rend(); it++) {
      PathUtil::ApplyTrimPathIfNeeds(path, *it);
    }
  }

 private:
  void AddTrimPath(TrimPathContent* trim_path) {
    contents_.push_back(trim_path);
  }

  std::vector<TrimPathContent*> contents_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_CONTENT_PATH_TRIM_PATH_CONTENT_H_
