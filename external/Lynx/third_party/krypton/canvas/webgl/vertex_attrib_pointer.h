#ifndef CANVAS_WEBGL_VERTEX_ATTRIB_POINTER_H_
#define CANVAS_WEBGL_VERTEX_ATTRIB_POINTER_H_

#include "canvas/util/js_object_pair.h"
#include "canvas/webgl/webgl_buffer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class VertexAttribPointer final {
 public:
  GLint size_ = 4;
  GLint array_elem_type_ = GL_FLOAT;  // array_buffer_'s type
  GLint stride_ = 0;
  int64_t offset_ = 0;
  bool normalized_ = false;
  bool enable_ = false;
  JsObjectPair<WebGLBuffer> array_buffer_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_VERTEX_ATTRIB_POINTER_H_
