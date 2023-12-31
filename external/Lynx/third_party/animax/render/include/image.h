// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_IMAGE_H_
#define ANIMAX_RENDER_INCLUDE_IMAGE_H_

#include <memory>

namespace lynx {
namespace animax {

class Image {
 public:
  virtual ~Image() = default;

  virtual float GetWidth() const = 0;

  virtual float GetHeight() const = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_IMAGE_H_
