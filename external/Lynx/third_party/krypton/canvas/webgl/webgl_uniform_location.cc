// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_uniform_location.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {

WebGLUniformLocation::WebGLUniformLocation(WebGLProgram* program,
                                           GLint location)
    : program_(program), location_(location) {
  DCHECK(program);
  link_count_ = program->LinkCount();
}

WebGLProgram* WebGLUniformLocation::Program() const {
  if (program_->LinkCount() != link_count_) {
    return nullptr;
  }
  return program_;
}

GLint WebGLUniformLocation::Location() const { return location_; }
}  // namespace canvas
}  // namespace lynx
