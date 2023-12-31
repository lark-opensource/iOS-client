// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_SURFACE_H_
#define ANIMAX_RENDER_INCLUDE_SURFACE_H_

#include <cstdint>

namespace lynx {
namespace animax {
class Canvas;
class AnimaXOnScreenSurface;
class Surface {
 public:
  Surface(AnimaXOnScreenSurface *surface, int32_t width, int32_t height) {}
  virtual ~Surface() = default;

  virtual Canvas *GetCanvas() = 0;

  virtual void Resize(AnimaXOnScreenSurface *surface, int32_t width,
                      int32_t height) = 0;
  virtual void Clear() = 0;
  virtual void Flush() = 0;

  virtual void Destroy() = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_SURFACE_H_
