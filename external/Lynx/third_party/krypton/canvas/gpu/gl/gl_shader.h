// Copyright 2021 The Lynx Authors. All rights reserved.

#include "gl_api.h"

#ifndef CANVAS_GPU_GL_GL_SHADER_H_
#define CANVAS_GPU_GL_GL_SHADER_H_

namespace lynx {
namespace canvas {

class GLShader {
 public:
  GLShader(GLenum type, GLsizei count, const GLchar *const *string,
           const GLint *length);

  ~GLShader();

  GLint Shader();

 private:
  GLint shader_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_GL_SHADER_H_
