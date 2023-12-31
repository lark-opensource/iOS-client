// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_LINEAR_DATA_H_
#define LYNX_STARLIGHT_STYLE_LINEAR_DATA_H_

#include "base/ref_counted.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace starlight {

class LinearData : public base::RefCountedThreadSafeStorage {
 public:
  void ReleaseSelf() const override { delete this; }
  static base::scoped_refptr<LinearData> Create() {
    return base::AdoptRef(new LinearData());
  }
  base::scoped_refptr<LinearData> Copy() const {
    return base::AdoptRef(new LinearData(*this));
  }

 public:
  LinearData();
  LinearData(const LinearData& data);
  ~LinearData() = default;
  void Reset();
  float linear_weight_sum_;
  float linear_weight_;
  LinearOrientationType linear_orientation_;
  LinearLayoutGravityType linear_layout_gravity_;
  LinearGravityType linear_gravity_;
  LinearCrossGravityType linear_cross_gravity_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_LINEAR_DATA_H_
