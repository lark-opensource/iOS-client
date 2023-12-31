// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_LYNX_MODULE_DESKTOP_H_
#define LYNX_JSBRIDGE_RENDERKIT_LYNX_MODULE_DESKTOP_H_

#include <memory>
#include <string>
#include <unordered_map>

#include "jsbridge/module/lynx_module.h"

namespace lynx {
namespace piper {

#define REGISTER_METHOD(method_name, args_count)                  \
  AddMethod(#method_name, args_count);                            \
  name_methods_.emplace(                                          \
      #method_name,                                               \
      [this](Runtime *rt, const lynx::piper::Value *args,         \
             size_t count) -> std::optional<lynx::piper::Value> { \
        return method_name(rt, args, count);                      \
      });

class LynxModuleDesktop : public LynxModule {
 public:
  LynxModuleDesktop(const std::string &name,
                    const std::shared_ptr<ModuleDelegate> &delegate);
  LynxModuleDesktop(void *lynx_view, const std::string &name,
                    const std::shared_ptr<ModuleDelegate> &delegate);
  void AddMethod(const std::string &name, size_t args_count);
  void Destroy() override;

 protected:
  std::optional<Value> invokeMethod(const MethodMetadata &method, Runtime *rt,
                                    const piper::Value *args,
                                    size_t count) override;
  Value getAttributeValue(Runtime *rt, std::string prop_name) override;

  using CxxModuleMethod = std::function<std::optional<Value>(
      Runtime *rt, const lynx::piper::Value *args, size_t count)>;
  std::unordered_map<std::string, CxxModuleMethod> name_methods_;
  void *lynx_view_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_LYNX_MODULE_DESKTOP_H_
