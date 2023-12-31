// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/border_radius_handler.h"

#include <string>
#include <vector>

#include "base/string/string_utils.h"
#include "css/parser/length_handler.h"
#include "css/unit_handler.h"
#include "css_string_parser.h"
#include "lepus/array.h"
#include "starlight/style/css_style_utils.h"

namespace lynx {
namespace tasm {
namespace BorderRadiusHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(key).c_str(), STRING_TYPE)) {
    return false;
  }
  std::string str = input.String()->str();
  CSSStringParser parser(str.c_str(), static_cast<int>(str.size()), configs);

  switch (key) {
    case kPropertyIDBorderRadius: {
      CSSValue x_radii[4] = {CSSValue::Empty(), CSSValue::Empty(),
                             CSSValue::Empty(), CSSValue::Empty()};
      CSSValue y_radii[4] = {CSSValue::Empty(), CSSValue::Empty(),
                             CSSValue::Empty(), CSSValue::Empty()};
      if (!parser.ParseBorderRadius(x_radii, y_radii)) {
        return false;
      }
      const std::vector<CSSPropertyID> radius_key_array = {
          kPropertyIDBorderTopLeftRadius, kPropertyIDBorderTopRightRadius,
          kPropertyIDBorderBottomRightRadius,
          kPropertyIDBorderBottomLeftRadius};
      for (int i = 0; i < 4; i++) {
        auto container = lepus::CArray::Create();
        container->push_back(x_radii[i].GetValue());
        container->push_back(
            lepus::Value(static_cast<int>(x_radii[i].GetPattern())));
        container->push_back(y_radii[i].GetValue());
        container->push_back(
            lepus::Value(static_cast<int>(y_radii[i].GetPattern())));
        output[radius_key_array[i]] =
            CSSValue(lepus::Value(container), CSSValuePattern::ARRAY);
      }
      output.erase(key);
    } break;
    case kPropertyIDBorderTopLeftRadius:
    case kPropertyIDBorderTopRightRadius:
    case kPropertyIDBorderBottomRightRadius:
    case kPropertyIDBorderBottomLeftRadius:
    case kPropertyIDBorderStartStartRadius:
    case kPropertyIDBorderStartEndRadius:
    case kPropertyIDBorderEndStartRadius:
    case kPropertyIDBorderEndEndRadius: {
      CSSValue value = parser.ParseSingleBorderRadius();
      if (value.IsArray()) {
        output[key] = value;
      }
    } break;
    default:
      break;
  }
  return true;
}

HANDLER_REGISTER_IMPL() {
  array[kPropertyIDBorderRadius] = &Handle;
  array[kPropertyIDBorderTopLeftRadius] = &Handle;
  array[kPropertyIDBorderTopRightRadius] = &Handle;
  array[kPropertyIDBorderBottomLeftRadius] = &Handle;
  array[kPropertyIDBorderBottomRightRadius] = &Handle;
  array[kPropertyIDBorderStartStartRadius] = &Handle;
  array[kPropertyIDBorderStartEndRadius] = &Handle;
  array[kPropertyIDBorderEndStartRadius] = &Handle;
  array[kPropertyIDBorderEndEndRadius] = &Handle;
}

}  // namespace BorderRadiusHandler
}  // namespace tasm
}  // namespace lynx
