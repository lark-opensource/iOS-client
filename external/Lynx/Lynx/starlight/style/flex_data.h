// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_FLEX_DATA_H_
#define LYNX_STARLIGHT_STYLE_FLEX_DATA_H_

#include "base/ref_counted.h"
#include "starlight/style/css_type.h"
#include "starlight/types/nlength.h"

namespace lynx {
namespace starlight {

class FlexData : public base::RefCountedThreadSafeStorage {
 public:
  void ReleaseSelf() const override { delete this; }
  static base::scoped_refptr<FlexData> Create() {
    return base::AdoptRef(new FlexData());
  }
  base::scoped_refptr<FlexData> Copy() const {
    return base::AdoptRef(new FlexData(*this));
  }
  FlexData();
  FlexData(const FlexData& data);
  ~FlexData() = default;
  void Reset();
  float flex_grow_;
  float flex_shrink_;
  NLength flex_basis_;
  FlexDirectionType flex_direction_;
  FlexWrapType flex_wrap_;
  JustifyContentType justify_content_;
  FlexAlignType align_items_;
  FlexAlignType align_self_;
  AlignContentType align_content_;
  float order_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_FLEX_DATA_H_
