// Copyright 2019 The Lynx Authors. All rights reserved.

#include "inspector/observer/inspector_console_postman.h"

#include "base/log/logging.h"
#include "inspector/inspector_manager.h"
#include "inspector/observer/inspector_runtime_observer.h"

namespace lynx {
namespace devtool {

void InspectorConsolePostMan::OnMessagePosted(
    const piper::ConsoleMessage& message) {
  auto iter = observer_vec_.begin();
  while (iter != observer_vec_.end()) {
    auto sp = (*iter).lock();
    if (sp) {
      sp->OnMessagePosted(reinterpret_cast<intptr_t>(&message));
      ++iter;
    } else {
      iter = observer_vec_.erase(iter);
    }
  }
}

void InspectorConsolePostMan::InsertRuntimeObserver(
    const std::shared_ptr<runtime::LynxRuntimeObserver>& observer) {
  if (observer) {
    observer_vec_.push_back(observer);
  }
}

}  // namespace devtool
}  // namespace lynx
