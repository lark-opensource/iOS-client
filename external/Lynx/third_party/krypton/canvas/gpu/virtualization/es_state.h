#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_H_

#include "es_state_buffer.h"
#include "es_state_enabled.h"
#include "es_state_misc.h"
#include "es_state_pixel_store.h"
#include "es_state_query_manage.h"
#include "es_state_stencil.h"
#include "es_state_texture.h"
#include "es_state_tfo.h"
#include "es_state_tracer.h"
#include "es_state_uniform_binding_point.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {

class Estate : public ESStateTracer {
 public:
  void Save() override;
  void SetCurrent() override;

  std::unique_ptr<Estate> Clone() const;

 public:
  EsStateBuffer buffer_;
  EsStateEnabled enabled_;
  EsStateMisc misc_;
  EsStatePixelStore pixel_store_;
  EsStateStencil stencil_;
  EsStateTexture texture_;
  EsStateTfo tfo_;
  EsStateUniformBindingPoint uniform_binding_point_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_H_
