// Copyright 2022 The Lynx Authors. All rights reserved.

#include "animation/css_transition_manager.h"

#include <utility>

#include "animation/keyframed_animation_curve.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace animation {

std::string ConvertAnimationPropertyTypeToString(
    lynx::starlight::AnimationPropertyType type) {
  switch (type) {
    case starlight::AnimationPropertyType::kNone:
      return "none";
    case starlight::AnimationPropertyType::kOpacity:
      return "opacity";
    case starlight::AnimationPropertyType::kScaleX:
      return "scaleX";
    case starlight::AnimationPropertyType::kScaleY:
      return "scaleY";
    case starlight::AnimationPropertyType::kScaleXY:
      return "scaleXY";
    case starlight::AnimationPropertyType::kWidth:
      return "width";
    case starlight::AnimationPropertyType::kHeight:
      return "height";
    case starlight::AnimationPropertyType::kBackgroundColor:
      return "background-color";
    case starlight::AnimationPropertyType::kColor:
      return "color";
    case starlight::AnimationPropertyType::kVisibility:
      return "visibility";
    case starlight::AnimationPropertyType::kLeft:
      return "left";
    case starlight::AnimationPropertyType::kTop:
      return "top";
    case starlight::AnimationPropertyType::kRight:
      return "right";
    case starlight::AnimationPropertyType::kBottom:
      return "bottom";
    case starlight::AnimationPropertyType::kTransform:
      return "transform";
    case starlight::AnimationPropertyType::kLayout:
      return "layout";
    case starlight::AnimationPropertyType::kAll:
      return "all";
  }
}

void CSSTransitionManager::setTransitionData(
    std::vector<starlight::TransitionData>& transition_data) {
  transition_data_.clear();
  property_type_value_ = 0;
  std::unordered_map<lepus::String, std::shared_ptr<Animation>>
      active_animations_map;
  for (const auto& data : transition_data) {
    if (data.property == starlight::AnimationPropertyType::kAll) {
      starlight::TransitionData temp_data(data);
      const auto& transition_props_map =
          GetPropertyIDToAnimationPropertyTypeMap();
      for (const auto& iterator : transition_props_map) {
        temp_data.property = iterator.second;
        SetTransitionDataInternal(temp_data, active_animations_map);
      }
    } else {
      SetTransitionDataInternal(data, active_animations_map);
    }
  }

  // 3. All animations remaining in animations_map_ need to be destroyed.
  for (auto& animation_iterator : animations_map_) {
    animation_iterator.second->Destroy();
  }
  // 4. Swap active animations to animations_map_.
  animations_map_.swap(active_animations_map);
}

void CSSTransitionManager::SetTransitionDataInternal(
    const starlight::TransitionData& data,
    std::unordered_map<lepus::String, std::shared_ptr<Animation>>&
        active_animations_map) {
  // 1. Constructor animation_data according to transition_data
  property_type_value_ =
      property_type_value_
          ? (property_type_value_ | static_cast<unsigned int>(data.property))
          : static_cast<unsigned int>(data.property);

  starlight::AnimationData animation_data;
  animation_data.name = ConvertAnimationPropertyTypeToString(data.property);
  animation_data.duration = data.duration;
  animation_data.delay = data.delay;
  animation_data.timing_func = data.timing_func;
  animation_data.iteration_count = 1;
  animation_data.fill_mode = starlight::AnimationFillModeType::kForwards;
  animation_data.direction = starlight::AnimationDirectionType::kNormal;
  animation_data.play_state = starlight::AnimationPlayStateType::kRunning;

  transition_data_[static_cast<unsigned int>(data.property)] = animation_data;

  // 2. Update data to the existing animation, and temporarily save them to
  // active_animations_map.
  auto animation = animations_map_.find(animation_data.name);
  if (animation != animations_map_.end()) {
    // Add it to active_animations_map and delete it from animations_map_;
    // Unlike keyframes, transitions do not require updating the animation
    // parameter of existing animator.
    active_animations_map[animation_data.name] = animation->second;
    animations_map_.erase(animation);
  }
}

bool CSSTransitionManager::ConsumeCSSProperty(tasm::CSSPropertyID css_id,
                                              const tasm::CSSValue& end_value) {
  starlight::AnimationPropertyType property_type =
      GetAnimationPropertyType(css_id);
  if (static_cast<unsigned int>(property_type) & property_type_value_) {
    // 1. get transition start value and end value
    tasm::CSSKeyframesMap map;
    tasm::CSSValue start_value_internal;
    tasm::CSSValue end_value_internal;
    std::optional<tasm::CSSValue> start_value_opt =
        element()->GetElementPreviousStyle(css_id);
    if (!start_value_opt || start_value_opt->IsEmpty()) {
      // If the start value is empty, we should give it a default value rather
      // than return directly.
      start_value_internal = GetDefaultValue(property_type);
    } else {
      start_value_internal = std::move(*start_value_opt);
    }

    if (end_value.IsEmpty()) {
      // If the end value is empty, we should give it a default value rather
      // than return directly.
      end_value_internal = GetDefaultValue(property_type);
    } else {
      end_value_internal = end_value;
    }
    const auto& configs = element()->element_manager()->GetCSSParserConfigs();
    if (!IsValueValid(property_type, start_value_internal, configs) ||
        !IsValueValid(property_type, end_value_internal, configs)) {
      TryToStopTransitionAnimator(property_type);
      return false;
    }

    // 2. construct keyframes Map
    auto start_shared_style_map = std::make_shared<tasm::StyleMap>();
    start_shared_style_map->insert({css_id, start_value_internal});

    auto end_shared_style_map = std::make_shared<tasm::StyleMap>();
    end_shared_style_map->insert({css_id, end_value_internal});

    tasm::CSSKeyframesMap keyframe_map;
    keyframe_map.insert({0, start_shared_style_map});  // begin keyframe
    keyframe_map.insert({1, end_shared_style_map});    // end keyframe

    keyframe_tokens_[ConvertAnimationPropertyTypeToString(property_type)] =
        keyframe_map;

    // 3. create transition animation and play
    const auto& data =
        transition_data_.find(static_cast<unsigned int>(property_type));
    if (data != transition_data_.end()) {
      if (animations_map_.count(data->second.name)) {
        // If a transition animation is replaced by another identical transition
        // animation (both animate the same properties), then this transition
        // animation does not require clearing effect and applying the end
        // effect.
        animations_map_[data->second.name]->Destroy(false);
      }
      std::shared_ptr<Animation> animation = CreateAnimation(data->second);
      animation->BindDelegate(this);
      animation->SetTransitionFlag();
      animation->Play();
      animations_map_[data->second.name] = animation;
      return true;
    }
  }
  return false;
}

void CSSTransitionManager::TickAllAnimation(fml::TimePoint& frame_time) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CSSTransitionManager::TickAllAnimation");
  CSSKeyframeManager::TickAllAnimation(frame_time);
  // After traversing the set, the final_animator_maps_ is now assembled.
}

tasm::CSSKeyframesMap& CSSTransitionManager::GetKeyframesStyleMap(
    const std::string& animation_name) {
  auto it = keyframe_tokens_.find(animation_name);
  if (it != keyframe_tokens_.end()) {
    return it->second;
  }

  return empty_keyframe_map();
}

void CSSTransitionManager::TryToStopTransitionAnimator(
    starlight::AnimationPropertyType property_type) {
  const auto& data =
      transition_data_.find(static_cast<unsigned int>(property_type));
  if (data == transition_data_.end()) {
    return;
  }
  const auto& animation_iterator = animations_map_.find(data->second.name);
  if (animation_iterator == animations_map_.end()) {
    return;
  }
  animation_iterator->second->Destroy();
  animations_map_.erase(animation_iterator);
}

bool CSSTransitionManager::IsValueValid(starlight::AnimationPropertyType type,
                                        const tasm::CSSValue& value,
                                        const tasm::CSSParserConfigs& configs) {
  switch (type) {
    case starlight::AnimationPropertyType::kWidth:
    case starlight::AnimationPropertyType::kHeight:
    case starlight::AnimationPropertyType::kLeft:
    case starlight::AnimationPropertyType::kTop:
    case starlight::AnimationPropertyType::kRight:
    case starlight::AnimationPropertyType::kBottom: {
      auto parse_result = starlight::CSSStyleUtils::ToLength(
          value, CSSKeyframeManager::GetLengthContext(element()), configs);
      // return directly if the value of layout property is auto
      if (!parse_result.second) {
        return false;
      }
      if (!parse_result.first.IsUnit() && !parse_result.first.IsPercent()) {
        return false;
      }
      return true;
    }
    case starlight::AnimationPropertyType::kOpacity: {
      if (!value.IsNumber()) {
        return false;
      }
      auto parse_result = value.GetValue().Number();
      if (parse_result < 0 || parse_result > 1) {
        return false;
      }
      return true;
    }
    case starlight::AnimationPropertyType::kColor:
    case starlight::AnimationPropertyType::kBackgroundColor: {
      if (!value.IsNumber()) {
        return false;
      }
      return true;
    }
    case starlight::AnimationPropertyType::kTransform: {
      if (!value.IsArray()) {
        return false;
      }
      return true;
    }
    default: {
      return false;
    }
  }
}

starlight::AnimationPropertyType CSSTransitionManager::GetAnimationPropertyType(
    tasm::CSSPropertyID id) {
  const auto& transition_props_map = GetPropertyIDToAnimationPropertyTypeMap();
  const auto& property_it = transition_props_map.find(id);
  if (property_it != transition_props_map.end()) {
    return property_it->second;
  }
  return starlight::AnimationPropertyType::kNone;
}

}  // namespace animation
}  // namespace lynx
