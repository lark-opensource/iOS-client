// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/four_sides_shorthand_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {

namespace {
constexpr CSSPropertyID kMarginIDs[] = {
    kPropertyIDMarginTop, kPropertyIDMarginRight, kPropertyIDMarginBottom,
    kPropertyIDMarginLeft};
constexpr CSSPropertyID kBorderWidthIDs[] = {
    kPropertyIDBorderTopWidth, kPropertyIDBorderRightWidth,
    kPropertyIDBorderBottomWidth, kPropertyIDBorderLeftWidth};
constexpr CSSPropertyID kPaddingsIDs[] = {
    kPropertyIDPaddingTop, kPropertyIDPaddingRight, kPropertyIDPaddingBottom,
    kPropertyIDPaddingLeft};
constexpr CSSPropertyID kBorderColorIDs[] = {
    kPropertyIDBorderTopColor, kPropertyIDBorderRightColor,
    kPropertyIDBorderBottomColor, kPropertyIDBorderLeftColor};
constexpr CSSPropertyID kBorderStyleIDs[] = {
    kPropertyIDBorderTopStyle, kPropertyIDBorderRightStyle,
    kPropertyIDBorderBottomStyle, kPropertyIDBorderLeftStyle};
}  // namespace

namespace FourSidesShorthandHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(input.IsString() || input.IsNumber(),
                               configs.enable_css_strict_mode,
                               "value must be a string or number:%d", key)) {
    return false;
  }
  lepus::Value maybeValue = input;
  const CSSPropertyID* property_index = nullptr;
  switch (key) {
    case kPropertyIDMargin:
      property_index = kMarginIDs;
      break;
    case kPropertyIDBorderWidth:
      property_index = kBorderWidthIDs;
      break;
    case kPropertyIDPadding:
      property_index = kPaddingsIDs;
      break;
    case kPropertyIDBorderColor:
      property_index = kBorderColorIDs;
      break;
    case kPropertyIDBorderStyle:
      property_index = kBorderStyleIDs;
      break;
    default:
      UnitHandler::CSSUnreachable(configs.enable_css_strict_mode,
                                  "don't handle this property:%d", key);
      break;
  }
  if (input.Type() == lepus::Value_String) {
    auto str = input.String()->str();
    std::vector<std::string> combines;
    base::SplitStringBySpaceOutOfBrackets(str, combines);
    switch (combines.size()) {
      case 1: {
        UnitHandler::Process(property_index[0],
                             lepus::Value(combines[0].c_str()), output,
                             configs);
        if (output.find(property_index[0]) != output.end()) {
          output[property_index[1]] = output[property_index[0]];
          output[property_index[2]] = output[property_index[0]];
          output[property_index[3]] = output[property_index[0]];
        } else {
          return false;
        }
      } break;
      case 2: {
        UnitHandler::Process(property_index[0],
                             lepus::Value(combines[0].c_str()), output,
                             configs);
        UnitHandler::Process(property_index[1],
                             lepus::Value(combines[1].c_str()), output,
                             configs);
        if (output.find(property_index[0]) != output.end() &&
            output.find(property_index[1]) != output.end()) {
          output[property_index[2]] = output[property_index[0]];
          output[property_index[3]] = output[property_index[1]];
        } else {
          return false;
        }
      } break;
      case 3: {
        UnitHandler::Process(property_index[0],
                             lepus::Value(combines[0].c_str()), output,
                             configs);
        UnitHandler::Process(property_index[1],
                             lepus::Value(combines[1].c_str()), output,
                             configs);
        UnitHandler::Process(property_index[2],
                             lepus::Value(combines[2].c_str()), output,
                             configs);
        if (output.find(property_index[1]) != output.end()) {
          output[property_index[3]] = output[property_index[1]];
        } else {
          return false;
        }
      } break;
      case 4: {
        UnitHandler::Process(property_index[0],
                             lepus::Value(combines[0].c_str()), output,
                             configs);
        UnitHandler::Process(property_index[1],
                             lepus::Value(combines[1].c_str()), output,
                             configs);
        UnitHandler::Process(property_index[2],
                             lepus::Value(combines[2].c_str()), output,
                             configs);
        UnitHandler::Process(property_index[3],
                             lepus::Value(combines[3].c_str()), output,
                             configs);
      } break;
      default:
        return false;
    }
  } else {
    if (!UnitHandler::CSSWarning(
            key != kPropertyIDBorderColor, configs.enable_css_strict_mode,
            TYPE_MUST_BE,
            CSSProperty::GetPropertyName(kPropertyIDBorderColor).c_str(),
            STRING_TYPE)) {
      return false;
    }
    if (!UnitHandler::CSSWarning(
            key != kPropertyIDBorderStyle, configs.enable_css_strict_mode,
            TYPE_MUST_BE,
            CSSProperty::GetPropertyName(kPropertyIDBorderStyle).c_str(),
            STRING_TYPE)) {
      return false;
    }
    UnitHandler::Process(property_index[0], maybeValue, output, configs);
    if (output.find(property_index[0]) != output.end()) {
      output[property_index[1]] = output[property_index[0]];
      output[property_index[2]] = output[property_index[0]];
      output[property_index[3]] = output[property_index[0]];
    } else {
      return false;
    }
  }
  return true;
}

HANDLER_REGISTER_IMPL() {
  array[kPropertyIDMargin] = &Handle;
  array[kPropertyIDPadding] = &Handle;
  array[kPropertyIDBorderWidth] = &Handle;
  array[kPropertyIDBorderColor] = &Handle;
  array[kPropertyIDBorderStyle] = &Handle;
}

}  // namespace FourSidesShorthandHandler
}  // namespace tasm
}  // namespace lynx
