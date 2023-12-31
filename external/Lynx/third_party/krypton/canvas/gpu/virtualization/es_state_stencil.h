#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_STENCIL_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_STENCIL_H_

#include "es_state_tracer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStateStencil : public ESStateTracer {
 public:
  void Save() override;
  void SetCurrent() override;

 private:
  GLint clear_ = 0;
  GLint front_fail_op_ = GL_KEEP;
  GLint front_z_fail_op_ = GL_KEEP;
  GLint front_z_pass_op_ = GL_KEEP;
  GLint front_write_mask_ = 0xFFFFFFFFU;
  GLint front_ref_ = 0;
  GLint front_func_ = GL_ALWAYS;
  GLint front_mask_ = 0xFFFFFFFFU;

  GLint back_fail_op_ = GL_KEEP;
  GLint back_z_fail_op_ = GL_KEEP;
  GLint back_z_pass_op_ = GL_KEEP;
  GLint back_write_mask_ = 0xFFFFFFFFU;
  GLint back_ref_ = 0;
  GLint back_func_ = GL_ALWAYS;
  GLint back_mask_ = 0xFFFFFFFFU;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_STENCIL_H_
