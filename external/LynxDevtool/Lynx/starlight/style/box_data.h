// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_BOX_DATA_H_
#define LYNX_STARLIGHT_STYLE_BOX_DATA_H_

#include "base/ref_counted.h"
#include "starlight/types/nlength.h"

namespace lynx {
namespace starlight {

class BoxData : public base::RefCountedThreadSafeStorage {
 public:
  void ReleaseSelf() const override { delete this; }
  static base::scoped_refptr<BoxData> Create() {
    return base::AdoptRef(new BoxData());
  }
  base::scoped_refptr<BoxData> Copy() const {
    return base::AdoptRef(new BoxData(*this));
  }

  BoxData();
  BoxData(const BoxData& other);
  ~BoxData() = default;
  void Reset();
  NLength width_;
  NLength height_;
  NLength min_width_;
  NLength max_width_;
  NLength min_height_;
  NLength max_height_;
  float aspect_ratio_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_BOX_DATA_H_
