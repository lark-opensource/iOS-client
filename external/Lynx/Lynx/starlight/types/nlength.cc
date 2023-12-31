// Copyright 2021 The Lynx Authors. All rights reserved.

#include "starlight/types/nlength.h"

#include <utility>

#include "base/string/string_number_convert.h"
#include "lepus/string_util.h"
#include "starlight/style/computed_css_style.h"
#include "starlight/types/measure_context.h"

namespace lynx {
namespace starlight {

using lynx::base::StringToFloat;

namespace {
// auto unit percentage vw vh
std::string ValueNLengthToString(const NLength& length) {
  if (length.GetType() == NLengthType::kNLengthAuto) {
    return std::string("auto");
  } else if (length.GetType() == NLengthType::kNLengthUnit) {
    return std::to_string(length.GetRawValue()) + "unit";
  } else if (length.GetType() == NLengthType::kNLengthPercentage) {
    return std::to_string(length.GetRawValue()) + "%";
  }

  return "";
}
}  // namespace
bool NLength::operator==(const NLength& o) const {
  if (this->IsCalc() && o.IsCalc()) {
    if (this->values_.size() != o.values_.size()) {
      return false;
    }
    size_t calc_sub_length = this->values_.size();
    for (size_t index = 0; index < calc_sub_length; ++index) {
      if (this->values_[index] != o.values_[index]) {
        return false;
      }
    }
    return true;
  } else {
    return (this->GetRawValue() == o.GetRawValue()) &&
           (this->GetType() == o.GetType());
  }
}

bool NLength::operator!=(const NLength& o) const { return !(*this == o); }

NLength NLength::MakeAutoNLength() {
  return NLength(0.0, NLengthType::kNLengthAuto);
}

NLength NLength::MakeMaxContentNLength() {
  return NLength(0.0, NLengthType::kNLengthMaxContent);
}

NLength NLength::MakeFitContentNLength(NLength nLength) {
  return NLength({std::move(nLength)}, NLengthType::kNLengthFitContent);
}

NLength NLength::MakeUnitNLength(float value) {
  return NLength(value, NLengthType::kNLengthUnit);
}

NLength NLength::MakePercentageNLength(float value) {
  return NLength(value, NLengthType::kNLengthPercentage);
}

NLength NLength::MakeCalcNLength(std::vector<NLength> value) {
  return NLength(std::move(value), NLengthType::kNLengthCalc);
}

NLength::NLength(float value, NLengthType type) : value_(value), type_(type) {}
NLength::NLength(std::vector<NLength> values, NLengthType type)
    : values_(std::move(values)), type_(type) {}

std::string NLength::ToString() const {
  std::string result;
  switch (GetType()) {
    case NLengthType::kNLengthAuto:
    case NLengthType::kNLengthUnit:
    case NLengthType::kNLengthPercentage: {
      result += ValueNLengthToString(*this);
    } break;
    case NLengthType::kNLengthCalc: {
      result += "calc(";
      // + xxx + xxxx + xxx;
      bool is_first = true;
      for (const auto& entry : GetCalcSubLengths()) {
        result += ValueNLengthToString(entry);
        if (!is_first) {
          result += " + ";
        } else {
          is_first = false;
        }
      }
      result += ")";
    } break;
    case NLengthType::kNLengthMaxContent: {
      result = "max-content";
    } break;
    case NLengthType::kNLengthFitContent: {
      result =
          "fit-content(" + ValueNLengthToString(GetFitContentValue()) + ")";
    } break;
    default:
      break;
  }
  return result + ";";
}

}  // namespace starlight
}  // namespace lynx
