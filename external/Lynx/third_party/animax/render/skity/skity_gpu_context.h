// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_GPU_CONTEXT_H_
#define ANIMAX_RENDER_SKITY_SKITY_GPU_CONTEXT_H_

#include "skity/gpu/gpu_gl_context.hpp"

#if OS_IOS
#import <OpenGLES/ES3/gl.h>
#else
#include <GLES3/gl3.h>
#endif

#include <vector>

namespace lynx {
namespace animax {

class FXAAGPUContext : public skity::GPUGLContext {
 public:
  FXAAGPUContext(void *proc_address_func, int fbo, int screen_fbo,
                 int filter_tex, int32_t width, int32_t height)
      : GPUGLContext(proc_address_func, fbo),
        screen_fbo_(screen_fbo),
        filter_tex_(filter_tex),
        width_(width),
        height_(height) {
    InitFilter();
  }

  ~FXAAGPUContext() override { CleanUpFilter(); }

  void MakeCurrent() override;

  void Flush() override;

 private:
  void InitFilter() {
    InitShader();
    InitBuffer();
  }

  void CleanUpFilter() {
    glDeleteProgram(shader_);
    glDeleteBuffers(1, &vbo_);
  }

  void InitShader();

  void InitBuffer();

  void DoFilter();

 private:
  int32_t screen_fbo_ = 0;
  int32_t filter_tex_ = 0;
  int32_t width_ = 0;
  int32_t height_ = 0;
  GLuint shader_ = 0;
  GLuint vbo_ = 0;
  int32_t loc_tex_ = -1;
};

class MSAAGPUContext : public skity::GPUGLContext {
 public:
  MSAAGPUContext(void *proc_address_func, int fbo, int screen_fbo,
                 int32_t width, int32_t height)
      : GPUGLContext(proc_address_func, fbo),
        screen_fbo_(screen_fbo),
        width_(width),
        height_(height) {}

  ~MSAAGPUContext() override = default;

  void MakeCurrent() override;

  void Flush() override;

 private:
  int32_t screen_fbo_;
  int32_t width_;
  int32_t height_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_GPU_CONTEXT_H_
