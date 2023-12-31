// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_TIMER_TIMER_NODE_H_
#define VMSDK_BASE_TIMER_TIMER_NODE_H_

#include <memory>

#include "basic/task/task.h"
#include "basic/timer/time_utils.h"

namespace vmsdk {
namespace general {

class TimerNode : public std::enable_shared_from_this<TimerNode> {
 public:
  TimerNode(Closure *closure, int interval_time)
      : task_(closure),
        interval_time_(interval_time),
        need_loop_(false),
        task_id_(0) {
    next_timeout_ = CurrentTimeMilliseconds() + interval_time_;
  }

  TimerNode(Closure *closure, int interval_time, bool need_loop)
      : task_(closure),
        interval_time_(interval_time),
        need_loop_(need_loop),
        task_id_(0) {
    next_timeout_ = CurrentTimeMilliseconds() + interval_time_;
  }

  TimerNode(TimerNode &other)
      : task_(other.task_),
        interval_time_(other.interval_time_),
        need_loop_(other.need_loop_),
        next_timeout_(other.next_timeout_),
        task_id_(other.task_id_) {}

  TimerNode(const TimerNode &other)
      : task_(other.task_),
        interval_time_(other.interval_time_),
        need_loop_(other.need_loop_),
        next_timeout_(other.next_timeout_),
        task_id_(other.task_id_) {}
  bool operator<(const TimerNode &other) {
    if (this->next_timeout_ != other.next_timeout_) {
      return this->next_timeout_ < other.next_timeout_;
    } else {
      return this->task_id_ < other.task_id_;
    }
  }
  Task task_;
  int interval_time_;
  bool need_loop_;
  uint64_t next_timeout_;
  uint64_t task_id_;
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_TIMER_TIMER_NODE_H_
