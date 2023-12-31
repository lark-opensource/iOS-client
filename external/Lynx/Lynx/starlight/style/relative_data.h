// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_RELATIVE_DATA_H_
#define LYNX_STARLIGHT_STYLE_RELATIVE_DATA_H_

#include "base/ref_counted.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace starlight {

class RelativeData : public base::RefCountedThreadSafeStorage {
 public:
  void ReleaseSelf() const override { delete this; }
  static base::scoped_refptr<RelativeData> Create() {
    return base::AdoptRef(new RelativeData());
  }
  base::scoped_refptr<RelativeData> Copy() const {
    return base::AdoptRef(new RelativeData(*this));
  }
  RelativeData();
  RelativeData(const RelativeData& data);
  ~RelativeData() = default;
  void Reset();
  int relative_id_;
  int relative_align_top_, relative_align_right_, relative_align_bottom_,
      relative_align_left_;
  int relative_top_of_, relative_right_of_, relative_bottom_of_,
      relative_left_of_;
  bool relative_layout_once_;
  RelativeCenterType relative_center_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_RELATIVE_DATA_H_
