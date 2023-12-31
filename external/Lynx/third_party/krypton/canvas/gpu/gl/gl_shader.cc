// Copyright 2021 The Lynx Authors. All rights reserved.

#include "gl_shader.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
GLShader::GLShader(GLenum type, GLsizei count, const GLchar *const *string,
                   const GLint *length) {
  if (!string) return;
  shader_ = GL::CreateShader(type);
  GL::ShaderSource(shader_, count, string, length);
  GL::CompileShader(shader_);
  int success;
  char infoLog[512];
  GL::GetShaderiv(shader_, GL_COMPILE_STATUS, &success);
  if (!success) {
    GL::GetShaderInfoLog(shader_, 512, NULL, infoLog);
    KRYPTON_LOGE(" GLProgram ")
        << "compile " << (type == GL_VERTEX_SHADER ? "vertex" : "fragment")
        << " shader failed \n"
        << infoLog << std::endl;
    return;
  }
}

GLShader::~GLShader() { GL::DeleteShader(shader_); }

GLint GLShader::Shader() { return shader_; }
}  // namespace canvas
}  // namespace lynx
