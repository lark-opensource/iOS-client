// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IOS_GL_CONTEXT_IOS_H_
#define CANVAS_IOS_GL_CONTEXT_IOS_H_

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/CAEAGLLayer.h>

#include "canvas/base/log.h"
#include "canvas/gpu/gl_context.h"

namespace lynx {
namespace canvas {
class GLContextIOS final : public GLContext {
 public:
  GLContextIOS();
  ~GLContextIOS() override {
    *ThreadLocalRealContextPtr() = nullptr;
    KRYPTON_DESTRUCTOR_LOG(GLContextIOS);
  };

  void Init() override;

  EAGLContext *context() { return context_; }

  bool MakeCurrent(GLSurface *gl_surface) override;
  bool IsCurrent(GLSurface *gl_surface) override;
  void ClearCurrent() override;

  bool IsRealContext() const override { return true; }

 private:
  EAGLContext *context_;

  // disallow copy&assign
  GLContextIOS(const GLContextIOS &) = delete;
  GLContextIOS &operator==(const GLContextIOS &) = delete;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IOS_GL_CONTEXT_IOS_H_
