// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_BRIDGE_NATIVE_MODULE_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_BRIDGE_NATIVE_MODULE_H_
#include <functional>
#include <memory>
#include <string>

#include "lynx_export.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {

enum class BridgeStatusCode {
  BridgeCodeUnknownError = -1000,   // 未知错误
  BridgeCodeManualCallback = -999,  // 业务方回调
  BridgeCodeUndefined = -998,       // 前端方法未定义
  BridgeCode404 = -997,             // 前端返回 404
  BridgeCodeParameterError = -3,    // 参数错误
  BridgeCodeNoHandler = -2,         // 未注册方法
  BridgeCodeNotAuthroized = -1,     // 未授权
  BridgeCodeFail = 0,               // 失败
  BridgeCodeSucceed = 1             // 成功
};

struct BridgeMethodArguments {
  BridgeMethodArguments();
  BridgeMethodArguments(const std::string& methodName,
                        const std::string& protocolVersion,
                        const std::string& containerId,
                        const std::string& namespaceName,
                        const EncodableMap& data);

  ~BridgeMethodArguments();
  std::string method_name;
  std::string protocol_version;
  std::string container_id;
  std::string namespace_name;
  EncodableMap data;
};

class BridgeNativeModuleImpl;

class LYNX_EXPORT BridgeNativeModule {
 public:
  explicit BridgeNativeModule(const std::string& name);
  ~BridgeNativeModule();
  bool RegisterMethod(
      const std::string& name,
      const std::function<void(
          void* lynx_view, const std::string& method_name,
          const BridgeMethodArguments& args,
          const std::function<void(BridgeStatusCode code,
                                   const EncodableValue& data)>& callback)>&
          method);

  friend class BridgeNativeModuleAdapter;

 private:
  std::unique_ptr<BridgeNativeModuleImpl> impl_;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_BRIDGE_NATIVE_MODULE_H_
