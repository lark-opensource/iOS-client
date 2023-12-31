// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_BINDINGS_LYNX_ERROR_H_
#define LYNX_JSBRIDGE_BINDINGS_LYNX_ERROR_H_

#include <string>
#include <utility>
#include <vector>

#include "jsbridge/jsi/jsi.h"

namespace lynx::piper {

class LynxError : public HostObject {
 public:
  explicit LynxError(const JSIException& exception)
      : name_(exception.name()),
        message_(exception.message()),
        stack_(exception.stack()) {}

  LynxError(std::string name, std::string message, std::string stack)
      : name_(std::move(name)),
        message_(std::move(message)),
        stack_(std::move(stack)) {}

  LynxError(const LynxError&) = delete;
  LynxError& operator=(const LynxError&) = delete;

  Value get(Runtime* rt, const PropNameID& name) override;

  void set(Runtime* rt, const PropNameID& name, const Value& value) override;

  std::vector<PropNameID> getPropertyNames(Runtime& rt) override;

 private:
  // Non-enumerable, writable, configuable
  // see: https://tc39.es/ecma262/#sec-error.prototype.name
  // also see:
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/name
  std::string name_;
  // Non-enumerable, writable, configuable
  // see: https://tc39.es/ecma262/#sec-error.prototype.message
  // also see:
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/message
  std::string message_;
  // Non-enumerable, writable, configuable
  // see:
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/stack
  std::string stack_;
};

}  // namespace lynx::piper

#endif  // LYNX_JSBRIDGE_BINDINGS_LYNX_ERROR_H_
