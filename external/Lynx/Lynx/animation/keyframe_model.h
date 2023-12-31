// Copyright 2021 The Lynx Authors. All rights reserved.
// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_ANIMATION_KEYFRAME_MODEL_H_
#define LYNX_ANIMATION_KEYFRAME_MODEL_H_

#include <cmath>
#include <memory>
#include <string>

#include "starlight/style/animation_data.h"
#include "starlight/style/css_type.h"
#include "third_party/fml/time/time_point.h"

namespace lynx {
namespace animation {

class AnimationCurve;

class KeyframeModel {
 public:
  enum RunState {
    WAITING_FOR_TARGET_AVAILABILITY = 0,
    WAITING_FOR_DELETION,
    STARTING,
    RUNNING,
    PAUSED,
    FINISHED,
    ABORTED,
    ABORTED_BUT_NEEDS_COMPLETION,
    // This sentinel must be last.
    LAST_RUN_STATE = ABORTED_BUT_NEEDS_COMPLETION
  };

  enum class Phase { BEFORE, ACTIVE, AFTER };

  static std::unique_ptr<KeyframeModel> Create(
      std::unique_ptr<AnimationCurve> curve);

  fml::TimePoint start_time() const { return start_time_; }
  fml::TimePoint pause_time() const { return pause_time_; }

  void set_start_time(fml::TimePoint& monotonic_time) {
    start_time_ = monotonic_time;
  }
  bool has_set_start_time() const { return start_time_ != fml::TimePoint(); }

  double playback_rate() { return playback_rate_; }
  void set_playback_rate(double playback_rate) {
    playback_rate_ = playback_rate;
  }

  KeyframeModel::Phase CalculatePhase(fml::TimeDelta local_time) const;

  // LocalTime is relative time
  fml::TimeDelta ConvertMonotonicTimeToLocalTime(
      fml::TimePoint monotonic_time) const;

  fml::TimeDelta CalculateActiveTime(fml::TimePoint monotonic_time) const;

  fml::TimeDelta TrimTimeToCurrentIteration(fml::TimePoint monotonic_time,
                                            int& current_iteration_count) const;

  AnimationCurve* curve() { return curve_.get(); }
  const AnimationCurve* curve() const { return curve_.get(); }

  bool InEffect(fml::TimePoint monotonic_time) const;
  bool InPlay(fml::TimePoint monotonic_time) const;

  void SetRunState(RunState run_state, fml::TimePoint monotonic_time);
  RunState GetRunState() { return run_state_; }
  bool is_finished() const {
    return run_state_ == FINISHED || run_state_ == ABORTED ||
           run_state_ == WAITING_FOR_DELETION;
  }

  bool IsFinishedAt(fml::TimePoint monotonic_time) const;

  void set_animation_data(starlight::AnimationData* data) {
    animation_data_ = data;
  }

  starlight::AnimationData get_animation_data() { return *animation_data_; }

  AnimationCurve* animation_curve() { return curve_.get(); }

  void UpdateAnimationData(starlight::AnimationData* data);

  void EnsureFromAndToKeyframe();

  void NotifyElementSizeUpdated();

 public:
  KeyframeModel(std::unique_ptr<AnimationCurve> curve);

 private:
  RunState run_state_;
  starlight::AnimationData* animation_data_;
  fml::TimePoint start_time_;
  std::unique_ptr<AnimationCurve> curve_;
  double playback_rate_;
  fml::TimePoint pause_time_;
  fml::TimeDelta total_paused_duration_{fml::TimeDelta()};

  // The time offset effectively pushes the start of the keyframe model back in
  // time. This is used for resuming paused KeyframeModels -- an animation is
  // added with a non-zero time offset, causing the keyframe model to skip ahead
  // to the desired point in time.
  fml::TimeDelta time_offset_;
  //  bool received_finished_event_{false};
};

}  // namespace animation
}  // namespace lynx

#endif  // LYNX_ANIMATION_KEYFRAME_MODEL_H_
