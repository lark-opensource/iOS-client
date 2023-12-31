// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/module/lynx_module_binding.h"

#include <utility>

namespace lynx {
namespace piper {

/**
 * Public API to install the LynxModule system.
 */
LynxModuleBinding::LynxModuleBinding(
    const LynxModuleProviderFunction& moduleProvider)
    : moduleProvider_(moduleProvider) {}

piper::Value LynxModuleBinding::get(Runtime* rt, const PropNameID& prop) {
  piper::Scope scope(*rt);
  std::string moduleName = prop.utf8(*rt);
  std::shared_ptr<LynxModule> module = moduleProvider_(moduleName);
  if (module == nullptr) {
    return piper::Value::null();
  }
  module->interceptor_ = interceptor_;
  return piper::Object::createFromHostObject(*rt, std::move(module));
}

std::shared_ptr<LynxModule> LynxModuleBinding::GetModule(
    const std::string& name) {
  return moduleProvider_(name);
}

ModuleInterceptorResult GroupInterceptor::InterceptModuleMethod(
    LynxModule* module, LynxModule::MethodMetadata* method, Runtime* rt,
    const std::shared_ptr<piper::ModuleDelegate>& delegate,
    const piper::Value* args, size_t count) const {
  for (auto& i : interceptors_) {
    auto pair =
        i->InterceptModuleMethod(module, method, rt, delegate, args, count);
    if (pair.handled) {
      return pair;
    }
  }
  return {false, Value::null()};
}

void GroupInterceptor::AddInterceptor(
    std::shared_ptr<ModuleMethodInterceptor>&& interceptor) {
  interceptors_.push_back(std::move(interceptor));
}

void GroupInterceptor::SetTemplateUrl(const std::string& url) {
  for (const auto& interceptor : interceptors_) {
    interceptor->SetTemplateUrl(url);
  }
}

}  // namespace piper
}  // namespace lynx
