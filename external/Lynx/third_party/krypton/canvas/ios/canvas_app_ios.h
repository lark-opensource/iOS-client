// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IOS_CANVAS_APP_IOS_H_
#define CANVAS_IOS_CANVAS_APP_IOS_H_

#import "KryptonApp.h"
#import "KryptonService.h"
#import "LynxKryptonHelper.h"  // to be removed after all LynxXXXProtocol removed
#include "canvas/canvas_app.h"

namespace lynx {
namespace canvas {

class CanvasAppIOS : public CanvasApp {
 public:
  CanvasAppIOS(KryptonApp* app);
  ~CanvasAppIOS() override = default;

  id GetService(Protocol* protocol);

  static std::shared_ptr<CanvasApp> CanvasAppFromHandler(int64_t handler);

  // todo: remove these interface from KryptonApp services
  // inner module must call from KryptonApp
  id<LynxKryptonEffectHandlerProtocol> GetEffectHandler();

 private:
  __weak KryptonApp* app_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IOS_CANVAS_APP_IOS_H_
