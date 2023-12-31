// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_VERTEX_ATTRIB_VALUES_H_
#define CANVAS_WEBGL_VERTEX_ATTRIB_VALUES_H_

#include "canvas/gpu/gl_constants.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class VertexAttribValues final {
 public:
  uint32_t attr_type_ = KR_GL_FLOAT;  // value_'s type
  union {
    float f_[4] = {0.f, 0.f, 0.f, 1.f};
    int32_t i_[4];
    uint32_t ui_[4];
  } value_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_VERTEX_ATTRIB_VALUES_H_
