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

#ifndef ANIMAX_MODEL_ANIMATABLE_ANIMATABLE_VALUE_H_
#define ANIMAX_MODEL_ANIMATABLE_ANIMATABLE_VALUE_H_

#include <vector>

#include "animax/animation/keyframe_animation.h"
#include "animax/model/keyframe/keyframe_model.h"

namespace lynx {
namespace animax {

enum class AnimatableType : uint8_t { kUnknown = 0, kSplitPath };

template <typename K, typename A>
class AnimatableValue {
 public:
  virtual ~AnimatableValue() = default;

  virtual std::vector<std::unique_ptr<KeyframeModel<K>>>& GetKeyframes() = 0;
  virtual bool IsStatic() = 0;
  virtual std::unique_ptr<BaseKeyframeAnimation<K, A>> CreateAnimation() = 0;
  virtual AnimatableType Type() { return AnimatableType::kUnknown; }
};

template <typename K, typename A>
class BaseAnimatableValue : public AnimatableValue<K, A> {
 public:
  bool IsStatic() override {
    return frames_.empty() || (frames_.size() == 1 && frames_[0]->IsStatic());
  }
  std::vector<std::unique_ptr<KeyframeModel<K>>>& GetKeyframes() override {
    // todo(aiyongbiao.rick): consume empty keyframe list on debug
    return frames_;
  }

 protected:
  std::vector<std::unique_ptr<KeyframeModel<K>>> frames_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_ANIMATABLE_ANIMATABLE_VALUE_H_
