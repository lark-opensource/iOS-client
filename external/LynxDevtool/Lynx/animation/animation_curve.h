// Copyright 2021 The Lynx Authors. All rights reserved.
// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_ANIMATION_ANIMATION_CURVE_H_
#define LYNX_ANIMATION_ANIMATION_CURVE_H_

#include <memory>
#include <utility>
#include <vector>

#include "animation/timing_function.h"
#include "css/css_property.h"
#include "third_party/fml/time/time_delta.h"

namespace lynx {

namespace tasm {
class Element;
}

namespace animation {

class OpacityAnimationCurve;
class LayoutAnimationCurve;
class ColorAnimationCurve;
#if ENABLE_NEW_ANIMATOR_TRANSFORM
class TransformAnimationCurve;
#endif

class Keyframe {
 public:
  Keyframe(const Keyframe&) = delete;
  Keyframe& operator=(const Keyframe&) = delete;

  fml::TimeDelta Time() const;
  const TimingFunction* timing_function() const {
    return timing_function_.get();
  }

  bool IsEmpty() { return is_empty_; }

  virtual ~Keyframe() = default;

  virtual void NotifyElementSizeUpdated(){};

  virtual bool SetValue(
      const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair,
      tasm::Element* element) = 0;

 protected:
  bool is_empty_{true};

  Keyframe(fml::TimeDelta time,
           std::unique_ptr<TimingFunction> timing_function);

 private:
  fml::TimeDelta time_;
  std::unique_ptr<TimingFunction> timing_function_;
};

class AnimationCurve {
 public:
  enum class CurveType {
    UNSUPPORT = 0,
    LEFT = tasm::kPropertyIDLeft,
    RIGHT = tasm::kPropertyIDRight,
    TOP = tasm::kPropertyIDTop,
    BOTTOM = tasm::kPropertyIDBottom,
    WIDTH = tasm::kPropertyIDWidth,
    HEIGHT = tasm::kPropertyIDHeight,
    OPACITY = tasm::kPropertyIDOpacity,
    BGCOLOR = tasm::kPropertyIDBackgroundColor,
    TEXTCOLOR = tasm::kPropertyIDColor,
    TRANSFORM = tasm::kPropertyIDTransform
  };

  virtual ~AnimationCurve() = default;
  CurveType Type() const { return type_; }
  fml::TimeDelta Duration() const;

  AnimationCurve::CurveType type_;
  TimingFunction* timing_function() { return timing_function_.get(); }
  void SetTimingFunction(std::unique_ptr<TimingFunction> timing_function) {
    timing_function_ = std::move(timing_function);
  }
  double scaled_duration() const { return scaled_duration_; }
  void set_scaled_duration(double scaled_duration) {
    scaled_duration_ = scaled_duration;
  }
  size_t get_keyframes_size() { return keyframes_.size(); }
  void AddKeyframe(std::unique_ptr<Keyframe> keyframe);

  void SetElement(tasm::Element* element) { element_ = element; }

  void EnsureFromAndToKeyframe();

  void NotifyElementSizeUpdated();

  virtual std::unique_ptr<Keyframe> MakeEmptyKeyframe(
      const fml::TimeDelta& offset) = 0;

  virtual tasm::CSSValue GetValue(fml::TimeDelta& t) const = 0;

 protected:
  std::unique_ptr<TimingFunction> timing_function_;
  double scaled_duration_{1.0};
  std::vector<std::unique_ptr<Keyframe>> keyframes_;
  tasm::Element* element_{nullptr};
};

class LayoutAnimationCurve : public AnimationCurve {
 public:
  ~LayoutAnimationCurve() override = default;

  std::unique_ptr<Keyframe> MakeEmptyKeyframe(
      const fml::TimeDelta& offset) override;
};

class OpacityAnimationCurve : public AnimationCurve {
 public:
  ~OpacityAnimationCurve() override = default;

  std::unique_ptr<Keyframe> MakeEmptyKeyframe(
      const fml::TimeDelta& offset) override;
};

class ColorAnimationCurve : public AnimationCurve {
 public:
  ~ColorAnimationCurve() override = default;

  std::unique_ptr<Keyframe> MakeEmptyKeyframe(
      const fml::TimeDelta& offset) override;
};

#if ENABLE_NEW_ANIMATOR_TRANSFORM
class TransformAnimationCurve : public AnimationCurve {
 public:
  ~TransformAnimationCurve() override = default;

  std::unique_ptr<Keyframe> MakeEmptyKeyframe(
      const fml::TimeDelta& offset) override;
};
#endif
}  // namespace animation
}  // namespace lynx
#endif  // LYNX_ANIMATION_ANIMATION_CURVE_H_
