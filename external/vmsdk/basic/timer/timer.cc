// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/timer/timer.h"

namespace vmsdk {
namespace general {

void Timer::Loop() {
  // std::vector<std::shared_ptr<TimerNode>> vec;
  while (!timer_heap_.IsEmpty() &&
         timer_heap_.NextTimeout() <= CurrentTimeMilliseconds()) {
    std::shared_ptr<TimerNode> node = timer_heap_.Pop();
    // issue: #3360
    if (node->need_loop_) {
      uint64_t now = CurrentTimeMilliseconds();
      if (node->interval_time_ != 0) {
        uint64_t interval_to_next_fire_time =
            node->interval_time_ -
            (now - node->next_timeout_) % node->interval_time_;
        node->next_timeout_ = now + interval_to_next_fire_time;
      } else {
        node->next_timeout_ = now;
      }
    }

    node->task_.Run();
    if (node->need_loop_) {
      temporary_poped_tasks_.push_back(node);
    }
  }
  for (int i = 0; i < temporary_poped_tasks_.size(); i++) {
    std::shared_ptr<TimerNode> node = temporary_poped_tasks_[i];

    timer_heap_.Push(node);
  }
  temporary_poped_tasks_.clear();
}

void Timer::Remove(std::shared_ptr<TimerNode> node) {
  // case: the removing TimerNode is the current running one
  node->need_loop_ = false;

  std::vector<std::shared_ptr<TimerNode>>::iterator it =
      temporary_poped_tasks_.begin();
  for (; it != temporary_poped_tasks_.end(); it++) {
    std::shared_ptr<TimerNode> cur_node = *it;
    if (cur_node == node) {
      temporary_poped_tasks_.erase(it);
      return;
    }
  }

  timer_heap_.Remove(node);
}

}  // namespace general
}  // namespace vmsdk
