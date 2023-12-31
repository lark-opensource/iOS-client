
#include "es_state_uniform_binding_point.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {

void EsStateUniformBindingPoint::Save() {
  GLint max_uniform_bind_points = 0;
  glGetIntegerv(GL_MAX_UNIFORM_BUFFER_BINDINGS, &max_uniform_bind_points);
  binding_points_.resize(max_uniform_bind_points);
  for (int i = 0; i < max_uniform_bind_points; ++i) {
    auto& item = binding_points_[i];
    ::glGetInteger64i_v(GL_UNIFORM_BUFFER_BINDING, i, &item.buffer_);
    ::glGetInteger64i_v(GL_UNIFORM_BUFFER_SIZE, i, &item.size_);
    ::glGetInteger64i_v(GL_UNIFORM_BUFFER_START, i, &item.offset_);
  }
  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStateUniformBindingPoint::SetCurrent() {
  for (int i = 0; i < (int)binding_points_.size(); ++i) {
    auto& item = binding_points_[i];
    if (0 == item.buffer_ || 0 == item.size_) {
      ::glBindBufferBase(GL_UNIFORM_BUFFER, i, item.buffer_);
    } else {
      ::glBindBufferRange(GL_UNIFORM_BUFFER, i, item.buffer_, item.offset_,
                          item.size_);
    }
  }
  DCHECK(::glGetError() == GL_NO_ERROR);
}
}  // namespace canvas
}  // namespace lynx
