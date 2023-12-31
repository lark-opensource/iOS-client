// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_SHADER_PRECISION_FORMAT_H_
#define CANVAS_WEBGL_WEBGL_SHADER_PRECISION_FORMAT_H_

#include "jsbridge/napi/base.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class WebGLShaderPrecisionFormat : public ImplBase {
 public:
  WebGLShaderPrecisionFormat(GLint min, GLint max, GLint precision);

  GLint GetRangeMin() const;
  GLint GetRangeMax() const;
  GLint GetPrecision() const;

 private:
  GLint range_min_ = 0;
  GLint range_max_ = 0;
  GLint precision_ = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_SHADER_PRECISION_FORMAT_H_
