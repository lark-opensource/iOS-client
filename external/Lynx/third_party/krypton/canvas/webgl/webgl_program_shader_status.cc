// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_program_shader_status.h"

namespace lynx {
namespace canvas {

WebGLProgramShaderStatus::WebGLProgramShaderStatus() {}

WebGLProgramUniform& WebGLProgramShaderStatus::GetUniformByLocation(
    int32_t location) {
  for (auto& uniform : uniforms) {
    if (uniform.location_ == location) {
      return uniform;
    }
  }

  // should never return invalid.
  DCHECK(false);
  static WebGLProgramUniform invalid("", 0, 0, -1, false);
  return invalid;
}

}  // namespace canvas
}  // namespace lynx
