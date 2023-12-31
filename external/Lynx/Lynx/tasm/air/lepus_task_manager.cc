// Copyright 2023 The Lynx Authors. All rights reserved.

#include "tasm/air/lepus_task_manager.h"

#include "lepus/context.h"
#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace air {
LepusTaskManager::FuncTask::FuncTask(lepus::Context* context,
                                     std::unique_ptr<lepus::Value> closure)
    : closure_(std::move(closure)), context_(context) {}

void LepusTaskManager::FuncTask::Execute(const lepus::Value& args) {
  context_->CallWithClosure(*closure_, {args});
}

int64_t LepusTaskManager::CacheTask(
    lepus::Context* context, std::unique_ptr<lepus::Value> callback_closure) {
  task_map_.emplace(std::make_pair(
      ++current_task_id_,
      std::make_unique<FuncTask>(context, std::move(callback_closure))));
  return current_task_id_;
}

void LepusTaskManager::InvokeTask(int64_t id, const lepus::Value& data) {
  auto iter = task_map_.find(id);
  if (iter != task_map_.end()) {
    iter->second->Execute(data);
    task_map_.erase(iter);
  }
}

uint32_t LepusTaskManager::SetTimeOut(lepus::Context* context,
                                      std::unique_ptr<lepus::Value> closure,
                                      int64_t delay_time) {
  return SetTimeTask(context, std::move(closure), delay_time, false);
}

uint32_t LepusTaskManager::SetTimeInterval(
    lepus::Context* context, std::unique_ptr<lepus::Value> closure,
    int64_t interval_time) {
  return SetTimeTask(context, std::move(closure), interval_time, true);
}

void LepusTaskManager::RemoveTimeTask(uint32_t task_id) {
  if (timer_task_manager_) {
    timer_task_manager_->StopTask(task_id);
  }
}

uint32_t LepusTaskManager::SetTimeTask(lepus::Context* context,
                                       std::unique_ptr<lepus::Value> closure,
                                       int64_t delay_time, bool is_interval) {
  EnsureTimerTaskInvokerInited();
  auto task = [func =
                   std::make_unique<FuncTask>(context, std::move(closure))]() {
    func->Execute({lepus::Value::CreateObject()});
  };
  if (is_interval) {
    return timer_task_manager_->SetInterval(std::move(task), delay_time);
  } else {
    return timer_task_manager_->SetTimeout(std::move(task), delay_time);
  }
}

LepusTaskManager::~LepusTaskManager() { Destroy(); }

void LepusTaskManager::EnsureTimerTaskInvokerInited() {
  if (!timer_task_manager_) {
    timer_task_manager_ = std::make_unique<base::TimedTaskManager>();
  }
}

void LepusTaskManager::Destroy() { task_map_.clear(); }

}  // namespace air
}  // namespace lynx
