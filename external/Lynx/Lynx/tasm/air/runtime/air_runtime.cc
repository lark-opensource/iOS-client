// Copyright 2023 The Lynx Authors. All rights reserved.

#include "tasm/air/runtime/air_runtime.h"

#include "lepus/table.h"
#include "lepus/value.h"
#include "shell/lynx_engine.h"

namespace lynx {
namespace air {

lepus::Value AirRuntime::TriggerBridgeSync(
    const std::string &method_name, const lynx::lepus::Value &arguments) {
  // TODO(zhangqun.29):This method has not been called yet, it will be
  // implemented after refactoring
  return lepus::Value();
}

void AirRuntime::TriggerBridgeAsync(
    lepus::Context *context, const std::string &method_name,
    const lynx::lepus::Value &arguments,
    std::unique_ptr<lepus::Value> callback_closure) {
  int64_t current_task_id =
      lepus_task_manager_->CacheTask(context, std::move(callback_closure));
  PostTask(method_name, arguments, current_task_id);
}

void AirRuntime::PostTask(const std::string &method_name,
                          const lepus::Value &arguments,
                          int64_t current_task_id) {
  static constexpr const char *kEventCallbackId = "callbackId";
  arguments.Table()->SetValue(kEventCallbackId, lepus::Value(current_task_id));
  // deep clone
  module_actor_->ActAsync(
      [method_name, clone_arguments = lepus::Value::Clone(arguments)](
          auto &air_module_handler) {
        air_module_handler->TriggerBridgeAsync(method_name, clone_arguments);
      });
}

// ensure run on engine thread
void AirRuntime::InvokeTask(int64_t id, const std::string &entry_name,
                            const lynx::lepus::Value &data) {
  lepus_task_manager_->InvokeTask(id, data);
}

uint32_t AirRuntime::SetTimeOut(lepus::Context *context,
                                std::unique_ptr<lepus::Value> closure,
                                int64_t delay_time) {
  return lepus_task_manager_->SetTimeOut(context, std::move(closure),
                                         delay_time);
}

uint32_t AirRuntime::SetTimeInterval(lepus::Context *context,
                                     std::unique_ptr<lepus::Value> closure,
                                     int64_t interval_time) {
  return lepus_task_manager_->SetTimeInterval(context, std::move(closure),
                                              interval_time);
}

void AirRuntime::RemoveTimeTask(uint32_t task_id) {
  lepus_task_manager_->RemoveTimeTask(task_id);
}

AirRuntime::AirRuntime(std::unique_ptr<AirModuleHandler> module_handler)
    : handler_thread_("Lynx_Air"),
      lepus_task_manager_(std::make_unique<LepusTaskManager>()),
      module_actor_(std::make_shared<shell::LynxActor<AirModuleHandler>>(
          std::move(module_handler), handler_thread_.GetTaskRunner())) {}

AirRuntime::~AirRuntime() {
  module_actor_->Act([](auto &module_handler) { module_handler = nullptr; });
}
}  // namespace air
}  // namespace lynx
