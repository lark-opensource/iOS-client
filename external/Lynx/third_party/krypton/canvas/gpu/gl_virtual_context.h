// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_VIRTUAL_CONTEXT_H_
#define CANVAS_GPU_GL_VIRTUAL_CONTEXT_H_

#include <memory>

#include "canvas/gpu/gl_context.h"
#include "canvas/gpu/virtualization/es_state.h"

namespace lynx {
namespace canvas {
class GLVirtualContext : public GLContext {
 public:
  GLVirtualContext(GLContext* real_context);
  ~GLVirtualContext();

  void Init() override;

  bool MakeCurrent(GLSurface* gl_surface) override;
  bool IsCurrent(GLSurface* gl_surface) override;
  void ClearCurrent() override;
  GLContext* GetRealContext() { return real_context_; }

  GLenum GetSavedError();
  void SetErrorToSave(GLenum error);

 private:
  GLContext* real_context_;
  std::unique_ptr<Estate> state_restorer_;
  GLenum error_ = GL_NO_ERROR;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_VIRTUAL_CONTEXT_H_
