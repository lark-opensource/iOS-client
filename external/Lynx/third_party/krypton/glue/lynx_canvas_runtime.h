// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_GLUE_LYNX_CANVAS_RUNTIME_H_
#define LYNX_KRYPTON_GLUE_LYNX_CANVAS_RUNTIME_H_

#include "canvas_runtime.h"
#include "jsbridge/runtime/lynx_runtime.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {

class LynxCanvasRuntime : public CanvasRuntime {
 public:
  LynxCanvasRuntime(
      std::shared_ptr<shell::LynxActor<runtime::LynxRuntime>> runtime_actor)
      : runtime_actor_(std::move(runtime_actor)) {}

  ~LynxCanvasRuntime() override = default;

  void AsyncRequestVSync(
      uintptr_t id,
      std::function<void(int64_t frame_start, int64_t frame_end)> callback,
      bool for_flush) override {
    runtime_actor_->Impl()->AsyncRequestVSync(id, std::move(callback),
                                              for_flush);
  }

 private:
  std::shared_ptr<shell::LynxActor<runtime::LynxRuntime>> runtime_actor_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_GLUE_LYNX_CANVAS_RUNTIME_H_
