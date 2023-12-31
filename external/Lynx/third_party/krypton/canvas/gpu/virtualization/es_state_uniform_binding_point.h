#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_UNIFORM_BINDING_POINT_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_UNIFORM_BINDING_POINT_H_

#include <vector>

#include "es_state_tracer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStateUniformBindingPoint : public ESStateTracer {
 public:
  void Save() override;
  void SetCurrent() override;

 public:
  struct BindingPoint {
    GLint64 buffer_, offset_, size_;
  };
  std::vector<BindingPoint> binding_points_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_UNIFORM_BINDING_POINT_H_
