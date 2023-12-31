// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_RUNTIME_AIR_RUNTIME_H_
#define LYNX_TASM_AIR_RUNTIME_AIR_RUNTIME_H_

#include <memory>
#include <string>
#include <utility>

#include "tasm/air/bridge/air_module_handler.h"
#include "tasm/air/lepus_task_manager.h"
#include "third_party/fml/thread.h"

namespace lynx {
namespace air {

// be sure use in engine thread
class AirRuntime {
 public:
  explicit AirRuntime(std::unique_ptr<AirModuleHandler> module_handler);
  ~AirRuntime();

  AirRuntime(const AirRuntime& runtime) = delete;
  AirRuntime& operator=(const AirRuntime& runtime) = delete;

  lepus::Value TriggerBridgeSync(const std::string& method_name,
                                 const lynx::lepus::Value& arguments);
  void TriggerBridgeAsync(lepus::Context* context,
                          const std::string& method_name,
                          const lynx::lepus::Value& arguments,
                          std::unique_ptr<lepus::Value> callback_closure);

  uint32_t SetTimeOut(lepus::Context* context,
                      std::unique_ptr<lepus::Value> closure,
                      int64_t delay_time);
  uint32_t SetTimeInterval(lepus::Context* context,
                           std::unique_ptr<lepus::Value> closure,
                           int64_t interval_time);

  void InvokeTask(int64_t id, const std::string& entry_name,
                  const lepus::Value& data);

  void RemoveTimeTask(uint32_t task_id);

 private:
  void PostTask(const std::string& method_name, const lepus::Value& arguments,
                int64_t current_task_id);

  fml::Thread handler_thread_;
  std::unique_ptr<LepusTaskManager> lepus_task_manager_;
  std::shared_ptr<shell::LynxActor<AirModuleHandler>> module_actor_;
};
}  // namespace air
}  // namespace lynx

#endif  // LYNX_TASM_AIR_RUNTIME_AIR_RUNTIME_H_
