// Copyright 2021 The Lynx Authors. All rights reserved.

#include "inspector/observer/inspector_lepus_context_observer.h"

#include <unordered_map>

#include "base/no_destructor.h"
#include "inspector/inspector_manager.h"
#include "jsbridge/lynx_console_helper.h"

namespace lynx {
namespace devtool {

static int32_t GetLevelNumByStr(const std::string &level) {
  static base::NoDestructor<std::unordered_map<std::string, int>> level_map(
      {{piper::LepusConsoleAlog, piper::CONSOLE_LOG_ALOG},
       {piper::LepusConsoleDebug, piper::CONSOLE_LOG_INFO},
       {piper::LepusConsoleError, piper::CONSOLE_LOG_ERROR},
       {piper::LepusConsoleInfo, piper::CONSOLE_LOG_INFO},
       {piper::LepusConsoleLog, piper::CONSOLE_LOG_LOG},
       {piper::LepusConsoleReport, piper::CONSOLE_LOG_REPORT},
       {piper::LepusConsoleWarn, piper::CONSOLE_LOG_WARNING}});
  return (*level_map)[level];
}

InspectorLepusContextObserver::InspectorLepusContextObserver(
    const std::shared_ptr<InspectorManager> &manager)
    : manager_(manager) {}

intptr_t InspectorLepusContextObserver::CreateJavascriptDebugger(
    const std::string &url) {
  auto manager = manager_.lock();
  auto ptr = manager != nullptr ? manager->getLepusDebugger(url) : 0;
  if (ptr) {
    debugger_ =
        reinterpret_cast<piper::JavaScriptDebuggerWrapper *>(ptr)->debugger_;
  }
  if (manager != nullptr) {
    need_post_console_ = !manager->IsJsRunnerReady();
  }
  return ptr;
}

void InspectorLepusContextObserver::OnConsoleMessage(const std::string &level,
                                                     const std::string &msg) {
  if (need_post_console_) {
    auto manager = manager_.lock();
    if (manager != nullptr) {
      LOGI("devtool post lepus console: " << msg);
      int32_t level_num = GetLevelNumByStr(level);
      auto ts = std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::system_clock::now().time_since_epoch())
                    .count();
      manager->SendConsoleMessage({msg, level_num, static_cast<int64_t>(ts)});
    }
  }
}

}  // namespace devtool
}  // namespace lynx
