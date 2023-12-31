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

#ifndef ANIMAX_ANIMATION_KEYFRAME_ANIMATION_H_
#define ANIMAX_ANIMATION_KEYFRAME_ANIMATION_H_

#include <vector>

#include "animax/base/log.h"
#include "animax/model/basic_model.h"
#include "animax/model/keyframe/keyframe_model.h"

namespace lynx {
namespace animax {

enum class AnimationType : uint8_t { kBase = 0, kShape };

class IKeyframeAnimation {
 public:
  virtual ~IKeyframeAnimation() = default;
  virtual void SetProgress(float progress) = 0;
  virtual AnimationType Type() { return AnimationType::kBase; }
};

class AnimationListener {
 public:
  virtual ~AnimationListener() = default;
  virtual void OnValueChanged() = 0;
};

template <typename T>
class KeyframesWrapper {
 public:
  virtual ~KeyframesWrapper() = default;
  virtual bool IsEmpty() = 0;
  virtual bool IsValueChanged(float progress) = 0;
  virtual KeyframeModel<T>& GetCurrentKeyframe() = 0;
  virtual float GetStartDelayProgress() = 0;
  virtual float GetEndProgress() = 0;
  virtual bool IsCachedValueEnabled(float progress) = 0;
};

template <typename T>
class SingleKeyframeWrapper : public KeyframesWrapper<T> {
 public:
  SingleKeyframeWrapper(std::vector<std::unique_ptr<KeyframeModel<T>>>& frames)
      : keyframe_(frames[0].get()) {}
  bool IsEmpty() override { return false; }
  bool IsValueChanged(float progress) override {
    return !keyframe_->IsStatic();
  }
  KeyframeModel<T>& GetCurrentKeyframe() override { return *keyframe_; }
  float GetStartDelayProgress() override {
    return keyframe_->GetStartProgress();
  }
  float GetEndProgress() override { return keyframe_->GetEndProgress(); }
  bool IsCachedValueEnabled(float progress) override {
    if (cached_progress_ == progress) {
      return true;
    }
    cached_progress_ = progress;
    return false;
  }

 private:
  KeyframeModel<T>* keyframe_;
  float cached_progress_ = -1;
};

template <typename T>
class KeyframesWrapperImpl : public KeyframesWrapper<T> {
 public:
  KeyframesWrapperImpl(std::vector<std::unique_ptr<KeyframeModel<T>>>& frames)
      : keyframes_(frames) {
    cur_keyframe_ = FindKeyframe(0);
  }
  bool IsEmpty() override { return false; }
  bool IsValueChanged(float progress) override {
    if (cur_keyframe_->ContainsProgress(progress)) {
      return !cur_keyframe_->IsStatic();
    }
    cur_keyframe_ = FindKeyframe(progress);
    return true;
  }
  KeyframeModel<T>& GetCurrentKeyframe() override { return *cur_keyframe_; }
  float GetStartDelayProgress() override {
    return keyframes_[0]->GetStartProgress();
  }
  float GetEndProgress() override {
    return keyframes_[keyframes_.size() - 1]->GetEndProgress();
  }
  bool IsCachedValueEnabled(float progress) override {
    if (cached_cur_keyframe_ == cur_keyframe_ && cached_progress_ == progress) {
      return true;
    }
    cached_cur_keyframe_ = cur_keyframe_;
    cached_progress_ = progress;
    return false;
  }

 private:
  KeyframeModel<T>* FindKeyframe(float progress) {
    auto& keyframe = keyframes_[keyframes_.size() - 1];
    if (progress >= keyframe->GetStartProgress()) {
      return keyframe.get();
    }

    if (keyframes_.size() <= 2) {
      return keyframes_[0].get();
    }

    for (auto i = keyframes_.size() - 2; i >= 1; i--) {
      auto& cur_keyframe = keyframes_[i];
      if (cur_keyframe_ == cur_keyframe.get()) {
        continue;
      }
      if (cur_keyframe->ContainsProgress(progress)) {
        return cur_keyframe.get();
      }
    }

    return keyframes_[0].get();
  }

  std::vector<std::unique_ptr<KeyframeModel<T>>>& keyframes_;
  KeyframeModel<T>* cur_keyframe_ = nullptr;
  KeyframeModel<T>* cached_cur_keyframe_ = nullptr;
  float cached_progress_ = 0;
};

template <typename K, typename A>
class BaseKeyframeAnimation : public IKeyframeAnimation {
 public:
  BaseKeyframeAnimation(
      std::vector<std::unique_ptr<KeyframeModel<K>>>& frames) {
    if (frames.empty()) {
      ANIMAX_LOGI("frames cannot be empty!");
    } else if (frames.size() == 1) {
      wrapper_ = std::make_unique<SingleKeyframeWrapper<K>>(frames);
    } else {
      wrapper_ = std::make_unique<KeyframesWrapperImpl<K>>(frames);
    }
  }

  virtual const A& GetValue() const {
    float progress = GetLinearCurrentKeyframeProgress();
    // TODO(aiyongbiao): cached get value p1

    auto& keyframe = GetCurrentKeyframe();

    if (keyframe.HasMultiDimenInterpolator()) {
      auto x_progress = keyframe.GetXProgress(progress);
      auto y_progress = keyframe.GetYProgress(progress);
      return GetValue(keyframe, progress, x_progress, y_progress);
    } else {
      if (keyframe.IsStatic()) {
        progress = 0;
      } else {
        progress = keyframe.GetProgress(progress);
      }
      return GetValue(keyframe, progress);
    }

    // TODO(aiyongbiao): cache value p1

    //        return intermediate_;
  }

  virtual const A& GetValue(KeyframeModel<K>& keyframe,
                            float progress) const = 0;

  virtual const A& GetValue(KeyframeModel<K>& keyframe, float progress,
                            float x_progress, float y_progress) const {
    return intermediate_;
  }

  KeyframeModel<K>& GetCurrentKeyframe() const {
    return wrapper_->GetCurrentKeyframe();
  }

  float GetLinearCurrentKeyframeProgress() const {
    if (is_discrete_) {
      return 0;
    }

    auto& keyframe = GetCurrentKeyframe();
    if (keyframe.IsStatic()) {
      return 0;
    }

    auto progress_into_frame = progress_ - keyframe.GetStartProgress();
    auto keyframe_progress =
        keyframe.GetEndProgress() - keyframe.GetStartProgress();

    return progress_into_frame / keyframe_progress;
  }

  void AddUpdateListener(AnimationListener* listener) {
    listeners_.push_back(listener);
  }

  virtual void SetProgress(float progress) override {
    if (wrapper_ == nullptr) {
      return;
    }

    float target_progress = progress;
    if (target_progress < GetStartDelayProgress()) {
      target_progress = GetStartDelayProgress();
    } else if (target_progress > GetEndProgress()) {
      target_progress = GetEndProgress();
    }

    if (target_progress == progress_) {
      return;
    }

    progress_ = target_progress;
    if (wrapper_->IsValueChanged(progress_)) {
      NotifyListeners();
    }
  }

  void NotifyListeners() {
    for (auto& listener : listeners_) {
      listener->OnValueChanged();
    }
  }

  void SetIsDiscrete() { is_discrete_ = true; }

  float GetProgress() { return progress_; }

 protected:
  float progress_ = 0;
  bool is_discrete_ = false;
  mutable A intermediate_;
  std::unique_ptr<KeyframesWrapper<K>> wrapper_;
  std::vector<AnimationListener*> listeners_;

 private:
  float GetStartDelayProgress() {
    if (cached_start_delay_progress_ == -1) {
      cached_start_delay_progress_ = wrapper_->GetStartDelayProgress();
    }
    return cached_start_delay_progress_;
  }

  float GetEndProgress() {
    if (cached_end_progress_ == -1) {
      cached_end_progress_ = wrapper_->GetEndProgress();
    }
    return cached_end_progress_;
  }

  float cached_start_delay_progress_ = -1;
  float cached_end_progress_ = -1;
};

template <typename T>
class KeyframeAnimation : public BaseKeyframeAnimation<T, T> {
 public:
  KeyframeAnimation(std::vector<std::unique_ptr<KeyframeModel<T>>>& frames)
      : BaseKeyframeAnimation<T, T>(frames) {}
  ~KeyframeAnimation() override = default;

  bool CheckNullValue(KeyframeModel<T>& keyframe) const {
    if (keyframe.IsStartValueEmpty() || keyframe.IsEndValueEmpty()) {
      ANIMAX_LOGI("KeyframeAnimation start_value or end_value is null");
      return true;
    }
    return false;
  }
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATION_KEYFRAME_ANIMATION_H_
