// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_LEPUS_TASK_MANAGER_H_
#define LYNX_TASM_AIR_LEPUS_TASK_MANAGER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/thread/timed_task.h"
#include "lepus/value.h"

namespace lynx {
namespace air {

// Air task manager cache callback closure when _TriggerLepusBridge method
// called. When a result is returned from platform, the corresponding callback
// will be found and called according to the id.
// The lifeCycle of timed callback is controlled by TimedTaskManager.
//  all closure will be destroyed in Destory method(StopAllTasks).
class LepusTaskManager {
 public:
  LepusTaskManager() = default;
  ~LepusTaskManager();
  // common method : cache , invoke and clear
  int64_t CacheTask(lepus::Context* context,
                    std::unique_ptr<lepus::Value> callback_closure);
  void InvokeTask(int64_t id, const lepus::Value& data);
  // timed task methods:setTime , setInterval , clear and invoke
  // The return type depends on TimedTaskManager。
  uint32_t SetTimeOut(lepus::Context* context,
                      std::unique_ptr<lepus::Value> closure,
                      int64_t delay_time);
  // The return type depends on TimedTaskManager。
  uint32_t SetTimeInterval(lepus::Context* context,
                           std::unique_ptr<lepus::Value> closure,
                           int64_t interval_time);
  void RemoveTimeTask(uint32_t task_id);

 private:
  // FuncTask cached in TaskMap , it has execute method
  class FuncTask {
   public:
    FuncTask(lepus::Context* context, std::unique_ptr<lepus::Value> closure);
    void Execute(const lepus::Value& args);

   private:
    // real closure callBack , operate by Execute method
    std::unique_ptr<lepus::Value> closure_;
    lepus::Context* context_;
  };

  using TaskMap = std::unordered_map<int64_t, std::unique_ptr<FuncTask>>;

  // task form _TriggerLepusBridge
  TaskMap task_map_;
  int64_t current_task_id_{0};

  // time task for _SetTimeout , _SetTimeInterval
  std::unique_ptr<base::TimedTaskManager> timer_task_manager_{nullptr};
  // The return type depends on TimedTaskManager。
  uint32_t SetTimeTask(lepus::Context* context,
                       std::unique_ptr<lepus::Value> closure,
                       int64_t delay_time, bool is_interval);

  void EnsureTimerTaskInvokerInited();
  void Destroy();
};
}  // namespace air
}  // namespace lynx

#endif  // LYNX_TASM_AIR_LEPUS_TASK_MANAGER_H_
