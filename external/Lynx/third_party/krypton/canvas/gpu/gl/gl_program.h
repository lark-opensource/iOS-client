// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_GL_PROGRAM_H_
#define CANVAS_GPU_GL_GL_PROGRAM_H_

#include <memory>
#include <unordered_map>

#include "canvas/gpu/gl/gl_api.h"
#include "gl_shader.h"

namespace lynx {
namespace canvas {

class GLProgram {
 public:
  GLProgram(std::unique_ptr<GLShader> vertex_shader,
            std::unique_ptr<GLShader> fragment_shader);

  ~GLProgram();

  GLint Program();

  void Use();

  void SetUniform1i(const char* loc, int val);
  void SetUniformMatrix4f(const char* loc, float* matrix);

 private:
  GLint program_;

  std::unordered_map<const char*, int> loc_map_;
  int GetUniformLocation(const char* name);
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_GL_PROGRAM_H_
