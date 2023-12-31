// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_TEXTURE_SHADER_H_
#define CANVAS_GPU_TEXTURE_SHADER_H_

#include <memory>
#include <string>

#include "canvas/gpu/gl/gl_program.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"

#define SCOPED_GL_DISABLE_RESET_RESTORE()    \
  ScopedGLResetRestore ss0(GL_CULL_FACE);    \
  ScopedGLResetRestore ss1(GL_DEPTH_TEST);   \
  ScopedGLResetRestore ss2(GL_BLEND);        \
  ScopedGLResetRestore ss3(GL_STENCIL_TEST); \
  ScopedGLResetRestore ss4(GL_SCISSOR_TEST); \
  GL::Disable(GL_CULL_FACE);                 \
  GL::Disable(GL_DEPTH_TEST);                \
  GL::Disable(GL_BLEND);                     \
  GL::Disable(GL_STENCIL_TEST);              \
  GL::Disable(GL_SCISSOR_TEST);

namespace lynx {
namespace canvas {
class TextureShader {
 public:
  virtual ~TextureShader();

  virtual const char* VertexShaderSource();

  virtual const char* FragmentShaderSource();

  void InitOnGPU();

  virtual void Draw(GLuint texture, bool flip_y, bool premul_alpha,
                    bool has_premul_alpha);

  bool IsReady();

 protected:
  std::unique_ptr<GLProgram> program_{nullptr};
  GLuint vao_;
  GLuint vbo_;
  GLuint ebo_;

  bool ready_{false};
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_TEXTURE_SHADER_H_
