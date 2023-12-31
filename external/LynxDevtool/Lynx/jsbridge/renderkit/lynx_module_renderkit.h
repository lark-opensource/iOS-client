// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RENDERKIT_LYNX_MODULE_RENDERKIT_H_
#define LYNX_JSBRIDGE_RENDERKIT_LYNX_MODULE_RENDERKIT_H_

#include <memory>
#include <optional>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "jsbridge/module/lynx_module.h"
#include "third_party/renderkit/include/rk_modules.h"

namespace lynx {

namespace piper {

class ModuleCallbackRenderkit;

RKLynxModuleArgsRef ConvertJSIObjectToRKArgs(Runtime* rt, const Object& value);

class LynxModuleRenderkit
    : public LynxModule,
      public std::enable_shared_from_this<LynxModuleRenderkit> {
 public:
  using Callbacks =
      std::unordered_set<std::shared_ptr<ModuleCallbackRenderkit>>;

  LynxModuleRenderkit(RKLynxModuleManagerRef manager, RKLynxModuleRef module,
                      const std::string& name,
                      const std::shared_ptr<ModuleDelegate>& delegate);
  ~LynxModuleRenderkit() override;
  void Destroy() override;

  struct MethodDescription {
    bool is_async = false;
    std::string name;
    std::vector<std::string> arg_names;
    std::vector<RKTypeValue::RKValueType> arg_types;
    std::optional<RKTypeValue::RKValueType> return_type;

    explicit MethodDescription(const RKLynxModuleMethod& method);
  };

  void InvokeCallback(const std::shared_ptr<ModuleCallbackRenderkit>& callback);

 protected:
  std::optional<Value> invokeMethod(const MethodMetadata& method, Runtime* rt,
                                    const piper::Value* args,
                                    size_t count) override;

  Value getAttributeValue(Runtime* rt, std::string propName) override {
    return Value();
  }

 private:
  std::optional<Value> InvokeInternal(const MethodDescription& description,
                                      Runtime* rt, const Value* args,
                                      size_t count);

  RKLynxModuleManagerRef rk_manager_;
  RKLynxModuleRef rk_module_;
  std::shared_ptr<ModuleDelegate> delegate_;

  std::unordered_map<std::string, MethodDescription> methods_;
  Callbacks callbacks_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_LYNX_MODULE_RENDERKIT_H_
