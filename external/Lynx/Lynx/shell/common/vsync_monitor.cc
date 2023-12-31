// Copyright 2021 The Lynx Authors. All rights reserved.

#include "shell/common/vsync_monitor.h"

#include <utility>
#include <vector>

#include "base/threading/task_runner_manufactor.h"
#include "third_party/fml/message_loop.h"

namespace lynx {
namespace shell {

void VSyncMonitor::AsyncRequestVSync(Callback callback) {
  // take care: do not call AsyncRequestVSync in multiple threads, or add a
  // mutex to protect
  if (callback_) {
    // request during a frame interval, just return
    return;
  }

  DCHECK(runner_->RunsTasksOnCurrentThread());

  callback_ = std::move(callback);

  RequestVSync();
}

void VSyncMonitor::AsyncRequestVSync(uintptr_t id, Callback callback) {
  if (!callback) {
    return;
  }

  DCHECK(runner_->RunsTasksOnCurrentThread());

  // take care: do not call AsyncRequestVSync in multiple threads
  auto &&[iter, inserted] =
      secondary_callbacks_.emplace(id, std::move(callback));
  if (!inserted) {
    // the same callback already post, ignore
    return;
  }

  if (!requested_) {
    RequestVSync();
    requested_ = true;
  }
}

void VSyncMonitor::OnVSync(int64_t frame_start_time,
                           int64_t frame_target_time) {
  if (runner_->RunsTasksOnCurrentThread()) {
    OnVSyncInternal(frame_start_time, frame_target_time);
    return;
  }

  runner_->PostTask(
      [weak_self = weak_from_this(), frame_start_time, frame_target_time]() {
        auto self = weak_self.lock();
        if (self != nullptr) {
          self->OnVSyncInternal(frame_start_time, frame_target_time);
        }
      });
}

void VSyncMonitor::OnVSyncInternal(int64_t frame_start_time,
                                   int64_t frame_target_time) {
  requested_ = false;
  // if necessary, add callback mutex
  if (callback_) {
    Callback callback = std::move(callback_);
    callback(frame_start_time, frame_target_time);
  }

  if (!secondary_callbacks_.empty()) {
    std::vector<Callback> callback_vec;
    for (auto &&[id, callback] : secondary_callbacks_) {
      callback_vec.push_back(std::move(callback));
    }
    secondary_callbacks_.clear();

    for (auto &cb : callback_vec) {
      cb(frame_start_time, frame_target_time);
    }
  }
}

void VSyncMonitor::BindToCurrentThread() {
  auto ui_runner = base::UIThread::GetRunner();
  if (ui_runner->RunsTasksOnCurrentThread()) {
    runner_ = ui_runner;
    return;
  }
  runner_ = fml::MessageLoop::GetCurrent().GetTaskRunner();
}

}  // namespace shell
}  // namespace lynx
