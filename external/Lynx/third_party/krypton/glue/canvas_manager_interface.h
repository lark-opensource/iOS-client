// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_GLUE_CANVAS_MANAGER_INTERFACE_H_
#define LYNX_KRYPTON_GLUE_CANVAS_MANAGER_INTERFACE_H_
#include "canvas_runtime.h"
#include "canvas_runtime_observer.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {

class ICanvasManager : public runtime::CanvasRuntimeObserver,
                       public std::enable_shared_from_this<ICanvasManager> {
 public:
  virtual void Init(
      std::shared_ptr<shell::LynxActor<CanvasRuntime>> runtime_actor,
      fml::RefPtr<fml::TaskRunner> runtime_task_runner,
      fml::RefPtr<fml::TaskRunner> gpu_task_runner) {}

  virtual int64_t GetCanvasAppHandler() { return 0; }
};

}  // namespace canvas
}  // namespace lynx
#endif  // LYNX_KRYPTON_GLUE_CANVAS_MANAGER_INTERFACE_H_
