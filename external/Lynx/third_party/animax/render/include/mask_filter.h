// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_MASK_FILTER_H_
#define ANIMAX_RENDER_INCLUDE_MASK_FILTER_H_

#include <memory>

namespace lynx {
namespace animax {

class MaskFilter {
 public:
  virtual ~MaskFilter() = default;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_MASK_FILTER_H_
