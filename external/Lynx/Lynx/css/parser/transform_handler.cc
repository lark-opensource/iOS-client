// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/transform_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_number_convert.h"
#include "base/string/string_utils.h"
#include "css/parser/length_handler.h"
#include "css/unit_handler.h"
#include "lepus/array.h"
#include "lepus/string_util.h"
#include "starlight/style/css_type.h"

#ifdef OS_WIN
#define _USE_MATH_DEFINES
#include <math.h>
#endif

namespace lynx {
namespace tasm {
namespace TransformHandler {
namespace {
bool handleLengthParams(std::vector<std::string>& params,
                        base::scoped_refptr<lepus::CArray> arr, int num,
                        const CSSParserConfigs& configs) {
  CSSValue css_value;
  for (int i = 0; i < num && static_cast<size_t>(i) < params.size(); i++) {
    if ((LengthHandler::Process(lepus::Value(params[i].c_str()), css_value,
                                configs))) {
      arr->push_back(css_value.GetValue());
      arr->push_back(lepus::Value(static_cast<int>(css_value.GetPattern())));
    } else {
      return false;
    }
  }
  return true;
}

void handleAngleParams(std::vector<std::string>& params,
                       base::scoped_refptr<lepus::CArray> arr, int num) {
  for (int i = 0; i < num && static_cast<size_t>(i) < params.size(); i++) {
    float f = atof(params[i].c_str());
    if (lepus::EndsWith(params[i], "rad")) {
      f = f * 180 / M_PI;
    } else if (lepus::EndsWith(params[i], "turn")) {
      f = f * 360;
    }
    arr->push_back(lepus::Value(f));
  }
}

bool handleFloatParams(std::vector<std::string>& params,
                       base::scoped_refptr<lepus::CArray> arr, int num) {
  for (int i = 0; i < num && static_cast<size_t>(i) < params.size(); i++) {
    double value;
    auto ret = base::StringToDouble(params[i], value, true);
    if (!ret) {
      return false;
    }
    arr->push_back(lepus::Value(value));
  }
  return true;
}

};  // namespace
using starlight::TransformType;

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  std::vector<std::string> transforms =
      base::SplitStringIgnoreBracket(str, ' ');
  if (transforms.empty()) {
    if (!UnitHandler::CSSWarning(
            false, configs.enable_css_strict_mode, FORMAT_ERROR,
            CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
            str.c_str())) {
      return false;
    }
  }
  auto items = lepus::CArray::Create();
  for (auto& item : transforms) {
    auto left = item.find("(");
    auto end = item.rfind(")");
    if (left == item.npos || end == item.npos || left >= end || left == 0) {
      if (!UnitHandler::CSSWarning(
              false, configs.enable_css_strict_mode, FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
              str.c_str())) {
        return false;
      }
    }
    auto trans_func = item.substr(0, left);
    auto params_str = item.substr(left, end - left + 1);
    std::vector<std::string> params;
    base::ConvertParenthesesStringToVector(params_str, params);

    auto arr = lepus::CArray::Create();

    TransformType trans_func_type = TransformType::kNone;
    if (trans_func == "translate") {
      trans_func_type = TransformType::kTranslate;
    } else if (trans_func == "translateX") {
      trans_func_type = TransformType::kTranslateX;
    } else if (trans_func == "translateY") {
      trans_func_type = TransformType::kTranslateY;
    } else if (trans_func == "translateZ") {
      trans_func_type = TransformType::kTranslateZ;
    } else if (trans_func == "translate3d" || trans_func == "translate3D") {
      trans_func_type = TransformType::kTranslate3d;
    } else if (trans_func == "rotate") {
      trans_func_type = TransformType::kRotate;
    } else if (trans_func == "rotateX") {
      trans_func_type = TransformType::kRotateX;
    } else if (trans_func == "rotateY") {
      trans_func_type = TransformType::kRotateY;
    } else if (trans_func == "rotateZ") {
      trans_func_type = TransformType::kRotateZ;
    } else if (trans_func == "scale") {
      trans_func_type = TransformType::kScale;
    } else if (trans_func == "scaleX") {
      trans_func_type = TransformType::kScaleX;
    } else if (trans_func == "scaleY") {
      trans_func_type = TransformType::kScaleY;
    } else if (trans_func == "skew") {
      trans_func_type = TransformType::kSkew;
    } else if (trans_func == "skewX") {
      trans_func_type = TransformType::kSkewX;
    } else if (trans_func == "skewY") {
      trans_func_type = TransformType::kSkewY;
    } else {
      if (!UnitHandler::CSSWarning(
              false, configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
              CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
              str.c_str())) {
        return false;
      }
    }

    arr->push_back(lepus::Value(static_cast<int>(trans_func_type)));

    if (trans_func_type == TransformType::kTranslate) {
      // translate(x,y)
      if (!UnitHandler::CSSWarning(
              handleLengthParams(params, arr, 2, configs),
              configs.enable_css_strict_mode, FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
              str.c_str())) {
        return false;
      }
    } else if (trans_func_type == TransformType::kTranslateX ||
               trans_func_type == TransformType::kTranslateY ||
               trans_func_type == TransformType::kTranslateZ) {
      // translateX(x)
      if (!UnitHandler::CSSWarning(
              handleLengthParams(params, arr, 1, configs),
              configs.enable_css_strict_mode, FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
              str.c_str())) {
        return false;
      }
    } else if (trans_func_type == TransformType::kTranslate3d) {
      // translate3d(x,y,z)
      if (!UnitHandler::CSSWarning(
              handleLengthParams(params, arr, 3, configs),
              configs.enable_css_strict_mode, FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
              str.c_str())) {
        return false;
      }
    } else if (trans_func_type == TransformType::kRotate ||
               trans_func_type == TransformType::kRotateX ||
               trans_func_type == TransformType::kRotateY ||
               trans_func_type == TransformType::kRotateZ ||
               trans_func_type == TransformType::kSkewX ||
               trans_func_type == TransformType::kSkewY) {
      // rotate(angle)
      // skewX(angle) skewY(angle)
      handleAngleParams(params, arr, 1);
    } else if (trans_func_type == TransformType::kSkew) {
      // skew(angle) skew(angle, angle)
      handleAngleParams(params, arr, 2);
    } else if (trans_func_type == TransformType::kScale) {
      // scale(x,y)
      if (!handleFloatParams(params, arr, 2)) {
        UnitHandler::CSSWarning(
            false, configs.enable_css_strict_mode, FORMAT_ERROR,
            CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
            str.c_str());
        continue;
      }
    } else if (trans_func_type == TransformType::kScaleX ||
               trans_func_type == TransformType::kScaleY) {
      // scaleX(x)  scaleY(y)
      if (!handleFloatParams(params, arr, 1)) {
        UnitHandler::CSSWarning(
            false, configs.enable_css_strict_mode, FORMAT_ERROR,
            CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
            str.c_str());
        continue;
      }
    } else {
      if (!UnitHandler::CSSWarning(
              false, configs.enable_css_strict_mode, FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDTransform).c_str(),
              str.c_str())) {
        return false;
      }
    }
    items->push_back(lepus::Value(arr));
  }
  output[key] = CSSValue(lepus::Value(items), CSSValuePattern::ARRAY);
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDTransform] = &Handle; }
}  // namespace TransformHandler
}  // namespace tasm
}  // namespace lynx
