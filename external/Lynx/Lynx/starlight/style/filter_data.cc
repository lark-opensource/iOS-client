//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "filter_data.h"
namespace lynx {
namespace starlight {

FilterData::FilterData()
    : type(FilterType::kNone), amount(NLength::MakeUnitNLength(0.0f)) {}

void FilterData::Reset() {
  type = FilterType::kNone;
  amount = NLength::MakeUnitNLength(0.0f);
}

}  // namespace starlight
}  // namespace lynx
