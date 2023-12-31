// Copyright 2019 The Lynx Authors. All rights reserved.

#include "inspector_java_script_debugger.h"

#include "config/devtool_config.h"
#include "inspector/inspector_manager.h"
#include "jsbridge/js_debug/debug_helper.h"
#include "jsbridge/js_debug/inspector_client.h"

namespace lynx {
namespace devtool {
static int cur_view_id = 0;

InspectorJavaScriptDebugger::InspectorJavaScriptDebugger(DebugType debug_type)
    : view_id_(kDefaultViewID), debug_type_(debug_type) {
  LOGI("js debug: create InspectorJavaScriptDebugger, this: "
       << this << ", debug type: " << debug_type_);
  InspectorClient::CreateJsEnvProvider(debug_type_);
  worker_client_sp_ = InspectorClientProvider::CreateInspectorClient(
      debug_type_, JsWorkerClient, false);
}

InspectorJavaScriptDebugger::~InspectorJavaScriptDebugger() {
  LOGI("js debug: ~InspectorJavaScriptDebugger, this: " << this);
  if (inspector_client_sp_ != nullptr) {
    inspector_client_sp_->RemoveJSDebugger(view_id_);
  }
}

void InspectorJavaScriptDebugger::SetSharedVM(const std::string& group_name) {
  shared_vm_ = group_name != kSingleGroupID || debug_type_ == quickjs_debug;
  if (shared_vm_) {
    view_id_ = ++cur_view_id;
  }
  inspector_client_sp_ = InspectorClientProvider::CreateInspectorClient(
      debug_type_, JsClient, shared_vm_);
  LOGI("js debug: InspectorJavaScriptDebugger::SetSharedVM, this: "
       << this << ", client: " << inspector_client_sp_
       << ", shared_vm: " << shared_vm_ << ", group_name: " << group_name
       << ", view_id: " << view_id_);
}

void InspectorJavaScriptDebugger::SetEnableNeeded(bool enable) {
  LOGI("js debug: setEnableNeeded: " << enable);
  enable_needed_ = enable;
}

void InspectorJavaScriptDebugger::SetRuntimeEnableNeeded(bool enable) {
  runtime_enable_needed_ = enable;
}

void InspectorJavaScriptDebugger::InitWithRuntime(
    const std::shared_ptr<piper::Runtime>& runtime, const std::string& group_id,
    bool is_worker) {
  LOGI("js debug: InspectorJavaScriptDebugger::InitWithRuntime, this: "
       << this << ", is worker: " << is_worker);
  auto& client = is_worker ? worker_client_sp_ : inspector_client_sp_;
  if (client != nullptr) {
    client->InsertJSDebugger(
        std::static_pointer_cast<InspectorJavaScriptDebugger>(
            shared_from_this()),
        view_id_, group_id);
    client->SetJSRuntime(runtime, view_id_);
    if (enable_needed_) {
      LOGI("js debug: DispatchMessageEnable");
      client->DispatchMessageEnable(view_id_,
                                    runtime_enable_needed_ && !is_worker);
      client->SetStopAtEntry(
          lynxdev::devtool::DevToolConfig::ShouldStopAtEntry(), view_id_);
    }
  }
}

void InspectorJavaScriptDebugger::OnDestroy(bool is_worker) {
  auto& client = is_worker ? worker_client_sp_ : inspector_client_sp_;
  LOGI("js debug: InspectorJavaScriptDebugger::OnDestroy, this: "
       << this << ", client: " << client << ", manager: " << manager_.lock()
       << ", is worker: " << is_worker);
  if (client != nullptr) {
    RunOnJSThread(
        [inspector_client = client, view_id = view_id_]() {
          inspector_client->DisconnectFrontend(view_id);
        },
        is_worker);
  }
}

void InspectorJavaScriptDebugger::StopDebug() {
  LOGI("js debug: InspectorJavaScriptDebugger::StopDebug, this: " << this);
  if (inspector_client_sp_ != nullptr) {
    inspector_client_sp_->DispatchMessageStop(view_id_);
  }
  if (worker_client_sp_ != nullptr) {
    worker_client_sp_->DispatchMessageStop(view_id_);
  }
}

void InspectorJavaScriptDebugger::SetInspectorManager(
    std::shared_ptr<devtool::InspectorManager> manager) {
  LOGI("js debug: InspectorJavaScriptDebugger::SetInspectorManager, this: "
       << this << ", manager: " << manager);
  manager_ = manager;
}

void InspectorJavaScriptDebugger::RunOnJSThread(base::closure closure,
                                                bool is_worker) {
  auto manager = manager_.lock();
  if (manager) {
    if (is_worker) {
      manager->RunOnWorkerThread(std::move(closure));
    } else {
      manager->RunOnJSThread(std::move(closure));
    }
  }
}

void InspectorJavaScriptDebugger::DispatchMessageToJSEngine(
    const std::string& message) {
  auto pos = message.find(kWorkerSessionIdPrefix);
  if (pos != std::string::npos && worker_client_sp_ != nullptr) {
    worker_client_sp_->DispatchMessageFromFrontend(message, view_id_);
  } else if (pos == std::string::npos && inspector_client_sp_ != nullptr) {
    inspector_client_sp_->DispatchMessageFromFrontend(message, view_id_);
  }
}

void InspectorJavaScriptDebugger::DispatchDebuggerDisableMessage() {
  if (inspector_client_sp_ != nullptr) {
    inspector_client_sp_->DispatchDebuggerDisable(view_id_);
  }
}

void InspectorJavaScriptDebugger::SetViewDestroyed(bool destroyed) {
  if (inspector_client_sp_ != nullptr) {
    inspector_client_sp_->SetViewDestroyed(destroyed, view_id_);
  }
  if (worker_client_sp_ != nullptr) {
    worker_client_sp_->SetViewDestroyed(destroyed, view_id_);
  }
}

}  // namespace devtool
}  // namespace lynx
