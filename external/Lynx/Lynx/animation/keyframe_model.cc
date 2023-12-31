// Copyright 2021 The Lynx Authors. All rights reserved.
// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "animation/keyframe_model.h"

#include <algorithm>
#include <climits>
#include <cstdlib>
#include <utility>

#include "animation/animation_curve.h"
#include "base/log/logging.h"

namespace lynx {
namespace animation {
std::unique_ptr<KeyframeModel> KeyframeModel::Create(
    std::unique_ptr<AnimationCurve> curve) {
  return std::make_unique<KeyframeModel>(std::move(curve));
}

KeyframeModel::KeyframeModel(std::unique_ptr<AnimationCurve> curve)
    : run_state_(WAITING_FOR_TARGET_AVAILABILITY),
      curve_(std::move(curve)),
      playback_rate_(1) {}

KeyframeModel::Phase KeyframeModel::CalculatePhase(
    fml::TimeDelta local_time) const {
  fml::TimeDelta time_offset =
      fml::TimeDelta::FromMilliseconds(animation_data_->delay * -1);
  fml::TimeDelta opposite_time_offset = time_offset == fml::TimeDelta::Min()
                                            ? fml::TimeDelta::Max()
                                            : fml::TimeDelta() - time_offset;
  fml::TimeDelta before_active_boundary_time =
      std::max(opposite_time_offset, fml::TimeDelta());
  if (local_time < before_active_boundary_time ||
      (local_time == before_active_boundary_time && playback_rate_ < 0)) {
    return KeyframeModel::Phase::BEFORE;
  }

  fml::TimeDelta active_duration =
      curve_->Duration() *
      static_cast<double>(animation_data_->iteration_count) /
      std::abs(playback_rate_);

  //   LOGE("linxs
  //   curve_->Duration:"<<curve_->Duration().ToSecondsF()<<",localtime:"<<local_time.ToSecondsF()<<",active_duration:"<<active_duration.ToSecondsF()
  //   <<",opposite_time_offset:"<<opposite_time_offset.ToSecondsF()<<",active_duration:"<<active_duration.ToSecondsF()<<",iteration_count:"<<animation_data_->iteration_count
  //   <<",playback_rate_:"<<playback_rate_);

  fml::TimeDelta active_after_boundary_time =
      // Negative iterations_ represents "infinite iterations".
      animation_data_->iteration_count >= 0
          ? std::max(opposite_time_offset + active_duration, fml::TimeDelta())
          : fml::TimeDelta::Max();
  if (local_time > active_after_boundary_time ||
      (local_time == active_after_boundary_time && playback_rate_ > 0)) {
    return KeyframeModel::Phase::AFTER;
  }
  return KeyframeModel::Phase::ACTIVE;
}

fml::TimeDelta KeyframeModel::ConvertMonotonicTimeToLocalTime(
    fml::TimePoint monotonic_time) const {
  // If we're paused, time is 'stuck' at the pause time.
  fml::TimePoint time = (run_state_ == PAUSED) ? pause_time_ : monotonic_time;
  return time - start_time_ - total_paused_duration_;
}

fml::TimeDelta KeyframeModel::CalculateActiveTime(
    fml::TimePoint monotonic_time) const {
  fml::TimeDelta time_offset =
      fml::TimeDelta::FromMilliseconds(animation_data_->delay * -1);
  fml::TimeDelta local_time = ConvertMonotonicTimeToLocalTime(monotonic_time);
  // LOGE("[animation] CalculateActiveTime
  // monotonic_time:"<<monotonic_time.ToEpochDelta().ToSecondsF()<<",local_time:"<<local_time.ToSecondsF());

  KeyframeModel::Phase phase = CalculatePhase(local_time);

  switch (phase) {
    case KeyframeModel::Phase::BEFORE:
      if (animation_data_->fill_mode ==
              starlight::AnimationFillModeType::kBackwards ||
          animation_data_->fill_mode == starlight::AnimationFillModeType::kBoth)
        return std::max(local_time + time_offset, fml::TimeDelta());
      return fml::TimeDelta::Min();
    case KeyframeModel::Phase::ACTIVE:
      return local_time + time_offset;
    case KeyframeModel::Phase::AFTER:
      if (animation_data_->fill_mode ==
              starlight::AnimationFillModeType::kForwards ||
          animation_data_->fill_mode ==
              starlight::AnimationFillModeType::kBoth) {
        fml::TimeDelta active_duration =
            curve_->Duration() *
            static_cast<double>(animation_data_->iteration_count) /
            std::abs(playback_rate_);
        return std::max(std::min(local_time + time_offset, active_duration),
                        fml::TimeDelta());
      }
      return fml::TimeDelta::Min();
    default:
      return fml::TimeDelta::Min();
  }
}

fml::TimeDelta KeyframeModel::TrimTimeToCurrentIteration(
    fml::TimePoint monotonic_time, int& current_iteration_count) const {
  fml::TimeDelta active_time = CalculateActiveTime(monotonic_time);
  fml::TimeDelta start_offset = fml::TimeDelta();

  // Return start offset if we are before the start of the keyframe model
  if (active_time < fml::TimeDelta()) return start_offset;
  // Always return zero if we have no iterations.
  if (!animation_data_->iteration_count) return fml::TimeDelta();

  // Don't attempt to trim if we have no duration.
  if (curve_->Duration() <= fml::TimeDelta()) return fml::TimeDelta();

  fml::TimeDelta repeated_duration =
      curve_->Duration() *
      static_cast<double>(animation_data_->iteration_count);
  fml::TimeDelta active_duration = repeated_duration / std::abs(playback_rate_);

  // Calculate the scaled active time
  fml::TimeDelta scaled_active_time;
  if (playback_rate_ < 0) {
    scaled_active_time =
        ((active_time - active_duration) * playback_rate_) + start_offset;
  } else {
    scaled_active_time = (active_time * playback_rate_) + start_offset;
  }

  // Calculate the iteration time
  fml::TimeDelta iteration_time;
  if (scaled_active_time - start_offset == repeated_duration &&
      fmod(static_cast<double>(animation_data_->iteration_count), 1) == 0)
    iteration_time = curve_->Duration();
  else
    iteration_time = scaled_active_time % curve_->Duration();
  //   LOGE("[animation]
  //   scaled_active_time:"<<scaled_active_time.ToSecondsF()<<",duration:"<<curve_->Duration().ToSecondsF());

  // Calculate the current iteration
  int iteration;
  if (scaled_active_time <= fml::TimeDelta())
    iteration = 0;
  else if (iteration_time == curve_->Duration())
    iteration = ceil(static_cast<double>(animation_data_->iteration_count) - 1);
  else
    iteration = static_cast<int>(scaled_active_time / curve_->Duration());

  current_iteration_count = iteration;
  // Check if we are running the keyframe model in reverse direction for the
  // current iteration
  bool reverse = (animation_data_->direction ==
                  starlight::AnimationDirectionType::kReverse) ||
                 (animation_data_->direction ==
                      starlight::AnimationDirectionType::kAlternate &&
                  iteration % 2 == 1) ||
                 (animation_data_->direction ==
                      starlight::AnimationDirectionType::kAlternateReverse &&
                  iteration % 2 == 0);

  // If we are running the keyframe model in reverse direction, reverse the
  // result
  if (reverse) iteration_time = curve_->Duration() - iteration_time;

  return iteration_time;
}

bool KeyframeModel::InEffect(fml::TimePoint monotonic_time) const {
  return CalculateActiveTime(monotonic_time) != fml::TimeDelta::Min();
}

bool KeyframeModel::InPlay(fml::TimePoint monotonic_time) const {
  fml::TimeDelta local_time = ConvertMonotonicTimeToLocalTime(monotonic_time);
  KeyframeModel::Phase phase = CalculatePhase(local_time);
  return phase == KeyframeModel::Phase::ACTIVE;
}

void KeyframeModel::SetRunState(RunState run_state,
                                fml::TimePoint monotonic_time) {
  if (run_state == RUNNING && run_state_ == PAUSED) {
    total_paused_duration_ =
        total_paused_duration_ + (monotonic_time - pause_time_);
  } else if (run_state == PAUSED) {
    pause_time_ = monotonic_time;
  }
  run_state_ = run_state;
}

bool KeyframeModel::IsFinishedAt(fml::TimePoint monotonic_time) const {
  if (is_finished()) return true;

  if (playback_rate_ == 0) return false;

  fml::TimeDelta time_offset =
      fml::TimeDelta::FromMilliseconds(animation_data_->delay * -1);
  // LOG(ERROR)<<__FUNCTION__<<",run_state_:"<<run_state_<<",this:"<<this;
  return run_state_ == RUNNING && animation_data_->iteration_count >= 0 &&
         (curve_->Duration() *
          (animation_data_->iteration_count / std::abs(playback_rate_))) <=
             (ConvertMonotonicTimeToLocalTime(monotonic_time) + time_offset);
}

void KeyframeModel::UpdateAnimationData(starlight::AnimationData* data) {
  animation_data_ = data;
  if (curve_) {
    // bind timing_function
    curve_->SetTimingFunction(TimingFunction::MakeTimingFunction(data));

    // scaled_duration's unit is second.
    curve_->set_scaled_duration(data->duration / 1000.0);
  }
}

void KeyframeModel::EnsureFromAndToKeyframe() {
  if (curve_) {
    curve_->EnsureFromAndToKeyframe();
  }
}

void KeyframeModel::NotifyElementSizeUpdated() {
  if (curve_) {
    curve_->NotifyElementSizeUpdated();
  }
}

}  // namespace animation
}  // namespace lynx
