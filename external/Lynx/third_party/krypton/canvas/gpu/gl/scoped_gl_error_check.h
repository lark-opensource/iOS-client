// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_SCOPED_GL_ERROR_CHECK_H_
#define CANVAS_GPU_GL_SCOPED_GL_ERROR_CHECK_H_

#include "canvas/base/log.h"
#include "canvas/gpu/gl/gl_api.h"

#ifndef NDEBUG
#define ENABLE_GL_ERROR_CHECK 1
#endif

// TODO(luchengxuan) change to reset gl error by ourself to avoid others dep on
// glerror
#if ENABLE_GL_ERROR_CHECK
#define DCHECK_SCOPED_NO_GL_ERROR ScopedGLErrorCheck scoped_gl_error_check
#else
#define DCHECK_SCOPED_NO_GL_ERROR
#endif

namespace lynx {
namespace canvas {
class ScopedGLErrorCheck {
 public:
  ScopedGLErrorCheck() : last_error_(GL::GetError()) {}

  ~ScopedGLErrorCheck() {
    int err = GL::GetError();
    DCHECK(err == GL_NO_ERROR);
    if (err) {
      KRYPTON_LOGE("throw gl err") << err;
    }

    if (last_error_ != GL_NO_ERROR) {
      GL::SetError(last_error_);
    }
  }

 private:
  GLenum last_error_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_SCOPED_GL_ERROR_CHECK_H_
