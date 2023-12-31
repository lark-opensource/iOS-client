// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef JSBRIDGE_BINDINGS_CANVAS_CANVAS_MODULE_H_
#define JSBRIDGE_BINDINGS_CANVAS_CANVAS_MODULE_H_

#include "base/base_export.h"
#include "jsbridge/napi/napi_environment.h"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace canvas {

class CanvasApp;

class CanvasModule : public piper::NapiEnvironment::Module {
 public:
  BASE_EXPORT static CanvasModule* From(Napi::Env env);
  void Install(Napi::Env env);

  CanvasModule(std::shared_ptr<CanvasApp> app);

  std::shared_ptr<CanvasApp> GetCanvasApp() { return app_; }
  bool IsLazy() override { return true; }
  static void RegisterClasses(Napi::Env env, Napi::Object& object);

 private:
  void OnLoad(Napi::Object& lynx) override{};

  std::shared_ptr<CanvasApp> app_ = nullptr;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_CANVAS_MODULE_H_
