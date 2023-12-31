#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_ENABLED_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_ENABLED_H_

#include "es_state_tracer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStateEnabled : public ESStateTracer {
 public:
  void Save() override;
  void SetCurrent() override;

 private:
  GLboolean blend_ = false;
  GLboolean cull_face_ = false;
  GLboolean depth_test_ = false;
  GLboolean dither_ = true;
  GLboolean polygon_offset_fill_ = false;
  GLboolean sample_alpha_to_coverage_ = false;
  GLboolean sample_coverage_ = false;
  GLboolean scissor_test_ = false;
  GLboolean stencil_test_ = false;
  GLboolean rasterizer_discard_ = false;
  GLboolean primitive_restart_fixed_index_ = false;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_ENABLED_H_
