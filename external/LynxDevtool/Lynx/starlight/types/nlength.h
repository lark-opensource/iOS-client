// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_TYPES_NLENGTH_H_
#define LYNX_STARLIGHT_TYPES_NLENGTH_H_

#include <stack>
#include <string>
#include <vector>

#include "starlight/layout/layout_global.h"

namespace lynx {
namespace starlight {

class CssMeasureContext;

enum NLengthType {
  kNLengthAuto,
  kNLengthUnit,
  kNLengthPercentage,
  kNLengthCalc,
  kNLengthMaxContent,
  kNLengthFitContent,
};

class NLength {
 public:
  static NLength MakeAutoNLength();
  static NLength MakeMaxContentNLength();
  static NLength MakeFitContentNLength(NLength nLength);
  static NLength MakeUnitNLength(float value);
  static NLength MakePercentageNLength(float value);
  static NLength MakeCalcNLength(std::vector<NLength> value);

  ~NLength() {}

  std::string ToString() const;

  float GetRawValue() const { return value_; }
  NLengthType GetType() const { return type_; }
  const std::vector<NLength>& GetCalcSubLengths() const { return values_; }
  const NLength& GetFitContentValue() const { return values_.front(); }

  bool IsAuto() const { return GetType() == NLengthType::kNLengthAuto; }
  bool IsUnit() const { return GetType() == NLengthType::kNLengthUnit; }
  bool IsPercent() const {
    return GetType() == NLengthType::kNLengthPercentage;
  }
  bool IsCalc() const { return GetType() == NLengthType::kNLengthCalc; }
  bool IsMaxContent() const {
    return GetType() == NLengthType::kNLengthMaxContent;
  }
  bool IsFitContent() const {
    return GetType() == NLengthType::kNLengthFitContent;
  }

  bool IsIntrinsic() const { return IsFitContent() || IsMaxContent(); }

  bool operator==(const NLength& o) const;
  bool operator!=(const NLength& o) const;

 private:
  // not calc
  NLength(float value, NLengthType type);
  // calc
  NLength(std::vector<NLength> values, NLengthType type);
  // px、percent、vw、vh
  float value_;
  // calc、fit-content
  std::vector<NLength> values_;
  NLengthType type_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_TYPES_NLENGTH_H_
