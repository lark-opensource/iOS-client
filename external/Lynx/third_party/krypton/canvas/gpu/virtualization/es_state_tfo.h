#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_TFO_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_TFO_H_

#include <vector>

#include "es_state_tracer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStateTfo : public ESStateTracer {
 public:
  void Save() override;
  void SetCurrent() override;

 private:
  GLint tfo_;
  GLboolean tfo_paused_, tfo_active_;

  struct TfoBuffer {
    GLint64 buffer_, offset_, size_;
  };
  std::vector<TfoBuffer> tfo_0_buffers_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_TFO_H_
