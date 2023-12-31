// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_gpu_context.h"

#include "animax/base/log.h"

namespace lynx {
namespace animax {

static GLuint CreateShader(const char *source, GLenum type) {
  GLuint shader = glCreateShader(type);

  GLint success;
  glShaderSource(shader, 1, &source, nullptr);
  glCompileShader(shader);
  glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
  if (!success) {
    GLchar info_log[1024];
    glGetShaderInfoLog(shader, 1204, nullptr, info_log);
    LOGE("shader compile error ") << info_log;
    return 0;
  }

  return shader;
}

static GLuint CreateProgram(const char *vs_code, const char *fs_code) {
  GLuint program = glCreateProgram();
  GLint success;

  GLuint vs = CreateShader(vs_code, GL_VERTEX_SHADER);
  GLuint fs = CreateShader(fs_code, GL_FRAGMENT_SHADER);

  glAttachShader(program, vs);
  glAttachShader(program, fs);
  glLinkProgram(program);
  glGetProgramiv(program, GL_LINK_STATUS, &success);

  if (!success) {
    GLchar info_log[1024];
    glGetProgramInfoLog(program, 1024, nullptr, info_log);
    LOGE("program link error ") << info_log;
    return 0;
  }

  return program;
}

void FXAAGPUContext::MakeCurrent() {
  glBindFramebuffer(GL_FRAMEBUFFER, GetFramebufferID());
  glViewport(0, 0, width_, height_);
  glScissor(0, 0, width_, height_);
  glEnable(GL_STENCIL_TEST);
  glEnable(GL_SCISSOR_TEST);

  glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
}

void FXAAGPUContext::Flush() {
  glBindFramebuffer(GL_FRAMEBUFFER, screen_fbo_);
  glDisable(GL_STENCIL_TEST);
  glDisable(GL_SCISSOR_TEST);
  glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

  DoFilter();
}

void FXAAGPUContext::InitShader() {
  auto vs = R"(#version 300 es
        precision highp float;
        precision mediump int;


        layout (location = 0) in vec2 aPos;
        layout (location = 1) in vec2 aUV;

        out vec2 vUV;

        void main() {
            vUV = aUV;
            gl_Position = vec4(aPos, 0.0, 1.0);
        }
      )";

  auto fs = R"(#version 300 es
      precision highp float;
      precision mediump int;

      uniform sampler2D tex;

      in vec2 vUV;

      out vec4 FragColor;



      #define FXAA_SPAN_MAX 4.0
      #define FXAA_REDUCE_MIN (1.0 / 64.0)
      #define FXAA_REDUCE_MUL (1.0 / 2.0)


      void main() {
        ivec2 resolution = textureSize(tex, 0);
        vec2 texelSize = 1.0 / vec2(resolution.x, resolution.y);

        vec3 luma = vec3(0.299, 0.587, 0.114);
        float lumaTL = dot(luma, texture(tex, vUV + (vec2(-1.0, -1.0) * texelSize)).xyz);
        float lumaTR = dot(luma, texture(tex, vUV + (vec2(1.0, -1.0) * texelSize)).xyz);
        float lumaBL = dot(luma, texture(tex, vUV + (vec2(-1.0, 1.0) * texelSize)).xyz);
        float lumaBR = dot(luma, texture(tex, vUV + (vec2(1.0, 1.0) * texelSize)).xyz);
        float lumaM  = dot(luma, texture(tex, vUV).xyz);

        vec2 dir;
        dir.x = -((lumaTL + lumaTR) - (lumaBL + lumaBR));
        dir.y = ((lumaTL + lumaBL) - (lumaTR + lumaBR));

        float dirReduce = max((lumaTL + lumaTR + lumaBL + lumaBR) * (FXAA_REDUCE_MUL * 0.25), FXAA_REDUCE_MIN);
        float inverseDirAdjustment = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);

        dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
            max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX), dir * inverseDirAdjustment)) * texelSize;


        vec4 result1 = (1.0/2.0) * (
          texture(tex, vUV + (dir * vec2(1.0/3.0 - 0.5))) +
          texture(tex, vUV + (dir * vec2(2.0/3.0 - 0.5))));

        vec4 result2 = result1 * (1.0/2.0) + (1.0/4.0) * (
          texture(tex, vUV + (dir * vec2(0.0/3.0 - 0.5)))+
          texture(tex, vUV + (dir * vec2(3.0/3.0 - 0.5))));


        float lumaMin = min(lumaM, min(min(lumaTL, lumaTR), min(lumaBL, lumaBR)));
        float lumaMax = max(lumaM, max(max(lumaTL, lumaTR), max(lumaBL, lumaBR)));
        float lumaResult2 = dot(luma, result2.xyz);

        if(lumaResult2 < lumaMin || lumaResult2 > lumaMax)
          FragColor = result1;
        else
          FragColor = result2;
      }
    )";

  shader_ = CreateProgram(vs, fs);

  loc_tex_ = glGetUniformLocation(shader_, "tex");
}

void FXAAGPUContext::InitBuffer() {
  glGenBuffers(1, &vbo_);

  std::vector<float> vertex{
      -1.f, -1.f, 0.f, 0.f,  // v1
      1.f,  -1.f, 1.f, 0.f,  // v2
      -1.f, 1.f,  0.f, 1.f,  // v3
      1.f,  1.f,  1.f, 1.f,  // v4
  };

  glBindBuffer(GL_ARRAY_BUFFER, vbo_);
  glBufferData(GL_ARRAY_BUFFER, vertex.size() * sizeof(float), vertex.data(),
               GL_STATIC_DRAW);
}

void FXAAGPUContext::DoFilter() {
  glUseProgram(shader_);
  glBindVertexArray(0);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_);

  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float),
                        reinterpret_cast<void *>(0));
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float),
                        reinterpret_cast<void *>(2 * sizeof(float)));

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, filter_tex_);

  glUniform1i(loc_tex_, 0);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void MSAAGPUContext::MakeCurrent() {
  glBindFramebuffer(GL_FRAMEBUFFER, GetFramebufferID());
  glViewport(0, 0, width_, height_);
  glScissor(0, 0, width_, height_);
  glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
}

void MSAAGPUContext::Flush() {
  glBindFramebuffer(GL_FRAMEBUFFER, screen_fbo_);

  glBindFramebuffer(GL_READ_FRAMEBUFFER, GetFramebufferID());

  glBlitFramebuffer(0, 0, width_, height_, 0, 0, width_, height_,
                    GL_COLOR_BUFFER_BIT, GL_LINEAR);
}

}  // namespace animax
}  // namespace lynx
