// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_COMMON_NATIVE_MODULE_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_COMMON_NATIVE_MODULE_H_

#include <functional>
#include <memory>
#include <string>

#include "lynx_export.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {

class CommonNativeModuleImpl;

class LYNX_EXPORT CommonNativeModule {
 public:
  explicit CommonNativeModule(const std::string& name);
  virtual ~CommonNativeModule();
  bool RegisterMethod(const std::string& name,
                      const std::function<std::unique_ptr<EncodableValue>(
                          void* lynx_view, const EncodableList&)>& method);
  std::string module_name() { return module_name_; }

  friend class CommonNativeModuleAdapter;

 private:
  std::unique_ptr<CommonNativeModuleImpl> impl_;
  std::string module_name_;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_COMMON_NATIVE_MODULE_H_
