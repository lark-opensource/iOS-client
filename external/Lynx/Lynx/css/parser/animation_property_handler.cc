// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/animation_property_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/unit_handler.h"
#include "lepus/array.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {
namespace AnimationPropertyHandler {
using starlight::AnimationPropertyType;

AnimationPropertyType toPropertyType(std::string str,
                                     bool enable_strict_mode = false) {
  AnimationPropertyType type = AnimationPropertyType::kNone;
  if (str == "none") {
    type = AnimationPropertyType::kNone;
  } else if (str == "opacity") {
    type = AnimationPropertyType::kOpacity;
  } else if (str == "scaleX") {
    type = AnimationPropertyType::kScaleX;
  } else if (str == "scaleY") {
    type = AnimationPropertyType::kScaleY;
  } else if (str == "scaleXY") {
    type = AnimationPropertyType::kScaleXY;
  } else if (str == "width") {
    type = AnimationPropertyType::kWidth;
  } else if (str == "height") {
    type = AnimationPropertyType::kHeight;
  } else if (str == "background-color") {
    type = AnimationPropertyType::kBackgroundColor;
  } else if (str == "color") {
    type = AnimationPropertyType::kColor;
  } else if (str == "visibility") {
    type = AnimationPropertyType::kVisibility;
  } else if (str == "left") {
    type = AnimationPropertyType::kLeft;
  } else if (str == "top") {
    type = AnimationPropertyType::kTop;
  } else if (str == "right") {
    type = AnimationPropertyType::kRight;
  } else if (str == "bottom") {
    type = AnimationPropertyType::kBottom;
  } else if (str == "transform") {
    type = AnimationPropertyType::kTransform;
  } else if (str == "all") {
    type = AnimationPropertyType::kAll;
  } else {
    UnitHandler::CSSWarning(false, enable_strict_mode, TYPE_UNSUPPORTED,
                            ANIMATION_PROPERTY, str.c_str());
  }
  return type;
}

bool Process(const lepus::Value& input, CSSValue& css_value,
             const CSSParserConfigs& configs) {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDTransitionProperty).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  auto itor = remove_if(str.begin(), str.end(), ::isspace);
  str.erase(itor, str.end());
  if (str.find(',') != std::string::npos) {
    std::vector<std::string> result;
    base::SplitString(str, ',', result);
    auto arr = lepus::CArray::Create();
    for (auto& item : result) {
      arr->push_back(lepus::Value(static_cast<int>(
          toPropertyType(item, configs.enable_css_strict_mode))));
    }
    css_value.SetValue(lepus::Value(arr));
    css_value.SetPattern(CSSValuePattern::ARRAY);
  } else {
    css_value.SetValue(lepus::Value(
        static_cast<int>(toPropertyType(str, configs.enable_css_strict_mode))));
    css_value.SetPattern(CSSValuePattern::ENUM);
  }

  return true;
}

HANDLER_IMPL() {
  CSSValue css_value;
  if (!Process(input, css_value, configs)) {
    return false;
  }
  output[key] = css_value;
  return true;
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDLayoutAnimationCreateProperty] = &Handle;
  array[kPropertyIDLayoutAnimationDeleteProperty] = &Handle;
  array[kPropertyIDTransitionProperty] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace AnimationPropertyHandler

}  // namespace tasm
}  // namespace lynx
