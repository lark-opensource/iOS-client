// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_PROGRAM_SHADER_STATUS_H_
#define CANVAS_WEBGL_WEBGL_PROGRAM_SHADER_STATUS_H_

#include <string>
#include <unordered_map>

#include "canvas/gpu/command_buffer/puppet.h"
#include "webgl_program_attrib.h"
#include "webgl_program_uniform.h"

namespace lynx {
namespace canvas {

struct WebGLProgramShaderStatus {
  WebGLProgramShaderStatus();

  bool is_success = false;
  std::string program_info;
  int32_t num_active_attribs = 0;
  int32_t num_active_uniforms = 0;
  std::vector<WebGLProgramAttrib> attribs;
  std::vector<WebGLProgramUniform> uniforms;

  inline void reset() {
    is_success = false;
    program_info = "";
    attribs.clear();
    uniforms.clear();
    num_active_attribs = 0;
    num_active_uniforms = 0;
  }

  WebGLProgramUniform& GetUniformByLocation(int32_t location);
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_PROGRAM_SHADER_STATUS_H_
