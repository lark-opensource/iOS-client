// Copyright 2021 The Lynx Authors. All rights reserved.

#include "animation/css_keyframe_manager.h"

#include <algorithm>
#include <queue>
#include <utility>
#include <vector>

#include "animation/animation.h"
#include "animation/animation_delegate.h"
#include "animation/keyframed_animation_curve.h"
#include "animation/timing_function.h"
#include "base/log/logging.h"
#include "css/css_keyframes_token.h"
#include "css/css_property.h"
#include "starlight/style/css_style_utils.h"
#include "starlight/style/css_type.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"
#include "timing_function.h"

namespace lynx {
namespace animation {
CSSKeyframeManager::CSSKeyframeManager(tasm::Element* element) {
  element_ = element;
}

KeyframeModel* CSSKeyframeManager::ConstructModel(
    std::unique_ptr<AnimationCurve> curve, AnimationCurve::CurveType type,
    Animation* animation) {
  curve->SetElement(element_);
  // add type here
  curve->type_ = type;
  curve->SetTimingFunction(
      TimingFunction::MakeTimingFunction(animation->animation_data()));
  curve->set_scaled_duration(animation->animation_data()->duration / 1000.0);
  std::unique_ptr<KeyframeModel> new_keyframe_model =
      KeyframeModel::Create(std::move(curve));
  new_keyframe_model->set_animation_data(animation->animation_data());
  KeyframeModel* keyframe_model = new_keyframe_model.get();
  animation->keyframe_effect()->AddKeyframeModel(std::move(new_keyframe_model));
  return keyframe_model;
}

bool CSSKeyframeManager::InitCurveAndModelAndKeyframe(
    AnimationCurve::CurveType type, Animation* animation, double offset,
    std::unique_ptr<TimingFunction> timing_function,
    std::pair<tasm::CSSPropertyID, tasm::CSSValue> css_value_pair) {
  KeyframeModel* keyframe_model =
      animation->keyframe_effect()->GetKeyframeModelByCurveType(type);
  bool has_model = (keyframe_model != nullptr);
  std::unique_ptr<AnimationCurve> new_curve;
  std::unique_ptr<Keyframe> keyframe;
  if (type == AnimationCurve::CurveType::LEFT ||
      type == AnimationCurve::CurveType::RIGHT ||
      type == AnimationCurve::CurveType::TOP ||
      type == AnimationCurve::CurveType::BOTTOM ||
      type == AnimationCurve::CurveType::HEIGHT ||
      type == AnimationCurve::CurveType::WIDTH) {
    if (!has_model) {
      new_curve = KeyframedLayoutAnimationCurve::Create();
    }
    keyframe = LayoutKeyframe::Create(fml::TimeDelta::FromSecondsF(offset),
                                      std::move(timing_function));
  } else if (type == AnimationCurve::CurveType::OPACITY) {
    if (!has_model) {
      new_curve = KeyframedOpacityAnimationCurve::Create();
    }
    keyframe = OpacityKeyframe::Create(fml::TimeDelta::FromSecondsF(offset),
                                       std::move(timing_function));
  } else if (type == AnimationCurve::CurveType::BGCOLOR ||
             type == AnimationCurve::CurveType::TEXTCOLOR) {
    if (!has_model) {
      new_curve = KeyframedColorAnimationCurve::Create();
    }
    keyframe = ColorKeyframe::Create(fml::TimeDelta::FromSecondsF(offset),
                                     std::move(timing_function));
  }
#if ENABLE_NEW_ANIMATOR_TRANSFORM
  else if (type == AnimationCurve::CurveType::TRANSFORM) {
    if (!has_model) {
      new_curve = KeyframedTransformAnimationCurve::Create();
    }
    keyframe = TransformKeyframe::Create(fml::TimeDelta::FromSecondsF(offset),
                                         std::move(timing_function));
  }
#endif
  else {
    return false;
  }
  // construct keyframe_model with AnimationCurve
  if (!has_model) {
    keyframe_model = ConstructModel(std::move(new_curve), type, animation);
  }
  // set css_value to keyframe
  if (!keyframe.get()->SetValue(css_value_pair, element_)) {
    return false;
  }
  // add keyframe into AnimationCurve
  keyframe_model->animation_curve()->AddKeyframe(std::move(keyframe));
  return true;
}

void CSSKeyframeManager::TickAllAnimation(fml::TimePoint& frame_time) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CSSKeyframeManager::TickAllAnimation");
  auto temp_queue = std::queue<std::weak_ptr<Animation>>();
  auto& true_queue = active_animations_;
  temp_queue.swap(true_queue);
  while (!temp_queue.empty()) {
    // Erase first because we're going to insert it in the Doframe.
    auto animation_shared_ptr = temp_queue.front().lock();
    temp_queue.pop();
    if (animation_shared_ptr != nullptr) {
      animation_shared_ptr->DoFrame(frame_time);
    }
  }
  // After traversing the set, the final_animator_maps_ is now assembled.
}

void CSSKeyframeManager::SetAnimationDataAndPlay(
    std::vector<starlight::AnimationData>& anim_data) {
  if (anim_data.size() == animation_data_.size() &&
      std::equal(anim_data.begin(), anim_data.end(), animation_data_.begin())) {
    return;
  }
  animation_data_ = anim_data;
  for (auto& data : animation_data_) {
    if (data.name.empty()) {
      continue;
    }
    // 1. Update data to the existing animation or create a new one, and
    // temporarily save them to temp_active_animations_map_.
    auto animation = animations_map_.find(data.name);
    if (animation != animations_map_.end()) {
      // Update an existing animation, add it to temp_active_animations_map_ and
      // delete it from animations_map_;
      animation->second->UpdateAnimationData(data);
      temp_active_animations_map_[data.name] = animation->second;
      animations_map_.erase(animation);
    } else {
      // Create a new animation, add it to temp_active_animations_map_;
      auto new_animation = CreateAnimation(data);
      temp_active_animations_map_[data.name] = new_animation;
    }
  }
  // 2. All animations remaining in animations_map_ need to be destroyed.
  for (auto& ani_iter : animations_map_) {
    ani_iter.second->Destroy();
  }

  for (auto& active_ani_iter : temp_active_animations_map_) {
    if (active_ani_iter.second->animation_data()->play_state ==
        starlight::AnimationPlayStateType::kPaused) {
      active_ani_iter.second->Pause();
    } else {
      active_ani_iter.second->Play();
    }
  }
  // 3. Swap active animations to animations_map_.
  animations_map_.swap(temp_active_animations_map_);
  temp_active_animations_map_.clear();
}

std::shared_ptr<Animation> CSSKeyframeManager::CreateAnimation(
    starlight::AnimationData& data) {
  // 1. create animation & keyframe_effect according to animation data
  auto animation = std::make_shared<Animation>(data.name.str());
  animation->set_animation_data(data);

  std::unique_ptr<KeyframeEffect> keyframe_effect = KeyframeEffect::Create();
  keyframe_effect->BindAnimationDelegate(this);
  keyframe_effect->BindElement(this->element());
  animation->SetKeyframeEffect(std::move(keyframe_effect));
  animation->BindDelegate(this);
  animation->BindElement(this->element());
  // 2. create keyframe Models& animation Curves according to CSS keyframe
  // tokens
  MakeKeyframeModel(animation.get(), data.name.str());
  return animation;
}

tasm::CSSKeyframesMap& CSSKeyframeManager::GetKeyframesStyleMap(
    const std::string& animation_name) {
  DCHECK(element() != nullptr);
  auto iter = element()->keyframes_map_.find(animation_name);
  if (iter != element()->keyframes_map_.end()) {
    return iter->second->GetKeyframes();
  }
  tasm::CSSKeyframesToken* tokens =
      element()->GetCSSKeyframesToken(animation_name);
  if (tokens) {
    return tokens->GetKeyframes();
  }
  return empty_keyframe_map();
}

void CSSKeyframeManager::MakeKeyframeModel(Animation* animation,
                                           const std::string& animation_name) {
  const auto& keyframes_map = GetKeyframesStyleMap(animation_name);
  for (const auto& keyframe_info : keyframes_map) {
    double offset = keyframe_info.first;
    tasm::StyleMap* style_map = keyframe_info.second.get();
    if (!style_map) {
      continue;
    }
    std::unique_ptr<TimingFunction> timing_function = nullptr;
    starlight::TimingFunctionData timing_function_for_keyframe;
    const auto& iter =
        style_map->find(tasm::kPropertyIDAnimationTimingFunction);
    if (iter != style_map->end()) {
      auto timing_function_value =
          iter->second.GetValue().Array().Get()->get(0);
      starlight::CSSStyleUtils::ComputeTimingFunction(
          timing_function_value, false, timing_function_for_keyframe,
          element_->element_manager()->GetCSSParserConfigs());
    }
    for (const auto& css_value_pair : *style_map) {
      if (css_value_pair.first == tasm::kPropertyIDAnimationTimingFunction) {
        continue;
      }
      timing_function =
          TimingFunction::MakeTimingFunction(timing_function_for_keyframe);
      AnimationCurve::CurveType curve_type =
          static_cast<AnimationCurve::CurveType>(css_value_pair.first);
      if (GetPropertyIDToAnimationPropertyTypeMap().find(
              css_value_pair.first) ==
          GetPropertyIDToAnimationPropertyTypeMap().end()) {
        LOGE("[animation] unsupported animation curve type for css:"
             << css_value_pair.first);
        continue;
      }
      bool init_status = InitCurveAndModelAndKeyframe(
          curve_type, animation, offset, std::move(timing_function),
          css_value_pair);
      if (!init_status) {
        continue;
      }
      animation->SetRawCssId(css_value_pair.first);
    }
  }
  // There may be no from(0%) and to(100%) keyframe. If so, we add a empty one.
  animation->keyframe_effect()->EnsureFromAndToKeyframe();
}

void CSSKeyframeManager::RequestNextFrame(std::weak_ptr<Animation> ptr) {
  active_animations_.push(ptr);
  element_->RequestNextFrameTime();
}

void CSSKeyframeManager::UpdateFinalStyleMap(const tasm::StyleMap& styles) {
  element()->UpdateFinalStyleMap(styles);
}

void CSSKeyframeManager::NotifyClientAnimated(tasm::StyleMap& styles,
                                              tasm::CSSValue value,
                                              tasm::CSSPropertyID css_id) {
  if (!element_) {
    return;
  }
  switch (css_id) {
    case tasm::kPropertyIDTransform: {
      // If the transform value is empty, we use transform default value to fit
      // the CSS parsing logic.
      if (value.IsEmpty() ||
          (value.IsArray() && value.GetValue().Array()->size() == 0)) {
        value = GetDefaultValue(starlight::AnimationPropertyType::kTransform);
      }
      break;
    }
    case tasm::kPropertyIDOpacity: {
      if (value.IsNumber() && value.GetValue().Number() < 0.0f) {
        return;
      }
      break;
    }
    default: {
      break;
    }
  }
  styles[css_id] = value;
}

void CSSKeyframeManager::SetNeedsAnimationStyleRecalc(const std::string& name) {
  // clear effect
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "CSSKeyframeManager::SetNeedsAnimationStyleRecalc");
  if (element_) {
    auto iter = animations_map_.find(name);
    if (iter == animations_map_.end()) {
      iter = temp_active_animations_map_.find(name);
    }
    auto animation = iter->second;
    if (animation) {
      tasm::StyleMap reset_origin_css_styles;
      auto& raw_style_set = animation->GetRawStyleSet();
      for (tasm::CSSPropertyID key : raw_style_set) {
        std::optional<tasm::CSSValue> value_opt =
            element_->GetElementStyle(key);
        if (!value_opt) {
          reset_origin_css_styles[key] = tasm::CSSValue::Empty();
        } else {
          reset_origin_css_styles[key] = std::move(*value_opt);
        }
      }
      element()->UpdateFinalStyleMap(reset_origin_css_styles);
    }
  }
}

void CSSKeyframeManager::FlushAnimatedStyle() {
  element()->FlushAnimatedStyle();
}

const starlight::CssMeasureContext& CSSKeyframeManager::GetLengthContext(
    tasm::Element* element) {
  if (!element || !element->computed_css_style()) {
    static base::NoDestructor<starlight::CssMeasureContext>
        sDefaultLengthContext(
            0.f, starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX,
            starlight::ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT,
            lynx::tasm::Config::DefaultFontSize(),
            lynx::tasm::Config::DefaultFontSize(), starlight::LayoutUnit(),
            starlight::LayoutUnit());
    return *sDefaultLengthContext;
  }
  return element->computed_css_style()->GetMeasureContext();
}

tasm::CSSValue CSSKeyframeManager::GetDefaultValue(
    starlight::AnimationPropertyType type) {
  if (static_cast<unsigned int>(type) &
      static_cast<unsigned int>(starlight::AnimationPropertyType::kLayout)) {
    // the default values of layout properties are 'auto'.
    return tasm::CSSValue::Empty();
  } else if (type == starlight::AnimationPropertyType::kOpacity) {
    return tasm::CSSValue(lepus_value(OpacityKeyframe::kDefaultOpacity),
                          tasm::CSSValuePattern::NUMBER);
  } else if (type == starlight::AnimationPropertyType::kBackgroundColor) {
    return tasm::CSSValue(lepus_value(ColorKeyframe::kDefaultBackgroundColor),
                          tasm::CSSValuePattern::NUMBER);
  } else if (type == starlight::AnimationPropertyType::kColor) {
    return tasm::CSSValue(lepus_value(ColorKeyframe::kDefaultTextColor),
                          tasm::CSSValuePattern::NUMBER);
  } else if (type == starlight::AnimationPropertyType::kTransform) {
    // There are many kinds of identity transforms, we choose one(rotateZ 0
    // degree) of them.
    auto items = lepus::CArray::Create();
    auto item = lepus::CArray::Create();
    item->push_back(
        lepus::Value(static_cast<int>(starlight::TransformType::kRotateZ)));
    item->push_back(lepus::Value(0.0f));
    items->push_back(lepus::Value(item));
    return tasm::CSSValue(lepus_value(items), tasm::CSSValuePattern::ARRAY);
  }
  return tasm::CSSValue::Empty();
}

// TODO:(wujintian) Remove AnimationPropertyType, it is redundant code. Only use
// AnimationCurve::CurveType and tasm::kPropertyIDxxx in animation code.
const std::unordered_map<tasm::CSSPropertyID, starlight::AnimationPropertyType>&
GetPropertyIDToAnimationPropertyTypeMap() {
  static const base::NoDestructor<
      std::unordered_map<tasm::CSSPropertyID, starlight::AnimationPropertyType>>
      kIDPropertyMap({
        {tasm::kPropertyIDLeft, starlight::AnimationPropertyType::kLeft},
            {tasm::kPropertyIDTop, starlight::AnimationPropertyType::kTop},
            {tasm::kPropertyIDRight, starlight::AnimationPropertyType::kRight},
            {tasm::kPropertyIDBottom,
             starlight::AnimationPropertyType::kBottom},
            {tasm::kPropertyIDWidth, starlight::AnimationPropertyType::kWidth},
            {tasm::kPropertyIDHeight,
             starlight::AnimationPropertyType::kHeight},

            {tasm::kPropertyIDOpacity,
             starlight::AnimationPropertyType::kOpacity},
            {tasm::kPropertyIDBackgroundColor,
             starlight::AnimationPropertyType::kBackgroundColor},
            {tasm::kPropertyIDColor, starlight::AnimationPropertyType::kColor},
#if ENABLE_NEW_ANIMATOR_TRANSFORM
            {tasm::kPropertyIDTransform,
             starlight::AnimationPropertyType::kTransform},
#endif
      });
  return *kIDPropertyMap;
}

void CSSKeyframeManager::NotifyElementSizeUpdated() {
  for (auto& item : animations_map_) {
    item.second->NotifyElementSizeUpdated();
  }
}

bool IsAnimatableProperty(tasm::CSSPropertyID css_id) {
  if ((css_id >= tasm::kPropertyIDTop && css_id <= tasm::kPropertyIDBottom) ||
      css_id == tasm::kPropertyIDHeight || css_id == tasm::kPropertyIDWidth ||
      css_id == tasm::kPropertyIDBackgroundColor ||
      css_id == tasm::kPropertyIDOpacity ||
      css_id == tasm::kPropertyIDTransform ||
      css_id == tasm::kPropertyIDColor) {
    return true;
  }
  return false;
}

}  // namespace animation
}  // namespace lynx
