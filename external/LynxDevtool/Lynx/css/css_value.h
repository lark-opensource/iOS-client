// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_VALUE_H_
#define LYNX_CSS_CSS_VALUE_H_

#include <string>
#include <utility>

#include "base/base_export.h"
#include "lepus/value-inl.h"
#include "lepus/value.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {
enum class CSSValuePattern {
  EMPTY = 0,
  STRING = 1,
  NUMBER = 2,
  BOOLEAN = 3,
  ENUM = 4,
  PX = 5,
  RPX = 6,
  EM = 7,
  REM = 8,
  VH = 9,
  VW = 10,
  PERCENT = 11,
  CALC = 12,
  ENV = 13,
  ARRAY = 14,
  MAP = 15,
  PPX = 16,
  INTRINSIC = 17,
  SP = 18,
  COUNT = 19,
};

enum class CSSValueType {
  DEFAULT = 0,
  VARIABLE = 1,
};

class BASE_EXPORT_FOR_DEVTOOL CSSValue {
 public:
  explicit CSSValue(lepus::Value value = lepus::Value(),
                    CSSValuePattern pattern = CSSValuePattern::STRING,
                    CSSValueType type = CSSValueType::DEFAULT,
                    lepus::String default_val = lepus::String())
      : value_(std::move(value)),
        pattern_(pattern),
        type_(type),
        default_value_(default_val) {}

  template <typename T>
  T GetEnum() const {
    return (T)AsNumber();
  }

  static CSSValue Empty() {
    return CSSValue(lepus::Value(), CSSValuePattern::EMPTY);
  }

  static CSSValue MakeEnum(int enumType) {
    return CSSValue(lepus::Value(enumType), CSSValuePattern::ENUM);
  }

  lepus::Value& GetValue() const { return value_; }
  CSSValuePattern GetPattern() const { return pattern_; }
  CSSValueType GetValueType() const { return type_; }
  lepus::String& GetDefaultValue() const { return default_value_; }

  void SetValue(lepus::Value value) { value_ = value; }
  void SetPattern(CSSValuePattern pattern) { pattern_ = pattern; }
  void SetType(CSSValueType type) { type_ = type; }
  void SetDefaultValue(lepus::String default_val) {
    default_value_ = default_val;
  }

  bool IsString() const { return pattern_ == CSSValuePattern::STRING; }
  bool IsNumber() const { return pattern_ == CSSValuePattern::NUMBER; }
  bool IsBoolean() const { return pattern_ == CSSValuePattern::BOOLEAN; }
  bool IsEnum() const { return pattern_ == CSSValuePattern::ENUM; }
  bool IsPx() const { return pattern_ == CSSValuePattern::PX; }
  bool IsPPx() const { return pattern_ == CSSValuePattern::PPX; }
  bool IsRpx() const { return pattern_ == CSSValuePattern::RPX; }
  bool IsEm() const { return pattern_ == CSSValuePattern::EM; }
  bool IsRem() const { return pattern_ == CSSValuePattern::REM; }
  bool IsVh() const { return pattern_ == CSSValuePattern::VH; }
  bool IsVw() const { return pattern_ == CSSValuePattern::VW; }
  bool IsPercent() const { return pattern_ == CSSValuePattern::PERCENT; }
  bool IsCalc() const { return pattern_ == CSSValuePattern::CALC; }
  bool IsArray() const { return pattern_ == CSSValuePattern::ARRAY; }
  bool IsMap() const { return pattern_ == CSSValuePattern::MAP; }
  bool IsEmpty() const { return pattern_ == CSSValuePattern::EMPTY; }
  bool IsEnv() const { return pattern_ == CSSValuePattern::ENV; }
  bool IsIntrinsic() const { return pattern_ == CSSValuePattern::INTRINSIC; }
  bool IsSp() const { return pattern_ == CSSValuePattern::SP; }

  double AsNumber() const { return value_.Number(); }

  std::string AsString() const { return value_.String()->str(); }

  BASE_EXPORT_FOR_DEVTOOL bool AsBool() const;

  std::string AsJsonString() const;

  friend bool operator==(const CSSValue& left, const CSSValue& right) {
    return left.pattern_ == right.pattern_ && left.value_ == right.value_;
  }

  friend bool operator!=(const CSSValue& left, const CSSValue& right) {
    return !(left == right);
  }

 private:
  mutable lepus::Value value_;
  mutable CSSValuePattern pattern_;
  mutable CSSValueType type_;
  mutable lepus::String default_value_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_VALUE_H_
