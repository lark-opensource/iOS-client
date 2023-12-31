// Copyright 2021 The Lynx Authors. All rights reserved.

#include "texture_shader.h"

namespace lynx {
namespace canvas {
TextureShader::~TextureShader() {
  GL::DeleteBuffers(1, &vbo_);
  GL::DeleteBuffers(1, &ebo_);
  GL::DeleteVertexArrays(1, &vao_);
}

const char* TextureShader::VertexShaderSource() {
  return "attribute vec2 aPos;\n"
         "attribute vec2 aTexCoord;\n"
         "varying highp vec4 texCoord;\n"
         "void main() {\n"
         "    gl_Position = vec4(aPos, 0.0, 1.0);\n"
         "    texCoord = vec4(aTexCoord, 0.0, 1.0);\n"
         "}";
}

const char* TextureShader::FragmentShaderSource() {
  return "varying highp vec4 texCoord;\n"
         "uniform bool flipY;\n"
         "uniform bool premulAlpha;\n"
         "uniform bool hasPremulAlpha;\n"
         "uniform sampler2D ourTexture;\n"
         "void main() {\n"
         "  highp vec2 pos = texCoord.xy;\n"
         "  if (flipY) {\n"
         "    pos = vec2(pos.x, 1. - pos.y);\n"
         "  }\n"
         "  highp vec4 color = texture2D(ourTexture, pos);\n"
         "  if (premulAlpha) {\n"
         "    if (!hasPremulAlpha) {\n"
         "      color = vec4(color.rgb * color.a, color.a);\n"
         "    }\n"
         "  } else {\n"
         "    if (color.a != 0.0 && hasPremulAlpha) {\n"
         "       color = vec4(color.rgb / color.a, color.a);\n"
         "    }\n"
         "  }\n"
         "  gl_FragColor = color;\n"
         "}";
}

void TextureShader::InitOnGPU() {
  const char* vertex_source = VertexShaderSource();
  const GLint vertex_shader_length[] = {
      static_cast<GLint>(strlen(vertex_source))};
  const char* fragment_source = FragmentShaderSource();
  const GLint fragment_shader_length[] = {
      static_cast<GLint>(strlen(fragment_source))};
  program_ = std::make_unique<GLProgram>(
      std::make_unique<GLShader>(GL_VERTEX_SHADER, 1, &vertex_source,
                                 vertex_shader_length),
      std::make_unique<GLShader>(GL_FRAGMENT_SHADER, 1, &fragment_source,
                                 fragment_shader_length));

  ScopedGLResetRestore s(GL_VERTEX_ARRAY_BINDING);
  ScopedGLResetRestore s0(GL_ARRAY_BUFFER_BINDING);
  ScopedGLResetRestore s1(GL_ELEMENT_ARRAY_BUFFER_BINDING);

  GL::GenVertexArrays(1, &vao_);
  GL::BindVertexArray(vao_);

  float vertices[] = {1.f,  1.f,  1.f, 1.f, 1.f,  -1.f, 1.f, 0.f,
                      -1.f, -1.f, 0.f, 0.f, -1.f, 1.f,  0.f, 1.f};
  GL::GenBuffers(1, &vbo_);
  GL::BindBuffer(GL_ARRAY_BUFFER, vbo_);
  GL::BufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

  unsigned int indices[] = {0, 1, 3, 1, 2, 3};
  GL::GenBuffers(1, &ebo_);
  GL::BindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo_);
  GL::BufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices,
                 GL_STATIC_DRAW);

  int aPosLoc = GL::GetAttribLocation(program_->Program(), "aPos");
  GL::VertexAttribPointer(aPosLoc, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float),
                          (void*)0);
  GL::EnableVertexAttribArray(aPosLoc);

  int aTexCoordLoc = GL::GetAttribLocation(program_->Program(), "aTexCoord");
  GL::VertexAttribPointer(aTexCoordLoc, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float), (void*)(2 * sizeof(float)));
  GL::EnableVertexAttribArray(aTexCoordLoc);

  ready_ = true;
}

void TextureShader::Draw(GLuint texture, bool flip_y, bool premul_alpha,
                         bool has_premul_alpha) {
  SCOPED_GL_DISABLE_RESET_RESTORE()

  ScopedGLResetRestore s0(GL_CURRENT_PROGRAM);
  program_->Use();
  program_->SetUniform1i("ourTexture", 0);
  program_->SetUniform1i("flipY", flip_y);
  program_->SetUniform1i("premulAlpha", premul_alpha);
  program_->SetUniform1i("hasPremulAlpha", has_premul_alpha);

  ScopedGLResetRestore s1(GL_VERTEX_ARRAY_BINDING);
  GL::BindVertexArray(vao_);

  ScopedGLResetRestore s2(GL_ACTIVE_TEXTURE);
  GL::ActiveTexture(GL_TEXTURE0);
  {
    ScopedGLResetRestore s3(GL_TEXTURE_BINDING_2D);
    GL::BindTexture(GL_TEXTURE_2D, texture);

    ScopedGLResetRestore s4(GL_ELEMENT_ARRAY_BUFFER_BINDING);
    GL::BindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo_);
    GL::DrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
  }
}

bool TextureShader::IsReady() { return ready_; }
}  // namespace canvas
}  // namespace lynx
