#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_MISC_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_MISC_H_

#include "es_state_tracer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStateMisc : public ESStateTracer {
 public:
  void Save() override;
  void SetCurrent() override;

 private:
  GLint cull_face_mode_ = GL_BACK;

  GLint depth_func_ = GL_LESS;
  GLfloat depth_clear_ = 1.0f;
  GLfloat depth_range_[2];
  GLboolean depth_mask_ = true;

  GLint front_face_ = GL_CCW;
  GLint hint_generate_mipmap_ = GL_DONT_CARE;
  GLint viewport_[4] = {0, 0, 1, 1};
  GLint scissor_box_[4] = {0, 0, 1, 1};
  GLfloat color_clear_[4] = {0.0f};
  GLfloat blend_color_[4] = {0.0f};
  GLint blend_equation_rgb_ = GL_FUNC_ADD;
  GLint blend_equation_alpha_ = GL_FUNC_ADD;
  GLint blend_src_rgb_ = GL_ONE;
  GLint blend_src_alpha_ = GL_ONE;
  GLint blend_dest_rgb_ = GL_ZERO;
  GLint blend_dest_alpha_ = GL_ZERO;

  GLfloat line_width_ = 1.0f;

  GLfloat polygon_offset_factor_ = 0.0f;
  GLfloat polygon_offset_units_ = 0.0f;
  GLint program_ = GL_NONE;
  GLboolean color_mask_[4] = {1, 1, 1, 1};
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_MISC_H_
