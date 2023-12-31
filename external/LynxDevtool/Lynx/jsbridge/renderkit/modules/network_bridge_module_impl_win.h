// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_MODULES_NETWORK_BRIDGE_MODULE_IMPL_WIN_H_
#define LYNX_JSBRIDGE_RENDERKIT_MODULES_NETWORK_BRIDGE_MODULE_IMPL_WIN_H_

#include <memory>
#include <string>
#include <unordered_map>

#include "jsbridge/renderkit/jsi_value_reader.h"
#include "jsbridge/renderkit/modules/bridge_module_impl_win.h"

namespace lynx {
namespace piper {

struct RequestInfo {
  std::string url;
  std::string method;
  std::string body;
  std::string body_type;
  std::unordered_map<std::string, std::string> header;
  RequestInfo(Runtime &rt, const lynx::piper::Object &obj) {
    url = ReadObjectValue<std::string>(rt, obj, "url");
    method = ReadObjectValue<std::string>(rt, obj, "url");
    body = ReadObjectValue<std::string>(rt, obj, "body");
    auto header_value = obj.getProperty(rt, "header");
    if (header_value) {
      header = ReadObject<std::unordered_map<std::string, std::string>>(
          rt, *header_value);
    }
  }
};

class NetworkBridgeModuleImplWin : public BridgeModuleImplWin {
 public:
  explicit NetworkBridgeModuleImplWin(
      const std::shared_ptr<ModuleDelegate> &delegate);
  BridgeMethodsMap Methods() override;
  lynx::piper::Value Request(Runtime *rt, const lynx::piper::Value *args,
                             size_t count);
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_MODULES_NETWORK_BRIDGE_MODULE_IMPL_WIN_H_
