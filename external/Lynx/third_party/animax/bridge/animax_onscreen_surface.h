// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_BRIDGE_ANIMAX_ONSCREEN_SURFACE_H_
#define ANIMAX_BRIDGE_ANIMAX_ONSCREEN_SURFACE_H_

#include <memory>

#include "canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class GLContext;
class Surface;
}  // namespace canvas
}  // namespace lynx

namespace lynx {
namespace animax {

class AnimaXOnScreenSurface {
 public:
  /** Constructor
   * @param surface lynx::canvas::Surface, nonnull.
   */
  AnimaXOnScreenSurface(std::unique_ptr<lynx::canvas::Surface> surface);
  /**
   * Destructor.
   * gpu thread only.
   */
  ~AnimaXOnScreenSurface() = default;
  /**
   * Init onscreen surface.
   * gpu thread only.
   * Must call this before calling other methods.
   */
  void Init();
  /**
   * Check whether the surface is gpu backend or not.
   * gpu thread only.
   * @return true if the surface is gpu backend.
   */
  bool IsGPUBacked() const;
  /**
   * Make context related with the surface the current context.
   * gpu thread only.
   * Make sure to call this if you use the surface and the surface is gpu
   * backend. If the surface isn't gpu backend, calling this will do nothing.
   */
  void MakeRelatedContextCurrent();
  /**
   * Flush content of surface to screen.
   * gpu thread only.
   */
  void Flush();
  /**
   * Resize the onscreen surface.
   * gpu thread only.
   * The onscreen surface is usually related with system view. If the size of
   * system view changes, call this to update the width and height of onscreen
   * surface.
   * @param width  new width getting from system view.
   * @param height new height getting from system view.
   * @return       true if the onscreen surface changed, false may means some
   * error occur.
   */
  bool Resize(int32_t width, int32_t height);
  /**
   * Width of onscreen surface.
   * gpu thread only.
   * @return width of onscreen surface.
   */
  int32_t Width() const;
  /**
   * Height of onscreen surface.
   * gpu thread only.
   * @return height of onscreen surface.
   */
  int32_t Height() const;
  /**
   * The related framebuffer object of the onscreen surface.
   * gpu thread only.
   * @return framebuffer object of onscreen surface. If the surface isn't gpu
   * backend, return 0.
   */
  GLuint GLContextFBO();
  /**
   * The related buffer of the onscreen surface.
   * gpu thread only.
   * @return buffer address in memory. If the surface is gpu backend, return
   * nullptr.
   */
  uint8_t *Buffer() const;
  /**
   * Bytes per row.
   * gpu thread only.
   * Total size of Buffer is equal to BytesPerRow() * Height()
   * @return bytes per row. If the surface is gpu backend, return 0.
   */
  int32_t BytesPerRow();

 private:
  std::unique_ptr<lynx::canvas::GLContext> context_;
  std::unique_ptr<lynx::canvas::Surface> surface_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_BRIDGE_ANIMAX_ONSCREEN_SURFACE_H_
