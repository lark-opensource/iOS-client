
#include "jsb/runtime/task_runner.h"

namespace vmsdk {
namespace runtime {

void TaskRunner::PostTask(general::Closure *task) {
  if (task == nullptr) {
    return;
  }
  if (thread_) {
    thread_->Looper()->PostTask(task);
  } else if (running_) {
    task->Run();
    delete task;
  }
}

void TaskRunner::PostTaskAtFront(general::Closure *task) {
  if (task == nullptr) {
    return;
  }
  if (thread_) {
    thread_->Looper()->PostTaskAtFront(task);
  }
}

void TaskRunner::RunNowOrPostTaskAtFront(general::Closure *task) {
  if (task == nullptr) {
    return;
  }
  if (CanRunNow()) {
    task->Run();
    delete task;
  } else {
    thread_->Looper()->PostTaskAtFront(task);
  }
}

void TaskRunner::RunNowOrPostTask(general::Closure *task) {
  if (task == nullptr) {
    return;
  }
  if (CanRunNow()) {
    task->Run();
    delete task;
  } else {
    thread_->Looper()->PostTask(task);
  }
}

std::shared_ptr<general::TimerNode> TaskRunner::PostDelayedTask(
    general::Closure *task, int32_t delayed_milliseconds) {
  if (task == nullptr || thread_ == nullptr) {
    delete task;
    return nullptr;
  }
  return thread_->Looper()->PostDelayedTaskInWorkThread(task,
                                                        delayed_milliseconds);
}

std::shared_ptr<general::TimerNode> TaskRunner::PostIntervalTask(
    general::Closure *task, int32_t delayed_milliseconds) {
  if (task == nullptr || thread_ == nullptr) {
    delete task;
    return nullptr;
  }
  return thread_->Looper()->PostIntervalTaskInWorkThread(task,
                                                         delayed_milliseconds);
}

void TaskRunner::RemoveTask(const std::shared_ptr<general::TimerNode> &task) {
  if (thread_ != nullptr && task != nullptr) {
    thread_->Looper()->RemoveTask(task);
  }
}

void TaskRunner::RemoveTaskByGroupId(uintptr_t group_Id) {
  if (thread_ != nullptr) {
    thread_->Looper()->RemoveTaskByGroupId(group_Id);
  }
}

void TaskRunner::RemoveTasks() {
  if (thread_ != nullptr) {
    thread_->Looper()->RemoveTasks();
  }
}

void TaskRunner::RunNowOrPostTask2(std::shared_ptr<TaskRunner> runner,
                                   general::Closure *task) {
  if (runner) {
    runner->RunNowOrPostTask(task);
  }
}

bool TaskRunner::CanRunNow() {
  return running_ &&
         (!thread_ || general::MessageLoop::current() == thread_->Looper());
}
}  // namespace runtime
}  // namespace vmsdk
