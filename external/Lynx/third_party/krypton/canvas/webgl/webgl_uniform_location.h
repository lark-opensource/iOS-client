// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_UNIFORM_LOCATION_H_
#define CANVAS_WEBGL_WEBGL_UNIFORM_LOCATION_H_

#include "canvas/util/js_object_pair.h"
#include "canvas/webgl/webgl_program.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class WebGLUniformLocation : public ImplBase {
 public:
  WebGLUniformLocation(WebGLProgram* program, GLint location);

  WebGLProgram* Program() const;

  GLint Location() const;

 private:
  JsObjectPair<WebGLProgram> program_;
  GLint location_;
  unsigned link_count_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_UNIFORM_LOCATION_H_
