// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_MODULE_LYNX_MODULE_BINDING_H_
#define LYNX_JSBRIDGE_MODULE_LYNX_MODULE_BINDING_H_

#include <memory>
#include <string>
#include <vector>

#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/lynx_module.h"

namespace lynx {
namespace piper {

class GroupInterceptor : public ModuleMethodInterceptor {
 public:
  virtual ModuleInterceptorResult InterceptModuleMethod(
      LynxModule* module, LynxModule::MethodMetadata* method, Runtime* rt,
      const std::shared_ptr<piper::ModuleDelegate>& delegate,
      const piper::Value* args, size_t count) const override;
  void AddInterceptor(std::shared_ptr<ModuleMethodInterceptor>&& interceptor);
  void SetTemplateUrl(const std::string& url) override;

 private:
  std::vector<std::shared_ptr<ModuleMethodInterceptor>> interceptors_;
};

/**
 * Represents the JavaScript binding for the LynxModule system.
 */
class LynxModuleBinding : public piper::HostObject {
 public:
  explicit LynxModuleBinding(const LynxModuleProviderFunction& moduleProvider);
  ~LynxModuleBinding() override = default;

  piper::Value get(Runtime* rt, const PropNameID& name) override;
  std::shared_ptr<LynxModule> GetModule(const std::string& name);
  // FIXME: use unique_ptr if we solve the `shared_ptr<LynxModule>` issue.
  std::shared_ptr<ModuleMethodInterceptor> interceptor_;

 private:
  LynxModuleProviderFunction moduleProvider_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_MODULE_LYNX_MODULE_BINDING_H_
