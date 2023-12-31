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

#ifndef ANIMAX_CONTENT_SHAPE_POLYSTAR_CONTENT_H_
#define ANIMAX_CONTENT_SHAPE_POLYSTAR_CONTENT_H_

#include "animax/animation/keyframe_animation.h"
#include "animax/content/content.h"
#include "animax/content/path/key_path_element.h"
#include "animax/content/path/trim_path_content.h"

namespace lynx {
namespace animax {

static constexpr float kPolystarMagicNumber = .47829;
static constexpr float kPolygonMagicNumber = .25;

class PolystarShapeModel;
enum class PolystarShapeType : uint8_t;

class PolystarContent : public AnimationListener, public KeyPathElementContent {
 public:
  PolystarContent(BaseLayer& layer, PolystarShapeModel& model);

  void Init() override;

  Path* GetPath() override;

  void SetContents(std::vector<Content*>& contents_before,
                   std::vector<Content*>& contents_after) override;

  void OnValueChanged() override;

  void ResolveKeyPath(KeyPathModel* key_path, int32_t depth,
                      std::vector<KeyPathModel*> accumulator,
                      KeyPathModel* current_partial_key_path) override;

  void CreateStarPath();
  void CreatePolygonPath();

  bool SubPathType() override { return true; }

 private:
  std::unique_ptr<Path> path_;
  PolystarShapeType type_;
  bool reversed_ = false;

  std::unique_ptr<BaseFloatKeyframeAnimation> points_animation_;
  std::unique_ptr<BasePointFKeyframeAnimation> position_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> rotation_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> inner_radius_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> outer_radius_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> inner_rounded_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> outer_rounded_animation_;

  CompoundTrimPathContent trim_paths_;
  bool is_path_valid_ = false;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_CONTENT_SHAPE_POLYSTAR_CONTENT_H_
