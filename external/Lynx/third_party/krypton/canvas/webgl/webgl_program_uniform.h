// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_PROGRAM_UNIFORM_H_
#define CANVAS_WEBGL_WEBGL_PROGRAM_UNIFORM_H_

#include <string>

#include "canvas/gpu/gl_constants.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {

class WebGLProgramUniform {
 public:
  WebGLProgramUniform(std::string name, uint32_t type, uint32_t size,
                      int32_t location, bool standalone);

  bool IsSampler() const {
    switch (type_) {
      case KR_GL_SAMPLER_2D:
        //      case GL_SAMPLER_2D_RECT_ARB:
      case KR_GL_SAMPLER_CUBE:
      case KR_GL_SAMPLER_EXTERNAL_OES:
        //      case GL_SAMPLER_3D:
        //      case GL_SAMPLER_2D_SHADOW:
        //      case GL_SAMPLER_2D_ARRAY:
        //      case GL_SAMPLER_2D_ARRAY_SHADOW:
        //      case GL_SAMPLER_CUBE_SHADOW:
        //      case GL_INT_SAMPLER_2D:
        //      case GL_INT_SAMPLER_3D:
        //      case GL_INT_SAMPLER_CUBE:
        //      case GL_INT_SAMPLER_2D_ARRAY:
        //      case GL_UNSIGNED_INT_SAMPLER_2D:
        //      case GL_UNSIGNED_INT_SAMPLER_3D:
        //      case GL_UNSIGNED_INT_SAMPLER_CUBE:
        //      case GL_UNSIGNED_INT_SAMPLER_2D_ARRAY:
        return true;
      default:
        return false;
    }
  }

  std::string name_;
  uint32_t type_ = 0;
  uint32_t size_ = 0;
  int32_t location_ = -1;
  bool standalone = false;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_PROGRAM_UNIFORM_H_
