// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/bindings/timed_task_adapter.h"

#include <utility>

#include "jsbridge/appbrand/js_thread_provider.h"
#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace piper {

namespace {

class AdapterTask : public provider::piper::Task {
 public:
  explicit AdapterTask(lynx::base::closure closure,
                       lynx::base::closure finish_callback = nullptr)
      : closure_(std::move(closure)),
        finish_callback_(std::move(finish_callback)) {}

  int64_t Id() override { return reinterpret_cast<int64_t>(&closure_); }

  void Run() override {
    DCHECK(closure_);
    closure_();
    if (finish_callback_) {
      finish_callback_();
    }
  }

 private:
  lynx::base::closure closure_;

  lynx::base::closure finish_callback_;
};

}  // namespace

TimedTaskAdapter::TimedTaskAdapter(const std::weak_ptr<Runtime>& rt,
                                   const std::string& group_id,
                                   bool use_provider_js_env)
    : rt_(rt) {
  if (!use_provider_js_env) {
    timer_ = std::make_optional<base::TimedTaskManager>();
    return;
  }

  // mini app logic
  group_id_ = group_id;
  mini_app_task_recorder_ = std::make_optional<MiniAppTaskRecorder>();
}

piper::Value TimedTaskAdapter::SetTimeout(Function func, int32_t delay) {
  return piper::Value(
      static_cast<int>(SetTimedTask(std::move(func), delay, false)));
}

piper::Value TimedTaskAdapter::SetInterval(Function func, int32_t delay) {
  return piper::Value(
      static_cast<int>(SetTimedTask(std::move(func), delay, true)));
}

uint32_t TimedTaskAdapter::SetTimedTask(Function func, int32_t delay,
                                        bool is_interval) {
  auto task = fml::MakeCopyable([weak_rt = rt_, func = std::move(func)]() {
    auto rt = weak_rt.lock();
    if (rt) {
      piper::Scope scope(*rt);
      if (!func.call(*rt, nullptr, 0)) {
        rt->reportJSIException(
            JSINativeException("TimedTask failed: An exception occurred when "
                               "run timer's js task!"));
      }
    }
  });

  // mini app logic
  if (mini_app_task_recorder_) {
    [[maybe_unused]] auto& [current, task_ids] = *mini_app_task_recorder_;
    uint32_t index = ++current;
    // c++20 support structured binding, now can only capture like this
    auto* adapter_task = new AdapterTask(
        std::move(task),
        [index, task_ids = &task_ids]() { task_ids->erase(index); });
    task_ids.emplace(index, adapter_task->Id());
    provider::piper::JSThreadProviderGenerator::Provider().OnPostTaskDelay(
        adapter_task, delay, group_id_.c_str());
    return index;
  }

  if (is_interval) {
    return timer_->SetInterval(std::move(task), static_cast<int64_t>(delay));
  }
  return timer_->SetTimeout(std::move(task), static_cast<int64_t>(delay));
}

void TimedTaskAdapter::RemoveTask(uint32_t task) {
  if (timer_) {
    timer_->StopTask(task);
    return;
  }

  // for mini app logic
  [[maybe_unused]] auto& [current, task_ids] = *mini_app_task_recorder_;
  auto iter = task_ids.find(task);
  if (iter != task_ids.end()) {
    provider::piper::JSThreadProviderGenerator::Provider().OnRemoveTask(
        iter->second, group_id_.c_str());
    task_ids.erase(iter);
  }
}

void TimedTaskAdapter::RemoveAllTasks() {
  if (timer_) {
    timer_->StopAllTasks();
    return;
  }

  // for mini app logic
  [[maybe_unused]] auto& [current, task_ids] = *mini_app_task_recorder_;
  for (const auto& [index, id] : task_ids) {
    provider::piper::JSThreadProviderGenerator::Provider().OnRemoveTask(
        id, group_id_.c_str());
  }
  task_ids.clear();
}

}  // namespace piper
}  // namespace lynx
