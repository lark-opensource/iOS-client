// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_CANVAS_RENDERBUFFER_H_
#define CANVAS_WEBGL_CANVAS_RENDERBUFFER_H_

#include <cstdint>

#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl_device_attributes.h"

namespace lynx {
namespace canvas {
class CanvasElement;
class CanvasRenderbuffer final {
 public:
  enum MSAAMode {
    kNone,
    kExplicitResolve,
    kImplicitResolve,
  };
  CanvasRenderbuffer();
  ~CanvasRenderbuffer();
  int width() const;
  int height() const;
  bool Build(int w, int h, int aa = 0);
  bool Dispose();

  GLuint reading_fbo() const;
  GLuint drawing_fbo() const;

  void ResolveIfNeeded();

 private:
  void BuildNoMSAAFramebuffer(int w, int h, bool need_depth);
  void BuildMSAAFramebuffer(MSAAMode msaa_mode, int samples, int w, int h);

  GLDeviceAttributes device_attributes_;
  MSAAMode msaa_mode_;
  uint32_t w_ = 0, h_ = 0;
  GLuint fbo_ = 0, rbo_ = 0, depth_ = 0;
  GLuint msaa_fbo_ = 0, msaa_rbo_ = 0, msaa_depth_ = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_CANVAS_RENDERBUFFER_H_
