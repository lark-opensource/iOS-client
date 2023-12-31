// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_HEADLESS_MODULE_MANAGER_HEADLESS_H_
#define LYNX_JSBRIDGE_HEADLESS_MODULE_MANAGER_HEADLESS_H_

#include <iostream>
#include <memory>
#include <string>
#include <unordered_map>

#include "jsbridge/headless/module_callback_headless.h"
#include "jsbridge/module/lynx_module_callback.h"
#include "jsbridge/module/lynx_module_manager.h"
#include "third_party/fml/synchronization/waitable_event.h"

#define Napi NodejsNapi
#include "napi.h"

namespace lynx {
namespace headless {

class AnyModule : public lynx::piper::LynxModule {
 public:
  AnyModule(const std::string& name,
            const std::shared_ptr<piper::ModuleDelegate>& delegate)
      : lynx::piper::LynxModule(name, delegate) {}
  void Destroy() override;

  void RegisterNativeMethod(std::string method, Napi::ThreadSafeFunction tsfn);

 protected:
  std::optional<piper::Value> invokeMethod(const MethodMetadata& method,
                                           piper::Runtime* rt,
                                           const piper::Value* args,
                                           size_t count) override;

  piper::Value get(piper::Runtime* runtime,
                   const piper::PropNameID& prop) override;

  piper::Value getAttributeValue(piper::Runtime* rt,
                                 std::string propName) override;

 private:
  std::unordered_map<std::string, Napi::ThreadSafeFunction> impls_map_;
};

class ModuleManagerHeadless : public lynx::piper::LynxModuleManager {
 public:
  ModuleManagerHeadless() = default;

  void initBindingPtr(std::weak_ptr<ModuleManagerHeadless> weak_manager,
                      const std::shared_ptr<piper::ModuleDelegate>& delegate);

  ~ModuleManagerHeadless() override = default;

  void Destroy() override;

  void RegisterNativeModule(std::string module, std::string method,
                            Napi::ThreadSafeFunction tsfn);

 private:
  std::shared_ptr<piper::ModuleDelegate> delegate_;
  std::unordered_map<std::string, std::shared_ptr<AnyModule>> map_{};
};

}  // namespace headless
}  // namespace lynx

#undef Napi

#endif  // LYNX_JSBRIDGE_HEADLESS_MODULE_MANAGER_HEADLESS_H_
