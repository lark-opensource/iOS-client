// Copyright 2021 The Lynx Authors. All rights reserved.

#include "jsbridge/js_debug/inspector_lepus_debugger.h"

#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "config/devtool_config.h"
#include "inspector/inspector_manager.h"
#include "inspector_client.h"
#include "lepus/context.h"

namespace lynx {
namespace devtool {

constexpr int kDefaultViewId = -1;

InspectorLepusDebugger::InspectorLepusDebugger() {
  InspectorClient::CreateLepusEnvProvider();
  inspector_client_sp_ =
      InspectorClient::CreateInspectorClient(lepus_debug, LepusClient);
  LOGI("lepus debug: create inspectorLepusDebugger");
}

void InspectorLepusDebugger::SetEnableNeeded(bool enable) {
  LOGI("lepus debug: setEnableNeeded: " << enable);
  enable_needed_ = enable;
}

void InspectorLepusDebugger::InitWithContext(
    const std::shared_ptr<lepus::Context>& context) {
  LOGI("lepus debug: InspectorLepusDebugger::InitWithContext");
  if (inspector_client_sp_ != nullptr && enable_needed_) {
    inspector_client_sp_->SetLepusDebugger(
        std::static_pointer_cast<InspectorLepusDebugger>(shared_from_this()));
    inspector_client_sp_->SetLepusContext(context);
    LOGI("lepus debug: DispatchMessageEnable");
    inspector_client_sp_->DispatchMessageEnable(kDefaultViewId, false);
    inspector_client_sp_->SetStopAtEntry(enable_needed_, kDefaultViewId);
  }
}

void InspectorLepusDebugger::OnDestroy(bool is_worker) {
  if (inspector_client_sp_ != nullptr) {
    inspector_client_sp_->DisconnectFrontend(kDefaultViewId);
  }
}

void InspectorLepusDebugger::StopDebug() {
  if (inspector_client_sp_ != nullptr) {
    inspector_client_sp_->DispatchMessageStop(kDefaultViewId);
  }
}

void InspectorLepusDebugger::SetTargetNum(int num) { target_num_ = num; }

void InspectorLepusDebugger::SetDebugInfo(const std::string& info) {
  debug_info_ = info;
  LOGI("lepus debug: SetDebugInfo: info isEmpty: " << debug_info_.empty());
}

void InspectorLepusDebugger::DispatchMessageToJSEngine(
    const std::string& message) {
  if (inspector_client_sp_ != nullptr) {
    inspector_client_sp_->DispatchMessageFromFrontend(message, kDefaultViewId);
  }
}

void InspectorLepusDebugger::DispatchDebuggerDisableMessage() {
  if (inspector_client_sp_ != nullptr) {
    inspector_client_sp_->DispatchDebuggerDisable(kDefaultViewId);
  }
}

void InspectorLepusDebugger::RunOnMainThread(lynx::base::closure closure) {
  InspectorManager::RunOnMainThread(std::move(closure));
}

}  // namespace devtool
}  // namespace lynx
