// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_SCOPED_GL_RESET_RESTORE_H_
#define CANVAS_GPU_GL_SCOPED_GL_RESET_RESTORE_H_

#include <functional>

#include "gl_api.h"

namespace lynx {
namespace canvas {
class ScopedGLResetRestore {
 public:
  ScopedGLResetRestore(GLenum target);

  ~ScopedGLResetRestore();

 private:
  std::function<void()> reset_fn_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_SCOPED_GL_RESET_RESTORE_H_
