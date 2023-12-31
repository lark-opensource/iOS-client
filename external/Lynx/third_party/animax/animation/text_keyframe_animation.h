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

#ifndef ANIMAX_ANIMATION_TEXT_KEYFRAME_ANIMATION_H_
#define ANIMAX_ANIMATION_TEXT_KEYFRAME_ANIMATION_H_

#include "animax/animation/keyframe_animation.h"
#include "animax/model/text/document_data_model.h"

namespace lynx {
namespace animax {

using BaseTextKeyframeAnimation =
    BaseKeyframeAnimation<DocumentDataModel, DocumentDataModel>;
class TextKeyframeAnimation : public KeyframeAnimation<DocumentDataModel> {
 public:
  TextKeyframeAnimation(
      std::vector<std::unique_ptr<KeyframeModel<DocumentDataModel>>>& frames)
      : KeyframeAnimation<DocumentDataModel>(frames) {}

  const DocumentDataModel& GetValue(KeyframeModel<DocumentDataModel>& keyframe,
                                    float progress) const override;

  // TODO(aiyongbiao): set string value callback
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATION_TEXT_KEYFRAME_ANIMATION_H_
