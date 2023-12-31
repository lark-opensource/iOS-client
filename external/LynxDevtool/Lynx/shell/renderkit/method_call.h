// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_METHOD_CALL_H_
#define LYNX_SHELL_RENDERKIT_METHOD_CALL_H_

#include <memory>
#include <string>
#include <utility>

#include "shell/renderkit/public/encodable_value.h"

namespace lynx {
class MethodCall {
 public:
  // Creates a MethodCall with the given name and arguments.
  MethodCall(std::string method_name, std::unique_ptr<EncodableValue> arguments)
      : method_name_(std::move(method_name)),
        arguments_(std::move(arguments)) {}

  ~MethodCall() = default;
  // Prevent copying.
  MethodCall(MethodCall const&) = delete;
  MethodCall& operator=(MethodCall const&) = delete;

  // The name of the method being called.
  std::string method_name() const { return method_name_; }

  // The arguments to the method call, or NULL if there are none.
  const EncodableValue* arguments() const { return arguments_.get(); }

 private:
  std::string method_name_;
  std::unique_ptr<EncodableValue> arguments_;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_METHOD_CALL_H_
