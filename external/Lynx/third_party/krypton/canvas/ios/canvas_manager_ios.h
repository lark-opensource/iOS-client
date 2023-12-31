// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IOS_CANVAS_MANAGER_IOS_H_
#define CANVAS_IOS_CANVAS_MANAGER_IOS_H_

#import "LynxKryptonApp.h"
#include "glue/canvas_manager_interface.h"
#include "glue/canvas_runtime_observer.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {

class CanvasManagerIOS : public ICanvasManager {
 public:
  CanvasManagerIOS(LynxKryptonApp* app);
  ~CanvasManagerIOS();

  void Init(std::shared_ptr<shell::LynxActor<CanvasRuntime>> runtime_actor,
            fml::RefPtr<fml::TaskRunner> runtime_task_runner,
            fml::RefPtr<fml::TaskRunner> gpu_task_runner) override;

  int64_t GetCanvasAppHandler() override;
  void RuntimeInit(int64_t runtime_id) override;
  void RuntimeAttach(piper::NapiEnvironment* env) override;
  void RuntimeDetach() override;
  void RuntimeDestroy() override;
  void OnAppEnterForeground() override;
  void OnAppEnterBackground() override;

 private:
  LynxKryptonApp* app_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IOS_CANVAS_MANAGER_IOS_H_
