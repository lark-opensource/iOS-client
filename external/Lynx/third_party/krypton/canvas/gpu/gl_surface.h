// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_SURFACE_H_
#define CANVAS_GPU_GL_SURFACE_H_

#include <cstdint>

#include "base/base_export.h"
#include "canvas/gpu/gl/gl_include.h"
#include "canvas/surface/surface.h"

namespace lynx {
namespace canvas {

class GLSurface : public Surface {
 public:
  BASE_EXPORT static GLSurface *GetCurrent();
  static void ClearCurrent();

  GLSurface() = default;
  ~GLSurface() override = default;
  // virtual std::unique_ptr<SurfaceFrame> BeginFrame(const SkSize& size) = 0;
  // virtual void EndFrame() = 0;
  virtual void Init() override {}
  virtual bool Resize(int32_t width, int32_t height) override { return false; };
  virtual bool GLPresent() { return false; }
  virtual GLuint GLContextFBO() = 0;
  virtual void Flush() override { GLPresent(); }

  void SetCurrent();

  bool IsGPUBacked() const override { return true; }

 private:
  // disallow copy&assign
  GLSurface(const GLSurface &) = delete;
  GLSurface &operator=(const GLSurface &) = delete;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_SURFACE_H_
