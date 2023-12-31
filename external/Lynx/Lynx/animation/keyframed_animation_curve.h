// Copyright 2021 The Lynx Authors. All rights reserved.
// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_ANIMATION_KEYFRAMED_ANIMATION_CURVE_H_
#define LYNX_ANIMATION_KEYFRAMED_ANIMATION_CURVE_H_

#include <memory>
#include <utility>
#include <vector>

#include "animation/animation_curve.h"
#include "animation/timing_function.h"
#include "css/css_property.h"
#include "starlight/types/nlength.h"
#include "third_party/fml/time/time_delta.h"
#if ENABLE_NEW_ANIMATOR_TRANSFORM
#include "transforms/transform_operations.h"
#endif

namespace lynx {
namespace animation {

fml::TimeDelta TransformedAnimationTime(
    const std::vector<std::unique_ptr<Keyframe>>& keyframes,
    const std::unique_ptr<TimingFunction>& timing_function,
    double scaled_duration, fml::TimeDelta time);

size_t GetActiveKeyframe(
    const std::vector<std::unique_ptr<Keyframe>>& keyframes,
    double scaled_duration, fml::TimeDelta time);

double TransformedKeyframeProgress(
    const std::vector<std::unique_ptr<Keyframe>>& keyframes,
    double scaled_duration, fml::TimeDelta time, size_t i);

tasm::CSSValue GetStyleInElement(tasm::CSSPropertyID id,
                                 tasm::Element* element);

//====Layout keyframe ====
class LayoutKeyframe : public Keyframe {
 public:
  static std::pair<starlight::NLength, tasm::CSSValue> GetLayoutKeyframeValue(
      LayoutKeyframe* keyframe, tasm::CSSPropertyID id, tasm::Element* element);
  static std::unique_ptr<LayoutKeyframe> Create(
      fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function);
  ~LayoutKeyframe() override = default;

  void SetLayout(starlight::NLength length) {
    value_ = length;
    is_empty_ = false;
  }

  bool SetValue(
      const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair,
      tasm::Element* element) override;

  const starlight::NLength& Value() const { return value_; }

  LayoutKeyframe(fml::TimeDelta time,
                 std::unique_ptr<TimingFunction> timing_function);

 private:
  starlight::NLength value_;
};
class KeyframedLayoutAnimationCurve : public LayoutAnimationCurve {
 public:
  static std::unique_ptr<KeyframedLayoutAnimationCurve> Create();
  ~KeyframedLayoutAnimationCurve() override = default;

  tasm::CSSValue GetValue(fml::TimeDelta& t) const override;
};

//====Opacity keyframe ====
class OpacityKeyframe : public Keyframe {
 public:
  constexpr static float kDefaultOpacity = 1.0f;
  static float GetOpacityKeyframeValue(OpacityKeyframe* keyframe,
                                       tasm::Element* element);

  static std::unique_ptr<OpacityKeyframe> Create(
      fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function);
  ~OpacityKeyframe() override = default;

  void SetOpacity(float opacity) {
    value_ = opacity;
    is_empty_ = false;
  }

  bool SetValue(
      const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair,
      tasm::Element* element) override;

  float Value() const { return value_; }

  OpacityKeyframe(fml::TimeDelta time,
                  std::unique_ptr<TimingFunction> timing_function);

 private:
  float value_{kDefaultOpacity};
};

class KeyframedOpacityAnimationCurve : public OpacityAnimationCurve {
 public:
  static std::unique_ptr<KeyframedOpacityAnimationCurve> Create();
  ~KeyframedOpacityAnimationCurve() override = default;

  tasm::CSSValue GetValue(fml::TimeDelta& t) const override;
};

//====Color keyframe ====
class ColorKeyframe : public Keyframe {
 public:
  constexpr static uint32_t kDefaultBackgroundColor = 0x0;
  constexpr static uint32_t kDefaultTextColor = 0xFF000000;
  static uint32_t GetColorKeyframeValue(ColorKeyframe*, tasm::CSSPropertyID id,
                                        tasm::Element*);
  static std::unique_ptr<ColorKeyframe> Create(
      fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function);
  ~ColorKeyframe() override = default;

  void SetColor(uint32_t color) {
    value_ = color;
    is_empty_ = false;
  }

  bool SetValue(
      const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair,
      tasm::Element* element) override;

  uint32_t Value() const { return value_; }

  ColorKeyframe(fml::TimeDelta time,
                std::unique_ptr<TimingFunction> timing_function);

 private:
  uint32_t value_{kDefaultBackgroundColor};
};
class KeyframedColorAnimationCurve : public ColorAnimationCurve {
 public:
  static std::unique_ptr<KeyframedColorAnimationCurve> Create();
  ~KeyframedColorAnimationCurve() override = default;

  tasm::CSSValue GetValue(fml::TimeDelta& t) const override;
};

#if ENABLE_NEW_ANIMATOR_TRANSFORM
//====Transform keyframe ====
class TransformKeyframe : public Keyframe {
 public:
  static std::unique_ptr<transforms::TransformOperations>
  GetTransformKeyframeValueInElement(tasm::Element*);
  static std::unique_ptr<TransformKeyframe> Create(
      fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function);
  ~TransformKeyframe() override = default;

  void SetTransform(
      std::unique_ptr<transforms::TransformOperations> transform) {
    value_ = std::move(transform);
    is_empty_ = false;
  }

  bool SetValue(
      const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair,
      tasm::Element* element) override;

  const std::unique_ptr<transforms::TransformOperations>& Value() const {
    return value_;
  };

  void NotifyElementSizeUpdated() override;

  TransformKeyframe(fml::TimeDelta time,
                    std::unique_ptr<TimingFunction> timing_function);

 private:
  std::unique_ptr<transforms::TransformOperations> value_;
};

class KeyframedTransformAnimationCurve : public TransformAnimationCurve {
 public:
  static std::unique_ptr<KeyframedTransformAnimationCurve> Create();
  ~KeyframedTransformAnimationCurve() override = default;

  tasm::CSSValue GetValue(fml::TimeDelta& t) const override;
};
#endif

}  // namespace animation
}  // namespace lynx
#endif  // LYNX_ANIMATION_KEYFRAMED_ANIMATION_CURVE_H_
