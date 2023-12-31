
#include "es_state_enabled.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {

inline void enable_and_disable(GLenum cap, bool enable) {
  if (enable) {
    ::glEnable(cap);
  } else {
    ::glDisable(cap);
  }
}

void EsStateEnabled::Save() {
  ::glGetBooleanv(GL_BLEND, &blend_);
  ::glGetBooleanv(GL_CULL_FACE, &cull_face_);
  ::glGetBooleanv(GL_DEPTH_TEST, &depth_test_);
  ::glGetBooleanv(GL_DITHER, &dither_);
  ::glGetBooleanv(GL_POLYGON_OFFSET_FILL, &polygon_offset_fill_);
  ::glGetBooleanv(GL_SAMPLE_ALPHA_TO_COVERAGE, &sample_alpha_to_coverage_);
  ::glGetBooleanv(GL_SAMPLE_COVERAGE, &sample_coverage_);
  ::glGetBooleanv(GL_SCISSOR_TEST, &scissor_test_);
  ::glGetBooleanv(GL_STENCIL_TEST, &stencil_test_);
  ::glGetBooleanv(GL_RASTERIZER_DISCARD, &rasterizer_discard_);
  ::glGetBooleanv(GL_PRIMITIVE_RESTART_FIXED_INDEX,
                  &primitive_restart_fixed_index_);
  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStateEnabled::SetCurrent() {
  enable_and_disable(GL_BLEND, blend_);
  enable_and_disable(GL_CULL_FACE, cull_face_);
  enable_and_disable(GL_DEPTH_TEST, depth_test_);
  enable_and_disable(GL_DITHER, dither_);
  enable_and_disable(GL_POLYGON_OFFSET_FILL, polygon_offset_fill_);
  enable_and_disable(GL_SAMPLE_ALPHA_TO_COVERAGE, sample_alpha_to_coverage_);
  enable_and_disable(GL_SAMPLE_COVERAGE, sample_coverage_);
  enable_and_disable(GL_SCISSOR_TEST, scissor_test_);
  enable_and_disable(GL_STENCIL_TEST, stencil_test_);
  enable_and_disable(GL_RASTERIZER_DISCARD, rasterizer_discard_);
  enable_and_disable(GL_PRIMITIVE_RESTART_FIXED_INDEX,
                     primitive_restart_fixed_index_);
  DCHECK(::glGetError() == GL_NO_ERROR);
}
}  // namespace canvas
}  // namespace lynx
