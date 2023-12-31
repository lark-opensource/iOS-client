// Copyright 2021 The Lynx Authors. All rights reserved.

#include "animation/animation.h"

#include <math.h>

#include <utility>

#include "base/log/logging.h"
#include "base/trace_event/trace_event.h"
#include "shell/common/vsync_monitor.h"

namespace lynx {
namespace animation {
Animation::Animation(const std::string& name)
    : name_(name), keyframe_effect_(nullptr) {}

void Animation::Play() {
  if (state_ == State::kPlay) {
    return;
  }
  // Since `DoFrame` may reads and modifies state_, the change of state_ must be
  // completed before DoFrame is executed.
  State temp_state = state_;
  state_ = State::kPlay;
  // The kIdle flag indicates that the animation has just been created and has
  // never been ticked before. Here we need to use dummy time to tick the
  // animation to ensure the style is correct.

  // This is a tricky code used to solve the UI flickering issue in some cases
  // on iOS. The root cause is that the operation of destroying an old animator
  // and ticking a newly created animator are not within the same UI operation,
  // causing them to take effect in different frames, resulting in flickering.
  // To solve this problem, these two operations need to occur within the same
  // UI operation. A tricky approach is used here, which involves using a dummy
  // time to actively tick the newly created animator. The more reasonable
  // approach is to delay the destruction of the old animator until the next
  // vsync, and then simultaneously perform the operations of destroying the old
  // animator and ticking the newly created animator on the next vsync.

  // TODO(WUJINTIAN): Remove these tricky code and defer the destruction of the
  // animator to the next vsync to solve the aforementioned problem.
  if (temp_state == State::kIdle) {
    DoFrame(GetAnimationDummyStartTime());
    if (animation_delegate_) {
      animation_delegate_->FlushAnimatedStyle();
    }
  } else {
    RequestNextFrame();
  }
}

void Animation::Pause() {
  if (state_ == State::kPause) {
    return;
  }
  state_ = State::kPause;
}

void Animation::Stop() {
  state_ = State::kStop;
  static constexpr const char* kKeyframeEndEventName = "animationend";
  static constexpr const char* kTransitionEndEventName = "transitionend";
  CreateEventAndSend(is_transition_ ? kTransitionEndEventName
                                    : kKeyframeEndEventName);
}

void Animation::Destroy(bool need_clear_effect) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Animation::Destroy");
  if (need_clear_effect) {
    keyframe_effect_->ClearEffect();
  }
  if (state_ == State::kPlay || state_ == State::kPause) {
    static constexpr const char* kKeyframeCancelEventName = "animationcancel";
    static constexpr const char* kTransitionCancelEventName =
        "transitioncancel";
    CreateEventAndSend(is_transition_ ? kTransitionCancelEventName
                                      : kKeyframeCancelEventName);
  }
  state_ = State::kStop;
  if (animation_delegate_) {
    animation_delegate_->FlushAnimatedStyle();
  }
}

void Animation::CreateEventAndSend(const char* event) {
  auto dict = lepus::Dictionary::Create();
  static constexpr const char* kKeyframeAnimationName = "keyframe-animation";
  static constexpr const char* kTransitionAnimationName =
      "transition-animation";
  dict->SetValue(lepus::String("new_animator"), lepus::Value(true));
  dict->SetValue(lepus::String("animation_type"),
                 lepus::Value(is_transition_ ? kTransitionAnimationName
                                             : kKeyframeAnimationName));
  dict->SetValue(lepus::String("animation_name"),
                 lepus::Value(this->animation_data()->name.c_str()));
  lepus::Value dict_value = lepus::Value(dict);
  element_->element_manager()->SendAnimationEvent(event, element_->impl_id(),
                                                  std::move(dict_value));
}

void Animation::SetKeyframeEffect(
    std::unique_ptr<KeyframeEffect> keyframe_effect) {
  keyframe_effect->SetAnimation(this);
  keyframe_effect_ = std::move(keyframe_effect);
}

void Animation::Tick(fml::TimePoint& time) {
  if (!keyframe_effect_) {
    return;
  }

  // If start_time_ is uninitialized or is a dummy time, we should update it.
  if (start_time_ == fml::TimePoint::Min() ||
      start_time_ == GetAnimationDummyStartTime()) {
    start_time_ = time;
    keyframe_effect_->SetStartTime(time);
  }

  keyframe_effect_->TickKeyframeModel(time);
}

void Animation::BindDelegate(AnimationDelegate* target) {
  animation_delegate_ = target;
}

bool Animation::HasFinishedAll(fml::TimePoint& time) {
  if (!keyframe_effect_ || keyframe_effect_->CheckHasFinished(time)) {
    return true;
  }
  return false;
}

void Animation::RequestNextFrame() {
  if (animation_delegate_) {
    animation_delegate_->RequestNextFrame(
        std::weak_ptr<Animation>(shared_from_this()));
  }
}

void Animation::DoFrame(fml::TimePoint& frame_time) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Animation::DoFrame");
  if (frame_time != fml::TimePoint::Min()) {
    Tick(frame_time);
    if (HasFinishedAll(frame_time)) {
      LOGI("[animation] all keyframe effect has finished!");
      Stop();
    }
  }

  if (state_ == State::kPlay) {
    RequestNextFrame();
  } else if (state_ == State::kPause) {
    keyframe_effect_->SetPauseTime(frame_time);
  }
}

void Animation::UpdateAnimationData(starlight::AnimationData& data) {
  animation_data_ = data;
  if (keyframe_effect_) {
    keyframe_effect_->UpdateAnimationData(&animation_data_);
  }
}

void Animation::NotifyElementSizeUpdated() {
  if (keyframe_effect_) {
    keyframe_effect_->NotifyElementSizeUpdated();
  }
}

fml::TimePoint& Animation::GetAnimationDummyStartTime() {
  static fml::TimePoint kAnimationDummyStartTime = fml::TimePoint();
  return kAnimationDummyStartTime;
}

}  // namespace animation
}  // namespace lynx
