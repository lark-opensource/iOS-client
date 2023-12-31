// Copyright 2023 The Lynx Authors. All rights reserved.

#include "shell/thread_mode_auto_switch.h"

#include "base/threading/task_runner_manufactor.h"
#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace shell {

ThreadModeAutoSwitch::ThreadModeAutoSwitch(ThreadModeManager& manager) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ThreadModeAutoSwitch.Create");
  if (!manager) {
    return;
  }

  manager_ = &manager;

  // mark manager to be held.
  manager_->is_held = true;

  merger_ = std::make_optional<base::ThreadMerger>(manager.ui_runner,
                                                   manager.engine_runner);

  // transfer the queue after the threads have merged.
  manager.queue->Transfer(base::ThreadStrategyForRendering::PART_ON_LAYOUT);
}

ThreadModeAutoSwitch::~ThreadModeAutoSwitch() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ThreadModeAutoSwitch.Release");

  if (manager_ == nullptr) {
    return;
  }

  // transfer the queue before the threads have unmerged.
  // The threads will unmerge when merger_ release.
  manager_->queue->Transfer(base::ThreadStrategyForRendering::MULTI_THREADS);

  // mark manager to be unheld.
  manager_->is_held = false;
}

}  // namespace shell
}  // namespace lynx
