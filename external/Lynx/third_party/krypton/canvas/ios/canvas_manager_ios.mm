// Copyright 2023 The Lynx Authors. All rights reserved.

#include "canvas/ios/canvas_manager_ios.h"
#import "LynxKryptonLoader.h"
#include "canvas/base/log.h"
#include "jsbridge/napi/napi_environment.h"

namespace lynx {
namespace canvas {

CanvasManagerIOS::CanvasManagerIOS(LynxKryptonApp* app) : app_(app) {
  KRYPTON_CONSTRUCTOR_LOG(CanvasManagerIOS);
}

CanvasManagerIOS::~CanvasManagerIOS() { KRYPTON_DESTRUCTOR_LOG(CanvasManagerIOS); }

void CanvasManagerIOS::Init(std::shared_ptr<shell::LynxActor<CanvasRuntime>> runtime_actor,
                            fml::RefPtr<fml::TaskRunner> runtime_task_runner,
                            fml::RefPtr<fml::TaskRunner> gpu_task_runner) {
  [app_ setRuntimeActor:&runtime_actor];
  [app_ setRuntimeTaskRunner:&runtime_task_runner];
  [app_ setGPUTaskRunner:&gpu_task_runner];
}

int64_t CanvasManagerIOS::GetCanvasAppHandler() { return [app_ getNativeHandler]; }

void CanvasManagerIOS::RuntimeInit(int64_t runtime_id) {
  id service = [app_ getService:@protocol(KryptonLoaderService)];
  if ([service isKindOfClass:[LynxKryptonLoader class]]) {
    LynxKryptonLoader* loader = service;
    [loader setRuntimeId:runtime_id];
  }
}

void CanvasManagerIOS::RuntimeAttach(piper::NapiEnvironment* env) {
  DCHECK(env);
  [app_ bootstrap:env->proxy()->Env()];
}

void CanvasManagerIOS::RuntimeDetach() { [app_ destroy]; }

void CanvasManagerIOS::OnAppEnterForeground() {
  // lynx app enter forground, not application
  [app_ onShow];
}

void CanvasManagerIOS::OnAppEnterBackground() {
  // lynx app enter forground, not application
  [app_ onHide];
}

void CanvasManagerIOS::RuntimeDestroy() {}

}  // namespace canvas
}  // namespace lynx
