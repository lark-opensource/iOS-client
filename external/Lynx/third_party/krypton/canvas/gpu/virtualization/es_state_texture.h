#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_TEXTURE_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_TEXTURE_H_

#include <vector>

#include "es_state_tracer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStateTexture : public ESStateTracer {
 public:
  void Save() override;
  void SetCurrent() override;
  EsStateTexture() {
    ::glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &max_texture_units_);
    max_texture_units_ = std::min(max_texture_units_, 32);
    active_texture_ = GL_TEXTURE0;
    sample_coverage_invert_ = false;
    sample_coverage_value_ = 1.0f;
  }

 public:
  struct TextureItem {
    GLint _2d_;
    GLint _3d_;
    GLint _2d_arr_;
    GLint cube_map_;
    GLint sampler_;
  };
  std::vector<TextureItem> textures_;
  GLint max_texture_units_;
  GLint active_texture_;

  GLfloat sample_coverage_value_;
  GLboolean sample_coverage_invert_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_TEXTURE_H_
