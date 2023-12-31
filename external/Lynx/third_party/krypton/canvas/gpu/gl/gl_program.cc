// Copyright 2021 The Lynx Authors. All rights reserved.

#include "gl_program.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
GLProgram::GLProgram(std::unique_ptr<GLShader> vertex_shader,
                     std::unique_ptr<GLShader> fragment_shader) {
  if (!vertex_shader || !fragment_shader) {
    KRYPTON_LOGE("GLProgram")
        << "create program failed, shader = null " << std::endl;
    return;
  }

  program_ = GL::CreateProgram();
  GL::AttachShader(program_, vertex_shader->Shader());
  GL::AttachShader(program_, fragment_shader->Shader());
  GL::LinkProgram(program_);

  int success;
  char infoLog[512];
  GL::GetProgramiv(program_, GL_LINK_STATUS, &success);
  if (!success) {
    GL::GetProgramInfoLog(program_, 512, NULL, infoLog);
    KRYPTON_LOGE(" GLProgram ") << "link program failed\n"
                                << infoLog << std::endl;
    return;
  }
}

GLProgram::~GLProgram() {
  GLint p;
  GL::GetIntegerv(GL_CURRENT_PROGRAM, &p);
  if (p == program_) {
    GL::UseProgram(0);
  }
  GL::DeleteProgram(program_);
}

GLint GLProgram::Program() { return program_; }

void GLProgram::Use() { GL::UseProgram(program_); }

int GLProgram::GetUniformLocation(const char* name) {
  int loc_;
  auto i = loc_map_.find(name);
  if (i == loc_map_.end()) {
    loc_ = GL::GetUniformLocation(program_, name);
    if (loc_ == -1) return loc_;
    loc_map_[name] = loc_;
  } else {
    loc_ = i->second;
  }
  return loc_;
}

void GLProgram::SetUniform1i(const char* loc, int val) {
  GL::Uniform1i(GetUniformLocation(loc), val);
}

void GLProgram::SetUniformMatrix4f(const char* loc, float* matrix) {
  GL::UniformMatrix4fv(GetUniformLocation(loc), 1, false, matrix);
}
}  // namespace canvas
}  // namespace lynx
