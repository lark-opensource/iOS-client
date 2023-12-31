#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_TRACER_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_TRACER_H_

#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class ESStateTracer {
 public:
  virtual ~ESStateTracer() = default;
  virtual void Save() = 0;
  virtual void SetCurrent() = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_TRACER_H_
