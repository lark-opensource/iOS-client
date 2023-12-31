// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_shader_precision_format.h"

namespace lynx {
namespace canvas {

GLint WebGLShaderPrecisionFormat::GetRangeMin() const { return range_min_; }

GLint WebGLShaderPrecisionFormat::GetRangeMax() const { return range_max_; }

GLint WebGLShaderPrecisionFormat::GetPrecision() const { return precision_; }

WebGLShaderPrecisionFormat::WebGLShaderPrecisionFormat(GLint min, GLint max,
                                                       GLint precision)
    : range_min_(min), range_max_(max), precision_(precision) {}

}  // namespace canvas
}  // namespace lynx
