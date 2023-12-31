// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/ios/canvas_app_ios.h"
#import "LynxKryptonApp.h"
#include "canvas/base/log.h"
#include "config/config.h"
#if ENABLE_KRYPTON_RECORDER
#import "KryptonDefaultMediaRecorder.h"
#endif

namespace lynx {
namespace canvas {

CanvasAppIOS::CanvasAppIOS(KryptonApp* app) : app_(app) {}

std::shared_ptr<CanvasApp> CanvasAppIOS::CanvasAppFromHandler(int64_t handler) {
  if (!handler) {
    return nullptr;
  }

  // see CanvasApp::GetNativeHandler for real type of handler
  auto shared_canvas_app = reinterpret_cast<CanvasApp*>(handler)->shared_from_this();
  return std::static_pointer_cast<CanvasApp>(shared_canvas_app);
}

id CanvasAppIOS::GetService(Protocol* protocol) { return [app_ getService:protocol]; }

id<LynxKryptonEffectHandlerProtocol> CanvasAppIOS::GetEffectHandler() {
#if ENABLE_KRYPTON_EFFECT
  if (![(LynxKryptonApp*)app_ effectHandler]) {
    static id<LynxKryptonEffectHandlerProtocol> defaultImp;
    if (!defaultImp) {
      KRYPTON_LOGI("try to use default impl from HybridKit LynxCanvasEffectHandler");
      Class clazz = NSClassFromString(@"LynxCanvasEffectHandler");
      if (!clazz) {
        KRYPTON_LOGE("LynxCanvasEffectHandler class not found");
        return nil;
      }
      defaultImp = [[clazz alloc] init];
    }
    return defaultImp;
  }
  return [(LynxKryptonApp*)app_ effectHandler];
#else
  return nil;
#endif
}

}  // namespace canvas
}  // namespace lynx
