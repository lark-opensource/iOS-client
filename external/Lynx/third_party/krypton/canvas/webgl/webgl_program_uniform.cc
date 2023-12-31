// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_program_uniform.h"

namespace lynx {
namespace canvas {

WebGLProgramUniform::WebGLProgramUniform(std::string name, uint32_t type,
                                         uint32_t size, int32_t location,
                                         bool standalone)
    : name_(std::move(name)),
      type_(type),
      size_(size),
      location_(location),
      standalone(standalone) {}

}  // namespace canvas
}  // namespace lynx
