// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RENDERKIT_MODULE_CALLBACK_RENDERKIT_H_
#define LYNX_JSBRIDGE_RENDERKIT_MODULE_CALLBACK_RENDERKIT_H_

#include <functional>
#include <memory>
#include <utility>

#include "jsbridge/module/lynx_module_callback.h"
#include "third_party/renderkit/include/rk_modules.h"

namespace lynx {
namespace piper {

using RKLynxModuleArgsPtr = std::shared_ptr<RKLynxModuleArgs>;

class LynxModuleRenderkit;

Value CastRKValueToJSValue(Runtime* rt, const RKTypeValue& value);

class ModuleCallbackRenderkit
    : public ModuleCallback,
      public std::enable_shared_from_this<ModuleCallbackRenderkit> {
 public:
  ModuleCallbackRenderkit(int64_t callback_id,
                          std::shared_ptr<LynxModuleRenderkit> module);
  ~ModuleCallbackRenderkit() override;

  // Resource is managed by `ModuleCallbackRenderkit` itself.
  RKLynxModuleCallback* GetRKCallback();

  void Invoke(Runtime* runtime, ModuleCallbackFunctionHolder* holder) override;

  void TryInvoke(RKLynxModuleArgsPtr args);

 private:
  std::weak_ptr<LynxModuleRenderkit> module_;
  RKLynxModuleCallback* rk_callback_ = nullptr;
  RKLynxModuleArgsPtr args_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_MODULE_CALLBACK_RENDERKIT_H_
