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

#ifndef ANIMAX_MODEL_KEYFRAME_PATH_KEYFRAME_MODEL_H_
#define ANIMAX_MODEL_KEYFRAME_PATH_KEYFRAME_MODEL_H_

#include <memory>

#include "animax/model/basic_model.h"
#include "animax/model/composition_model.h"
#include "animax/model/keyframe/keyframe_model.h"
#include "animax/render/include/path.h"

namespace lynx {
namespace animax {

class PathKeyframeModel : public KeyframeModel<PointF> {
 public:
  PathKeyframeModel(CompositionModel& composition,
                    KeyframeModel<PointF>& point_keyframe);
  ~PathKeyframeModel() override = default;

  KeyframeType GetType() override { return KeyframeType::kPath; }

  void CreatePath() override;
  Path* GetPath() { return path_.get(); }

 private:
  void CreatePathInner();

  std::unique_ptr<Path> path_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_KEYFRAME_PATH_KEYFRAME_MODEL_H_
