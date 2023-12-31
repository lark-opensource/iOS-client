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

#include "animax/animation/text_keyframe_animation.h"

#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

const DocumentDataModel& TextKeyframeAnimation::GetValue(
    KeyframeModel<DocumentDataModel>& keyframe, float progress) const {
  // TODO(aiyongbiao): value callback

  if (progress != 1.0 || keyframe.IsEndValueEmpty()) {
    return keyframe.GetStartValue();
  } else {
    return keyframe.GetEndValue();
  }
}

}  // namespace animax
}  // namespace lynx
