// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_BINDINGS_TIMED_TASK_ADAPTER_H_
#define LYNX_JSBRIDGE_BINDINGS_TIMED_TASK_ADAPTER_H_

#include <memory>
#include <optional>
#include <string>
#include <tuple>
#include <unordered_map>

#include "base/thread/timed_task.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {

// fuck miniapp hook out timed task, need add these fuck code for miniapp
class TimedTaskAdapter {
 public:
  explicit TimedTaskAdapter(const std::weak_ptr<Runtime>& rt,
                            const std::string& group_id,
                            bool use_provider_js_env = false);

  TimedTaskAdapter(const TimedTaskAdapter&) = delete;
  TimedTaskAdapter& operator=(const TimedTaskAdapter&) = delete;
  TimedTaskAdapter(TimedTaskAdapter&&) = default;
  TimedTaskAdapter& operator=(TimedTaskAdapter&&) = default;

  piper::Value SetTimeout(Function func, int32_t delay);

  piper::Value SetInterval(Function func, int32_t delay);

  void RemoveTask(uint32_t task);

  void RemoveAllTasks();

 private:
  uint32_t SetTimedTask(Function func, int32_t delay, bool is_interval);

  std::optional<base::TimedTaskManager> timer_;

  std::weak_ptr<Runtime> rt_;

  std::string group_id_;

  // just use for mini app
  // uint32_t:current index for mini app task
  // std::unordered_map<>:key means index for js, value means task id receive
  // for mini app
  using MiniAppTaskRecorder =
      std::tuple<uint32_t, std::unordered_map<uint32_t, int64_t>>;

  std::optional<MiniAppTaskRecorder> mini_app_task_recorder_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_BINDINGS_TIMED_TASK_ADAPTER_H_
