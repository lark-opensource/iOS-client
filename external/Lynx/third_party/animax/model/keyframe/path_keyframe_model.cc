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

#include "animax/model/keyframe/path_keyframe_model.h"

#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

PathKeyframeModel::PathKeyframeModel(CompositionModel& composition,
                                     KeyframeModel<PointF>& keyframe)
    : KeyframeModel(composition, keyframe.GetStartValue(),
                    keyframe.GetEndValue(),
                    std::move(keyframe.GetInterpolator()),
                    keyframe.GetStartFrame(), keyframe.GetEndFrame()),
      path_() {
  CreatePathInner();
  SetPathCps(keyframe.GetPathCp1(), keyframe.GetPathCp2());
}

void PathKeyframeModel::CreatePath() { CreatePathInner(); }

void PathKeyframeModel::CreatePathInner() {
  if (!IsStartValueEmpty() && !IsEndValueEmpty()) {
    auto& start_value = GetStartValue();
    auto& end_value = GetEndValue();
    bool equals = start_value.Equals(end_value.GetX(), end_value.GetY());
    if (equals) {
      return;
    }

    if (!path_) {
      path_ = Context::MakePath();
    }

    path_->Reset();
    path_->MoveTo(start_value.GetX(), start_value.GetY());

    if (IsPathCpNotEmpty()) {
      auto& cp1 = GetPathCp1();
      auto& cp2 = GetPathCp2();
      if (cp1.Length() != 0 || cp2.Length() != 0) {
        path_->CubicTo(
            start_value.GetX() + cp1.GetX(), start_value.GetY() + cp1.GetY(),
            end_value.GetX() + cp2.GetX(), end_value.GetY() + cp2.GetY(),
            end_value.GetX(), end_value.GetY());
      } else {
        path_->LineTo(end_value.GetX(), end_value.GetY());
      }
    } else {
      path_->LineTo(end_value.GetX(), end_value.GetY());
    }
  }
}

}  // namespace animax
}  // namespace lynx
