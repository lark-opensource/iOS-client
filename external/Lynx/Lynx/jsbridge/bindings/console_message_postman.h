// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_BINDINGS_CONSOLE_MESSAGE_POSTMAN_H_
#define LYNX_JSBRIDGE_BINDINGS_CONSOLE_MESSAGE_POSTMAN_H_

#include <memory>
#include <string>

namespace lynx {

namespace runtime {
class LynxRuntimeObserver;
}

namespace piper {

class JavaScriptDebugger;

struct ConsoleMessage {
  ConsoleMessage(const std::string& text, int32_t level, int64_t timestamp)
      : text_(text), level_(level), timestamp_(timestamp){};
  std::string text_;
  int32_t level_;
  int64_t timestamp_;
};

class ConsoleMessagePostMan {
 public:
  ConsoleMessagePostMan(){};
  virtual ~ConsoleMessagePostMan(){};
  virtual void OnMessagePosted(const ConsoleMessage& message) = 0;
  virtual void InsertRuntimeObserver(
      const std::shared_ptr<runtime::LynxRuntimeObserver>& observer) = 0;
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_BINDINGS_CONSOLE_MESSAGE_POSTMAN_H_
