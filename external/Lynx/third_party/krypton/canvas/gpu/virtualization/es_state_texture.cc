
#include "es_state_texture.h"

#include "canvas/base/log.h"
namespace lynx {
namespace canvas {

void EsStateTexture::Save() {
  ::glGetIntegerv(GL_ACTIVE_TEXTURE, &active_texture_);
  textures_.resize(max_texture_units_);
  for (int i = 0; i < (int)max_texture_units_; ++i) {
    auto& item = textures_[i];
    ::glActiveTexture(GL_TEXTURE0 + i);
    ::glGetIntegerv(GL_TEXTURE_BINDING_2D, &item._2d_);
    ::glGetIntegerv(GL_TEXTURE_BINDING_2D_ARRAY, &item._2d_arr_);
    ::glGetIntegerv(GL_TEXTURE_BINDING_3D, &item._3d_);
    ::glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &item.cube_map_);
    ::glGetIntegerv(GL_SAMPLER_BINDING, &item.sampler_);
  }
  ::glActiveTexture(active_texture_);

  ::glGetFloatv(GL_SAMPLE_COVERAGE_VALUE, &sample_coverage_value_);
  ::glGetBooleanv(GL_SAMPLE_COVERAGE_INVERT, &sample_coverage_invert_);

  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStateTexture::SetCurrent() {
  for (int i = 0; i < (int)textures_.size(); ++i) {
    auto& item = textures_[i];
    ::glActiveTexture(GL_TEXTURE0 + i);
    ::glBindSampler(i, item.sampler_);
    ::glBindTexture(GL_TEXTURE_2D, item._2d_);
    ::glBindTexture(GL_TEXTURE_3D, item._3d_);
    ::glBindTexture(GL_TEXTURE_2D_ARRAY, item._2d_arr_);
    ::glBindTexture(GL_TEXTURE_CUBE_MAP, item.cube_map_);
  }
  ::glActiveTexture(active_texture_);

  ::glSampleCoverage(sample_coverage_value_, sample_coverage_invert_);

  DCHECK(::glGetError() == GL_NO_ERROR);
}
}  // namespace canvas
}  // namespace lynx
