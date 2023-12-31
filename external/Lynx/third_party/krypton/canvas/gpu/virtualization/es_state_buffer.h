#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_BUFFER_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_BUFFER_H_

#include <vector>

#include "es_state_tracer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStateBuffer : public ESStateTracer {
 public:
  void Save() override;
  void SetCurrent() override;
  EsStateBuffer();

 private:
  GLint vbo_ = 0;
  GLint rbo_ = 0;
  GLint vao_ = 0;
  GLint tbo_ = 0;
  GLint ubo_ = 0;
  GLint copy_r_buffer_ = 0;
  GLint copy_w_buffer_ = 0;
  GLint pixel_pack_buffer_ = 0;
  GLint pixel_unpack_buffer_ = 0;
  GLint draw_fbo_ = 0;
  GLint read_fbo_ = 0;
  std::vector<GLint> draw_buffer_;
  static GLint max_draw_buffer_size;

  // different canvas will only have data conflicts where
  // vao == 0, so you only need
  // to save and write back scenes with vao == 0
  GLint ebo_ = 0;

  struct VertexAttribItem {
    GLint enabled;
    GLint size;
    GLint type;
    GLint normalized;
    GLint stride;
    GLvoid* pointer = nullptr;
    GLint vbo_binding;
    GLfloat vertex_attrib[4];
    GLint divisor;
  };
  std::vector<VertexAttribItem> vertex_attrib_;
  static GLint max_vertex_attribs_size_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_BUFFER_H_
