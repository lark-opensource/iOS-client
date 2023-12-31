// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_SURFACE_SOFTWARE_SURFACE_H_
#define CANVAS_SURFACE_SOFTWARE_SURFACE_H_

#include <cstdint>

#include "canvas/surface/surface.h"

namespace lynx {
namespace canvas {

class SoftwareSurface : public Surface {
 public:
  SoftwareSurface() = default;
  ~SoftwareSurface() override = default;

  SoftwareSurface(const SoftwareSurface &) = delete;
  SoftwareSurface &operator=(const SoftwareSurface &) = delete;

  virtual uint8_t *Buffer() const { return nullptr; }
  virtual int32_t BytesPerRow() const = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_SURFACE_SOFTWARE_SURFACE_H_
