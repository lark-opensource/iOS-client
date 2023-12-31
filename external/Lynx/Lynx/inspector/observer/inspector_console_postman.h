// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_OBSERVER_INSPECTOR_CONSOLE_POSTMAN_H_
#define LYNX_INSPECTOR_OBSERVER_INSPECTOR_CONSOLE_POSTMAN_H_

#include <memory>
#include <vector>

#include "jsbridge/bindings/console_message_postman.h"

namespace lynx {

namespace runtime {
class LynxRuntimeObserver;
}

namespace devtool {

class InspectorManager;

class InspectorConsolePostMan : public piper::ConsoleMessagePostMan {
 public:
  InspectorConsolePostMan() = default;
  ~InspectorConsolePostMan() override = default;
  virtual void OnMessagePosted(const piper::ConsoleMessage& message) override;
  virtual void InsertRuntimeObserver(
      const std::shared_ptr<runtime::LynxRuntimeObserver>& observer) override;

 private:
  std::vector<std::weak_ptr<runtime::LynxRuntimeObserver>> observer_vec_;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_OBSERVER_INSPECTOR_CONSOLE_POSTMAN_H_
