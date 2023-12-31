
#include "es_state_misc.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {

void EsStateMisc::Save() {
  ::glGetIntegerv(GL_CULL_FACE_MODE, &cull_face_mode_);
  ::glGetIntegerv(GL_DEPTH_FUNC, &depth_func_);
  ::glGetIntegerv(GL_FRONT_FACE, &front_face_);
  ::glGetIntegerv(GL_GENERATE_MIPMAP_HINT, &hint_generate_mipmap_);
  ::glGetIntegerv(GL_VIEWPORT, &viewport_[0]);
  ::glGetIntegerv(GL_SCISSOR_BOX, &scissor_box_[0]);
  ::glGetFloatv(GL_COLOR_CLEAR_VALUE, &color_clear_[0]);
  // blend
  ::glGetFloatv(GL_BLEND_COLOR, &blend_color_[0]);
  ::glGetIntegerv(GL_BLEND_EQUATION_RGB, &blend_equation_rgb_);
  ::glGetIntegerv(GL_BLEND_EQUATION_ALPHA, &blend_equation_alpha_);
  ::glGetIntegerv(GL_BLEND_SRC_RGB, &blend_src_rgb_);
  ::glGetIntegerv(GL_BLEND_SRC_ALPHA, &blend_src_alpha_);
  ::glGetIntegerv(GL_BLEND_DST_RGB, &blend_dest_rgb_);
  ::glGetIntegerv(GL_BLEND_DST_ALPHA, &blend_dest_alpha_);

  ::glGetFloatv(GL_DEPTH_CLEAR_VALUE, &depth_clear_);
  ::glGetFloatv(GL_DEPTH_RANGE, &depth_range_[0]);
  ::glGetFloatv(GL_LINE_WIDTH, &line_width_);

  ::glGetFloatv(GL_POLYGON_OFFSET_FACTOR, &polygon_offset_factor_);
  ::glGetFloatv(GL_POLYGON_OFFSET_UNITS, &polygon_offset_units_);
  ::glGetIntegerv(GL_CURRENT_PROGRAM, &program_);
  ::glGetBooleanv(GL_COLOR_WRITEMASK, &color_mask_[0]);
  ::glGetBooleanv(GL_DEPTH_WRITEMASK, &depth_mask_);

  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStateMisc::SetCurrent() {
  if (program_ == GL_NONE) {
    ::glUseProgram(GL_NONE);
  } else {
    // if program is invalid, skip
    // as delete bound program may produce this
    // TODO(luchengxuan) workaround, need handle this situation by refcount
    if (::glIsProgram(program_)) {
      GLint linked;
      glGetProgramiv(program_, GL_LINK_STATUS, &linked);
      if (linked == GL_TRUE) {
        ::glUseProgram(program_);
      } else {
        // maybe shader is detached
        ::glUseProgram(GL_NONE);
        KRYPTON_LOGW("SetCurrent but proram_ is not linked.");
      }
    } else {
      ::glUseProgram(GL_NONE);
      KRYPTON_LOGW("SetCurrent but proram_ is invalid.");
    }
  }
  DCHECK(::glGetError() == GL_NO_ERROR);
  ::glColorMask(color_mask_[0], color_mask_[1], color_mask_[2], color_mask_[3]);
  ::glCullFace(cull_face_mode_);
  ::glDepthFunc(depth_func_);
  ::glDepthMask(depth_mask_);
  ::glClearDepthf(depth_clear_);
  ::glDepthRangef(depth_range_[0], depth_range_[1]);
  ::glFrontFace(front_face_);
  ::glHint(GL_GENERATE_MIPMAP_HINT, hint_generate_mipmap_);
  ::glLineWidth(line_width_);
  ::glPolygonOffset(polygon_offset_factor_, polygon_offset_units_);
  ::glViewport(viewport_[0], viewport_[1], viewport_[2], viewport_[3]);
  ::glScissor(scissor_box_[0], scissor_box_[1], scissor_box_[2],
              scissor_box_[3]);
  ::glClearColor(color_clear_[0], color_clear_[1], color_clear_[2],
                 color_clear_[3]);
  ::glBlendColor(blend_color_[0], blend_color_[1], blend_color_[2],
                 blend_color_[3]);
  ::glBlendEquationSeparate(blend_equation_rgb_, blend_equation_alpha_);
  ::glBlendFuncSeparate(blend_src_rgb_, blend_dest_rgb_, blend_src_alpha_,
                        blend_dest_alpha_);

  DCHECK(::glGetError() == GL_NO_ERROR);
}
}  // namespace canvas
}  // namespace lynx
