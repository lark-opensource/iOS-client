// Copyright 2021 The Lynx Authors. All rights reserved.
// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "animation/keyframe_effect.h"

#include <utility>

#include "animation/animation.h"
#include "animation/animation_curve.h"
#include "base/log/logging.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace animation {

KeyframeEffect::KeyframeEffect() : animation_delegate_(nullptr) {}

std::unique_ptr<KeyframeEffect> KeyframeEffect::Create() {
  return std::make_unique<KeyframeEffect>();
}

void KeyframeEffect::SetStartTime(fml::TimePoint& time) {
  for (auto& keyframe_model : keyframe_models_) {
    keyframe_model->set_start_time(time);
    keyframe_model->SetRunState(KeyframeModel::STARTING, time);
  }
}

void KeyframeEffect::SetPauseTime(fml::TimePoint& time) {
  for (auto& keyframe_model : keyframe_models_) {
    keyframe_model->SetRunState(KeyframeModel::PAUSED, time);
  }
}

void KeyframeEffect::AddKeyframeModel(
    std::unique_ptr<KeyframeModel> keyframe_model) {
  keyframe_models_.push_back(std::move(keyframe_model));
}

void KeyframeEffect::TickKeyframeModel(fml::TimePoint monotonic_time) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "KeyframeEffect::TickKeyframeModel");
  // Collect animated style of this animation
  tasm::StyleMap style_map;
  for (auto& keyframe_model : keyframe_models_) {
    if (!keyframe_model->InEffect(monotonic_time)) {
      return;
    }
    AnimationCurve* curve = keyframe_model->curve();
    // The counter records whether the iteration_count has changed.
    int temp_count = current_iteration_count_;
    fml::TimeDelta trimmed = keyframe_model->TrimTimeToCurrentIteration(
        monotonic_time, current_iteration_count_);
    if (current_iteration_count_ != temp_count) {
      static constexpr const char* kKeyframeIterationEventName =
          "animationiteration";
      static constexpr const char* kTransitionIterationEventName =
          "transitioniteration";
      this->animation_->CreateEventAndSend(this->animation_->GetTransitionFlag()
                                               ? kTransitionIterationEventName
                                               : kKeyframeIterationEventName);
    }
    if (trimmed != fml::TimeDelta())
      keyframe_model->SetRunState(KeyframeModel::RUNNING, monotonic_time);

    if (!animation_delegate_) {
      return;
    }

    if (SendStartEvent()) {
      static constexpr const char* kKeyframeStartEventName = "animationstart";
      static constexpr const char* kTransitionStartEventName =
          "transitionstart";
      this->animation_->CreateEventAndSend(this->animation_->GetTransitionFlag()
                                               ? kTransitionStartEventName
                                               : kKeyframeStartEventName);
    }

    tasm::CSSValue value = curve->GetValue(trimmed);
    animation_delegate_->NotifyClientAnimated(
        style_map, value, static_cast<tasm::CSSPropertyID>(curve->Type()));
  }
  if (animation_delegate_ != nullptr) {
    animation_delegate_->UpdateFinalStyleMap(style_map);
  }
}

bool KeyframeEffect::CheckHasFinished(fml::TimePoint& monotonic_time) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "KeyframeEffect::CheckHasFinished");
  if (!keyframe_models_.empty()) {
    bool is_in_effect = keyframe_models_[0]->InEffect(monotonic_time);
    bool is_in_play = keyframe_models_[0]->InPlay(monotonic_time);
    if ((!is_in_effect || !is_in_play) &&
        keyframe_models_[0]->IsFinishedAt(monotonic_time)) {
      keyframe_models_[0]->SetRunState(KeyframeModel::FINISHED, monotonic_time);
      if (!is_in_effect) {
        ClearEffect();
      };
    }

    if (!keyframe_models_[0]->is_finished()) {
      return false;
    }
  }
  return true;
}

void KeyframeEffect::ClearEffect() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "KeyframeEffect::ClearEffect");
  if (animation_delegate_) {
    animation_delegate_->SetNeedsAnimationStyleRecalc(animation_->name());
  }
}

KeyframeModel* KeyframeEffect::GetKeyframeModelByCurveType(
    AnimationCurve::CurveType type) {
  for (auto& keyframe_model : keyframe_models_) {
    if (keyframe_model->animation_curve()->Type() == type) {
      return keyframe_model.get();
    }
  }
  return nullptr;
}

void KeyframeEffect::UpdateAnimationData(starlight::AnimationData* data) {
  for (auto& keyframe_model : keyframe_models_) {
    if (keyframe_model) {
      keyframe_model->UpdateAnimationData(data);
    }
  }
}

void KeyframeEffect::EnsureFromAndToKeyframe() {
  for (auto& keyframe_model : keyframe_models_) {
    keyframe_model->EnsureFromAndToKeyframe();
  }
}

void KeyframeEffect::NotifyElementSizeUpdated() {
  for (auto& keyframe_model : keyframe_models_) {
    if (keyframe_model) {
      keyframe_model->NotifyElementSizeUpdated();
    }
  }
}

}  // namespace animation
}  // namespace lynx
