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

#ifndef ANIMAX_MODEL_KEYFRAME_KEYFRAME_MODEL_H_
#define ANIMAX_MODEL_KEYFRAME_KEYFRAME_MODEL_H_

#include <memory>

#include "animax/animation/interpolator/interpolator.h"
#include "animax/base/log.h"
#include "animax/model/basic_model.h"
#include "animax/model/composition_model.h"

namespace lynx {
namespace animax {

enum class KeyframeType : uint8_t { kPath = 0, kNormal };

template <typename T>
class KeyframeModel {
 public:
  // create by single start value
  KeyframeModel(CompositionModel& composition, T value)
      : composition_(composition),
        start_value_(value),
        end_value_(value),
        start_frame_(Float::Min()),
        end_frame_(Float::Max()) {}

  // create by both start/end value
  KeyframeModel(CompositionModel& composition, T start_value, T end_value,
                std::unique_ptr<Interpolator> interpolator, float start_frame,
                float end_frame)
      : composition_(composition),
        start_value_(start_value),
        end_value_(end_value),
        start_frame_(start_frame),
        end_frame_(end_frame),
        interpolator_(std::move(interpolator)) {}

  // create multi dimens interpolator
  KeyframeModel(CompositionModel& composition, T start_value, T end_value,
                std::unique_ptr<Interpolator> x_interpolator,
                std::unique_ptr<Interpolator> y_interpolator, float start_frame,
                float end_frame)
      : composition_(composition),
        start_value_(start_value),
        end_value_(end_value),
        start_frame_(start_frame),
        end_frame_(end_frame),
        x_interpolator_(std::move(x_interpolator)),
        y_interpolator_(std::move(y_interpolator)) {}

  virtual ~KeyframeModel() = default;

  KeyframeModel(const KeyframeModel&) = delete;
  KeyframeModel& operator=(const KeyframeModel&) = delete;

  float GetStartFrame() { return start_frame_; }
  float GetEndFrame() { return end_frame_; }

  void SetStartFrame(float frame) { start_frame_ = frame; }
  void SetEndFrame(float frame) { end_frame_ = frame; }

  T& GetStartValue() { return start_value_; }

  T& GetEndValue() { return end_value_; }
  void SetEndValue(T& end_value) { end_value_ = end_value; }

  void SetPathCps(PointF& cp1, PointF& cp2) {
    path_cp1_ = cp1;
    path_cp2_ = cp2;
  }
  bool IsPathCpNotEmpty() {
    return !path_cp1_.IsEmpty() && !path_cp2_.IsEmpty();
  }

  PointF& GetPathCp1() { return path_cp1_; }
  PointF& GetPathCp2() { return path_cp2_; }

  bool IsStartValueEmpty() { return start_value_.IsEmpty(); }
  bool IsEndValueEmpty() { return end_value_.IsEmpty(); }

  bool IsStatic() const {
    return interpolator_ == nullptr && x_interpolator_ == nullptr &&
           y_interpolator_ == nullptr;
  }

  float GetStartProgress() {
    if (start_progress_ == Float::Min()) {
      start_progress_ = (start_frame_ - composition_.GetStartFrame()) /
                        composition_.GetDurationFrames();
    }
    return start_progress_;
  }

  float GetEndProgress() {
    if (end_progress_ == Float::Min()) {
      if (end_frame_ == Float::Min()) {
        end_progress_ = 1;
      } else {
        float start_progress = GetStartProgress();
        float frames = end_frame_ - start_frame_;
        float progress = frames / composition_.GetDurationFrames();
        end_progress_ = start_progress + progress;
      }
    }
    return end_progress_;
  }

  bool ContainsProgress(float progress) {
    return progress >= GetStartProgress() && progress < GetEndProgress();
  }

  std::unique_ptr<Interpolator>& GetInterpolator() { return interpolator_; }

  bool HasMultiDimenInterpolator() {
    return x_interpolator_ && y_interpolator_;
  }
  float GetProgress(float progress) {
    return interpolator_ ? interpolator_->GetInterpolation(progress) : 0;
  }
  float GetXProgress(float progress) {
    return x_interpolator_ ? x_interpolator_->GetInterpolation(progress) : 0;
  }
  float GetYProgress(float progress) {
    return y_interpolator_ ? y_interpolator_->GetInterpolation(progress) : 0;
  }

  virtual void CreatePath() {}
  virtual KeyframeType GetType() { return KeyframeType::kNormal; }

 private:
  CompositionModel& composition_;

  T start_value_;
  T end_value_;

  float start_frame_ = 0;
  float end_frame_ = Float::Min();

  PointF path_cp1_;
  PointF path_cp2_;

  float start_progress_ = Float::Min();
  float end_progress_ = Float::Min();

  std::unique_ptr<Interpolator> interpolator_;
  std::unique_ptr<Interpolator> x_interpolator_;
  std::unique_ptr<Interpolator> y_interpolator_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_KEYFRAME_KEYFRAME_MODEL_H_
