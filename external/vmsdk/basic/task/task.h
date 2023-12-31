// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_TASK_TASK_H_
#define VMSDK_BASE_TASK_TASK_H_

#include <queue>

#include "basic/task/callback.h"
#include "basic/threading/condition.h"

namespace vmsdk {
namespace general {
class Task {
 public:
  explicit Task(Closure *closure) : runnable_(closure) {}

  Task(Task &&other) : runnable_(std::move(other.runnable_)) {}

  Task(Task &other) : runnable_(std::move(other.runnable_)) {}

  Task(const Task &other)
      : runnable_(std::move(const_cast<Task *>(&other)->runnable_)) {}

  Task() {}

  ~Task() {}

  void Reset(Closure *closure) { runnable_.reset(closure); }

  void Run() { runnable_->Run(); }

  bool IsValid() { return runnable_ ? true : false; }

  uintptr_t GetGroupId() {
    if (runnable_ != nullptr) {
      return runnable_->GetGroupId();
    } else {
      return 0;
    }
  }

  // Move
  Task &operator=(const Task &other) {
    if (this != &other) {
      runnable_.reset(const_cast<Task *>(&other)->runnable_.release());
    }
    return *this;
  }

  Closure *GetRunnable() const { return runnable_.get(); }

 private:
  std::unique_ptr<Closure> runnable_;
};

class TaskQueue : public std::queue<Task> {
 public:
  void Swap(TaskQueue *queue) { c.swap(queue->c); }
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_TASK_TASK_H_
