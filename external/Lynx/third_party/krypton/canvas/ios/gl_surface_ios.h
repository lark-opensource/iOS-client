// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IOS_GL_SURFACE_IOS_H_
#define CANVAS_IOS_GL_SURFACE_IOS_H_

#include <memory>

#include "canvas/gpu/gl_surface.h"
#include "canvas/ios/gl_context_ios.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {
class Raster;
class GLSurfaceIOS : public GLSurface {
 public:
  using Handle = CAEAGLLayer *;
  GLSurfaceIOS(CAEAGLLayer *layer);
  ~GLSurfaceIOS() override;

  GLuint GLContextFBO() override;
  bool GLPresent() override;
  Handle handle() const { return layer_; }
  bool Resize(int32_t, int32_t) override;
  int32_t Width() const override;
  int32_t Height() const override;
  void Flush() override { GLPresent(); }
  bool Valid() const override { return valid_; }

  void Init() override;

 private:
  void Initialize();
  void PrepareFrameBuffer();
  void PrepareRenderBuffer();
  bool ResizeIfNecessary(int size_width, int size_height);
  void DeInitialize();

  CAEAGLLayer *layer_;
  GLuint framebuffer_ = GL_NONE;
  GLuint renderbuffer_ = GL_NONE;
  GLint pre_size_width_ = 0;
  GLint pre_size_height_ = 0;
  bool valid_;

  // disallow copy&assign
  GLSurfaceIOS(const GLSurfaceIOS &) = delete;
  GLSurfaceIOS &operator==(const GLSurfaceIOS &) = delete;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IOS_GL_SURFACE_IOS_H_
