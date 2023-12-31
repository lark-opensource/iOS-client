
#include "es_state_stencil.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {

void EsStateStencil::Save() {
  ::glGetIntegerv(GL_STENCIL_CLEAR_VALUE, &clear_);
  ::glGetIntegerv(GL_STENCIL_FUNC, &front_func_);
  ::glGetIntegerv(GL_STENCIL_REF, &front_ref_);
  ::glGetIntegerv(GL_STENCIL_VALUE_MASK, &front_mask_);
  ::glGetIntegerv(GL_STENCIL_BACK_FUNC, &back_func_);
  ::glGetIntegerv(GL_STENCIL_BACK_REF, &back_ref_);
  ::glGetIntegerv(GL_STENCIL_BACK_VALUE_MASK, &back_mask_);
  ::glGetIntegerv(GL_STENCIL_WRITEMASK, &front_write_mask_);
  ::glGetIntegerv(GL_STENCIL_BACK_WRITEMASK, &back_write_mask_);
  ::glGetIntegerv(GL_STENCIL_FAIL, &front_fail_op_);
  ::glGetIntegerv(GL_STENCIL_PASS_DEPTH_FAIL, &front_z_fail_op_);
  ::glGetIntegerv(GL_STENCIL_PASS_DEPTH_PASS, &front_z_pass_op_);
  ::glGetIntegerv(GL_STENCIL_BACK_FAIL, &back_fail_op_);
  ::glGetIntegerv(GL_STENCIL_BACK_PASS_DEPTH_FAIL, &back_z_fail_op_);
  ::glGetIntegerv(GL_STENCIL_BACK_PASS_DEPTH_PASS, &back_z_pass_op_);
  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStateStencil::SetCurrent() {
  ::glClearStencil(clear_);
  ::glStencilFuncSeparate(GL_FRONT, front_func_, front_ref_, front_mask_);
  ::glStencilFuncSeparate(GL_BACK, back_func_, back_ref_, back_mask_);
  ::glStencilMaskSeparate(GL_FRONT, front_write_mask_);
  ::glStencilMaskSeparate(GL_BACK, back_write_mask_);
  ::glStencilOpSeparate(GL_FRONT, front_fail_op_, front_z_fail_op_,
                        front_z_pass_op_);
  ::glStencilOpSeparate(GL_BACK, back_fail_op_, back_z_fail_op_,
                        back_z_pass_op_);
  DCHECK(::glGetError() == GL_NO_ERROR);
}
}  // namespace canvas
}  // namespace lynx
