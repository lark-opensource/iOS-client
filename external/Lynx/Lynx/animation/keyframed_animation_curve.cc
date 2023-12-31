// Copyright 2021 The Lynx Authors. All rights reserved.
// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "animation/keyframed_animation_curve.h"

#include "base/log/logging.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace animation {

// keyframe
fml::TimeDelta Keyframe::Time() const { return time_; }

Keyframe::Keyframe(fml::TimeDelta time,
                   std::unique_ptr<TimingFunction> timing_function)
    : time_(time), timing_function_(std::move(timing_function)) {}

fml::TimeDelta TransformedAnimationTime(
    const std::vector<std::unique_ptr<Keyframe>>& keyframes,
    const std::unique_ptr<TimingFunction>& timing_function,
    double scaled_duration, fml::TimeDelta time) {
  if (timing_function) {
    fml::TimeDelta start_time = keyframes.front()->Time() * scaled_duration;
    fml::TimeDelta duration =
        (keyframes.back()->Time() - keyframes.front()->Time()) *
        scaled_duration;
    double progress = static_cast<double>(time.ToMicroseconds() -
                                          start_time.ToMicroseconds()) /
                      static_cast<double>(duration.ToMicroseconds());

    time = (duration * timing_function->GetValue(progress)) + start_time;
  }

  return time;
}

size_t GetActiveKeyframe(
    const std::vector<std::unique_ptr<Keyframe>>& keyframes,
    double scaled_duration, fml::TimeDelta time) {
  DCHECK(keyframes.size() >= 2);
  size_t i = 0;
  for (; i < keyframes.size() - 2; ++i) {  // Last keyframe is never active.
    if (time < (keyframes[i + 1]->Time() * scaled_duration)) break;
  }

  return i;
}

double TransformedKeyframeProgress(
    const std::vector<std::unique_ptr<Keyframe>>& keyframes,
    double scaled_duration, fml::TimeDelta time, size_t i) {
  double in_time = time.ToNanosecondsF();
  double time1 = keyframes[i]->Time().ToNanosecondsF() * scaled_duration;
  double time2 = keyframes[i + 1]->Time().ToNanosecondsF() * scaled_duration;

  double progress = (in_time - time1) / (time2 - time1);

  if (keyframes[i]->timing_function()) {
    progress = keyframes[i]->timing_function()->GetValue(progress);
  }

  return progress;
}

tasm::CSSValue GetStyleInElement(tasm::CSSPropertyID id,
                                 tasm::Element* element) {
  std::optional<tasm::CSSValue> value_opt = element->GetElementStyle(id);
  if (!value_opt) {
    return tasm::CSSValue::Empty();
  }
  return std::move(*value_opt);
}

//====== LayoutValueAnimator begin =======

std::unique_ptr<LayoutKeyframe> LayoutKeyframe::Create(
    fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function) {
  return std::make_unique<LayoutKeyframe>(time, std::move(timing_function));
}

LayoutKeyframe::LayoutKeyframe(fml::TimeDelta time,
                               std::unique_ptr<TimingFunction> timing_function)
    : Keyframe(time, std::move(timing_function)),
      value_(starlight::NLength::MakeAutoNLength()) {}

std::pair<starlight::NLength, tasm::CSSValue>
LayoutKeyframe::GetLayoutKeyframeValue(LayoutKeyframe* keyframe,
                                       tasm::CSSPropertyID id,
                                       tasm::Element* element) {
  // Layout length default value : auto
  starlight::NLength length = starlight::NLength::MakeAutoNLength();
  tasm::CSSValue css_value = tasm::CSSValue(
      lepus::Value(static_cast<int>(starlight::LengthValueType::kAuto)),
      tasm::CSSValuePattern::ENUM);
  if (keyframe->IsEmpty()) {
    std::optional<tasm::CSSValue> value_opt = element->GetElementStyle(id);
    if (!value_opt) {
      // return default value
      return std::make_pair(length, css_value);
    }
    const auto& configs = element->element_manager()->GetCSSParserConfigs();
    auto parse_result = starlight::CSSStyleUtils::ToLength(
        *value_opt, CSSKeyframeManager::GetLengthContext(element), configs);
    length = parse_result.first;
    css_value = std::move(*value_opt);
  } else {
    length = keyframe->Value();
  }
  return std::make_pair(length, css_value);
}

bool LayoutKeyframe::SetValue(
    const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair,
    tasm::Element* element) {
  auto parse_result = starlight::CSSStyleUtils::ToLength(
      css_value_pair.second, CSSKeyframeManager::GetLengthContext(element),
      element->element_manager()->GetCSSParserConfigs());

  if (!parse_result.second) {
    return false;
  }
  // TODO(wangyifei.20010605): Support percent and calc
  if (!parse_result.first.IsUnit() && !parse_result.first.IsPercent()) {
    return false;
  }
  value_ = parse_result.first;
  is_empty_ = false;
  return true;
}

std::unique_ptr<KeyframedLayoutAnimationCurve>
KeyframedLayoutAnimationCurve::Create() {
  return std::make_unique<KeyframedLayoutAnimationCurve>();
}

tasm::CSSValue KeyframedLayoutAnimationCurve::GetValue(
    fml::TimeDelta& t) const {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Animation_curve::GetValue");
  t = TransformedAnimationTime(keyframes_, timing_function_, scaled_duration(),
                               t);
  size_t i = GetActiveKeyframe(keyframes_, scaled_duration(), t);
  double progress =
      TransformedKeyframeProgress(keyframes_, scaled_duration(), t, i);

  LayoutKeyframe* keyframe =
      reinterpret_cast<LayoutKeyframe*>(keyframes_[i].get());
  LayoutKeyframe* keyframe_next =
      reinterpret_cast<LayoutKeyframe*>(keyframes_[i + 1].get());

  auto start_result = LayoutKeyframe::GetLayoutKeyframeValue(
      keyframe, static_cast<tasm::CSSPropertyID>(Type()), element_);
  starlight::NLength start_len = start_result.first;
  if (!start_len.IsUnit() && !start_len.IsPercent()) {
    return start_result.second;
  }

  auto end_result = LayoutKeyframe::GetLayoutKeyframeValue(
      keyframe_next, static_cast<tasm::CSSPropertyID>(Type()), element_);
  starlight::NLength end_len = end_result.first;
  if (!end_len.IsUnit() && !end_len.IsPercent()) {
    return tasm::CSSValue(lepus::Value(start_len.GetRawValue()),
                          start_len.IsUnit() ? tasm::CSSValuePattern::NUMBER
                                             : tasm::CSSValuePattern::PERCENT);
  }

  float start_value = 0.0f;
  float end_value = 0.0f;
  tasm::CSSValuePattern pattern = tasm::CSSValuePattern::NUMBER;
  if ((start_len.IsUnit() && end_len.IsPercent()) ||
      (start_len.IsPercent() && end_len.IsUnit())) {
    if (!element_ || !element_->parent()) {
      return tasm::CSSValue(lepus::Value(start_len.GetRawValue()),
                            start_len.IsUnit()
                                ? tasm::CSSValuePattern::NUMBER
                                : tasm::CSSValuePattern::PERCENT);
    }

    float parent_length = 0;
    if (Type() == AnimationCurve::CurveType::LEFT ||
        Type() == AnimationCurve::CurveType::RIGHT ||
        Type() == AnimationCurve::CurveType::WIDTH) {
      parent_length = element_->parent()->width();
    } else {
      parent_length = element_->parent()->height();
    }
    start_value = starlight::NLengthToLayoutUnit(
                      start_len, starlight::LayoutUnit(parent_length))
                      .ToFloat();
    end_value = starlight::NLengthToLayoutUnit(
                    end_len, starlight::LayoutUnit(parent_length))
                    .ToFloat();
    pattern = tasm::CSSValuePattern::NUMBER;
  } else {
    start_value = start_len.GetRawValue();
    end_value = end_len.GetRawValue();
    pattern = start_len.IsUnit() ? tasm::CSSValuePattern::NUMBER
                                 : tasm::CSSValuePattern::PERCENT;
  }

  float new_result = start_value + (end_value - start_value) * progress;

  return tasm::CSSValue(lepus::Value(new_result), pattern);
}

//====== LayoutValueAnimator end =======

//====== OpacityValueAnimator begin =======
std::unique_ptr<OpacityKeyframe> OpacityKeyframe::Create(
    fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function) {
  return std::make_unique<OpacityKeyframe>(time, std::move(timing_function));
}

OpacityKeyframe::OpacityKeyframe(
    fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function)
    : Keyframe(time, std::move(timing_function)) {}

float OpacityKeyframe::GetOpacityKeyframeValue(OpacityKeyframe* keyframe,
                                               tasm::Element* element) {
  float value = OpacityKeyframe::kDefaultOpacity;
  if (keyframe->IsEmpty()) {
    tasm::CSSValue opacity =
        GetStyleInElement(tasm::kPropertyIDOpacity, element);
    if (opacity.IsNumber()) {
      value = static_cast<float>(opacity.AsNumber());
    }
  } else {
    value = static_cast<float>(keyframe->Value());
  }
  return value;
}

bool OpacityKeyframe::SetValue(
    const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair,
    tasm::Element* element) {
  if (!css_value_pair.second.IsNumber()) {
    return false;
  }
  value_ = css_value_pair.second.GetValue().Number();
  is_empty_ = false;
  return true;
}

std::unique_ptr<KeyframedOpacityAnimationCurve>
KeyframedOpacityAnimationCurve::Create() {
  return std::make_unique<KeyframedOpacityAnimationCurve>();
}

tasm::CSSValue KeyframedOpacityAnimationCurve::GetValue(
    fml::TimeDelta& t) const {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Animation_curve::GetValue");
  t = TransformedAnimationTime(keyframes_, timing_function_, scaled_duration(),
                               t);
  size_t i = GetActiveKeyframe(keyframes_, scaled_duration(), t);
  double progress =
      TransformedKeyframeProgress(keyframes_, scaled_duration(), t, i);

  OpacityKeyframe* keyframe =
      reinterpret_cast<OpacityKeyframe*>(keyframes_[i].get());
  OpacityKeyframe* keyframe_next =
      reinterpret_cast<OpacityKeyframe*>(keyframes_[i + 1].get());

  float start_opacity =
      OpacityKeyframe::GetOpacityKeyframeValue(keyframe, element_);
  float end_opacity =
      OpacityKeyframe::GetOpacityKeyframeValue(keyframe_next, element_);
  float result_value = start_opacity + (end_opacity - start_opacity) * progress;
  return tasm::CSSValue(lepus_value(result_value),
                        tasm::CSSValuePattern::NUMBER);
}

//====== OpacityValueAnimator end =======

//====== ColorValueAnimator begin =======
std::unique_ptr<ColorKeyframe> ColorKeyframe::Create(
    fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function) {
  return std::make_unique<ColorKeyframe>(time, std::move(timing_function));
}

ColorKeyframe::ColorKeyframe(fml::TimeDelta time,
                             std::unique_ptr<TimingFunction> timing_function)
    : Keyframe(time, std::move(timing_function)) {}

uint32_t ColorKeyframe::GetColorKeyframeValue(ColorKeyframe* keyframe,
                                              tasm::CSSPropertyID id,
                                              tasm::Element* element) {
  uint32_t value = (id == tasm::kPropertyIDBackgroundColor)
                       ? ColorKeyframe::kDefaultBackgroundColor
                       : ColorKeyframe::kDefaultTextColor;
  if (keyframe->IsEmpty()) {
    tasm::CSSValue color = GetStyleInElement(id, element);
    if (color.IsNumber()) {
      value = static_cast<uint32_t>(color.AsNumber());
    }
  } else {
    value = static_cast<uint32_t>(keyframe->Value());
  }
  return value;
}

bool ColorKeyframe::SetValue(
    const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair,
    tasm::Element* element) {
  if (!css_value_pair.second.IsNumber()) {
    return false;
  }
  value_ = css_value_pair.second.GetValue().Number();
  is_empty_ = false;
  return true;
}

std::unique_ptr<KeyframedColorAnimationCurve>
KeyframedColorAnimationCurve::Create() {
  return std::make_unique<KeyframedColorAnimationCurve>();
}

tasm::CSSValue KeyframedColorAnimationCurve::GetValue(fml::TimeDelta& t) const {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Animation_curve::GetValue");
  t = TransformedAnimationTime(keyframes_, timing_function_, scaled_duration(),
                               t);
  size_t i = GetActiveKeyframe(keyframes_, scaled_duration(), t);
  double progress =
      TransformedKeyframeProgress(keyframes_, scaled_duration(), t, i);

  ColorKeyframe* keyframe =
      reinterpret_cast<ColorKeyframe*>(keyframes_[i].get());
  ColorKeyframe* keyframe_next =
      reinterpret_cast<ColorKeyframe*>(keyframes_[i + 1].get());

  uint32_t start_color = ColorKeyframe::GetColorKeyframeValue(
      keyframe, static_cast<tasm::CSSPropertyID>(Type()), element_);
  uint32_t end_color = ColorKeyframe::GetColorKeyframeValue(
      keyframe_next, static_cast<tasm::CSSPropertyID>(Type()), element_);

  float startA = ((start_color >> 24) & 0xff) / 255.0f;
  float startR = ((start_color >> 16) & 0xff) / 255.0f;
  float startG = ((start_color >> 8) & 0xff) / 255.0f;
  float startB = ((start_color)&0xff) / 255.0f;

  float endA = ((end_color >> 24) & 0xff) / 255.0f;
  float endR = ((end_color >> 16) & 0xff) / 255.0f;
  float endG = ((end_color >> 8) & 0xff) / 255.0f;
  float endB = ((end_color)&0xff) / 255.0f;

  // convert RGB to linear
  startR = static_cast<float>(pow(startR, 2.2));
  startG = static_cast<float>(pow(startG, 2.2));
  startB = static_cast<float>(pow(startB, 2.2));

  endR = static_cast<float>(pow(endR, 2.2));
  endG = static_cast<float>(pow(endG, 2.2));
  endB = static_cast<float>(pow(endB, 2.2));

  // compute the interpolated color in linear space
  float a = startA + progress * (endA - startA);
  float b = startB + progress * (endB - startB);
  float r = startR + progress * (endR - startR);
  float g = startG + progress * (endG - startG);

  // convert back to RGB to [0,255] range
  a = a * 255.0f;
  r = static_cast<float>(pow(r, 1.0 / 2.2)) * 255.0f;
  g = static_cast<float>(pow(g, 1.0 / 2.2)) * 255.0f;
  b = static_cast<float>(pow(b, 1.0 / 2.2)) * 255.0f;
  uint32_t result_value = static_cast<uint32_t>(round(a)) << 24 |
                          static_cast<uint32_t>(round(r)) << 16 |
                          static_cast<uint32_t>(round(g)) << 8 |
                          static_cast<uint32_t>(round(b));
  return tasm::CSSValue(lepus_value(result_value),
                        tasm::CSSValuePattern::NUMBER);
}

//====== ColorValueAnimator end =======
#if ENABLE_NEW_ANIMATOR_TRANSFORM
//====== TransformValueAnimator begin =======
std::unique_ptr<TransformKeyframe> TransformKeyframe::Create(
    fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function) {
  return std::make_unique<TransformKeyframe>(time, std::move(timing_function));
}

TransformKeyframe::TransformKeyframe(
    fml::TimeDelta time, std::unique_ptr<TimingFunction> timing_function)
    : Keyframe(time, std::move(timing_function)) {}

void TransformKeyframe::NotifyElementSizeUpdated() {
  if (value_) {
    value_->NotifyElementSizeUpdated();
  }
}

std::unique_ptr<transforms::TransformOperations>
TransformKeyframe::GetTransformKeyframeValueInElement(tasm::Element* element) {
  tasm::CSSValue transform =
      GetStyleInElement(tasm::kPropertyIDTransform, element);
  if (transform.IsArray()) {
    return std::make_unique<transforms::TransformOperations>(element,
                                                             transform);
  } else {
    return std::make_unique<transforms::TransformOperations>(element);
  }
}

bool TransformKeyframe::SetValue(
    const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair,
    tasm::Element* element) {
  if (!css_value_pair.second.IsArray()) {
    return false;
  }
  auto transform = std::make_unique<transforms::TransformOperations>(
      element, css_value_pair.second);
  value_ = std::move(transform);
  is_empty_ = false;
  return true;
}

std::unique_ptr<KeyframedTransformAnimationCurve>
KeyframedTransformAnimationCurve::Create() {
  return std::make_unique<KeyframedTransformAnimationCurve>();
}

// Using for getting the corresponding transform style value based on the local
// time passed in. The local time is converted from monotonic time of VSYNC.
//
// Details: This method get the active keyframe based on the local time passed
// in firstly. Then it gets the progress between the active keyframe and the
// next one. It gets the start transform value from the active keyframe and the
// end transform value from the keyframe next to the active keyframe. If the
// keyframe is empty, use the transform value in element instead. Finally, blend
// the start transform and end transform based on the progress, and return the
// blend result as the real time style of animation.
tasm::CSSValue KeyframedTransformAnimationCurve::GetValue(
    fml::TimeDelta& t) const {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Animation_curve::GetValue");
  t = TransformedAnimationTime(keyframes_, timing_function_, scaled_duration(),
                               t);
  size_t i = GetActiveKeyframe(keyframes_, scaled_duration(), t);
  double progress =
      TransformedKeyframeProgress(keyframes_, scaled_duration(), t, i);

  TransformKeyframe* keyframe =
      reinterpret_cast<TransformKeyframe*>(keyframes_[i].get());
  TransformKeyframe* keyframe_next =
      reinterpret_cast<TransformKeyframe*>(keyframes_[i + 1].get());

  std::unique_ptr<transforms::TransformOperations> transform_in_element;
  if (keyframe->IsEmpty() || keyframe_next->IsEmpty()) {
    transform_in_element =
        TransformKeyframe::GetTransformKeyframeValueInElement(element_);
  }
  transforms::TransformOperations& start_transform =
      keyframe->IsEmpty() ? *transform_in_element : *keyframe->Value();
  transforms::TransformOperations& end_transform =
      keyframe_next->IsEmpty() ? *transform_in_element
                               : *keyframe_next->Value();
  transforms::TransformOperations blended_result =
      end_transform.Blend(start_transform, progress);
  return blended_result.ToTransformRawValue();
}

//====== TransformValueAnimator end =======
#endif
}  // namespace animation
}  // namespace lynx
