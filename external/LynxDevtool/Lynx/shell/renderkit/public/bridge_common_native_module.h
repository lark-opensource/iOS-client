// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_BRIDGE_COMMON_NATIVE_MODULE_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_BRIDGE_COMMON_NATIVE_MODULE_H_

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>

#include "shell/renderkit/public/bridge_native_module.h"
#include "shell/renderkit/public/common_native_module.h"

namespace lynx {

enum class BridgeStatusCode;
struct BridgeMethodArguments;

using BridgeNativeMethod = std::function<void(
    void*, const std::string&, const BridgeMethodArguments&,
    const std::function<void(BridgeStatusCode, const EncodableValue&)>&)>;

class LYNX_EXPORT BridgeCommonNativeModule : public CommonNativeModule {
 public:
  BridgeCommonNativeModule() : CommonNativeModule("bridge") { registerJsb(); }
  virtual ~BridgeCommonNativeModule() = default;

  void registerJsb();

  void RegisterBridgeMethod(const std::string& method_name,
                            const BridgeNativeMethod& bridge_method);
  std::unique_ptr<EncodableValue> call(void* lynx_view, EncodableList params);

 private:
  std::unordered_map<std::string, BridgeNativeMethod> bridge_methods;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_BRIDGE_COMMON_NATIVE_MODULE_H_
