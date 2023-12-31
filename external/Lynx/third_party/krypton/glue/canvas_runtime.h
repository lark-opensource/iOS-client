// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_GLUE_CANVAS_RUNTIME_H_
#define LYNX_KRYPTON_GLUE_CANVAS_RUNTIME_H_

#include <functional>

namespace lynx {
namespace canvas {

// linxs tobe moved to krypton_glue
class CanvasRuntime {
 public:
  CanvasRuntime() = default;
  virtual ~CanvasRuntime() = default;

  virtual void AsyncRequestVSync(
      uintptr_t id,
      std::function<void(int64_t frame_start, int64_t frame_end)> callback,
      bool for_flush = false) = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_GLUE_CANVAS_RUNTIME_H_
