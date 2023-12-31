// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_TIMER_TIMER_HEAP_H_
#define VMSDK_BASE_TIMER_TIMER_HEAP_H_

#include <climits>
#include <memory>
#include <vector>

#include "basic/threading/lock.h"
#include "basic/timer/timer_node.h"

namespace vmsdk {
namespace general {
class TimerHeap {
 public:
  TimerHeap() : task_nums_(0), lock_() {}
  ~TimerHeap() {}
  uint64_t NextTimeout() {
    return !min_heap_.empty() ? min_heap_[0]->next_timeout_ : ULLONG_MAX;
  }
  bool IsEmpty() { return min_heap_.empty(); }
  void Remove(std::shared_ptr<TimerNode> node);
  std::shared_ptr<TimerNode> Pop();
  void Push(std::shared_ptr<TimerNode> node);

 private:
  void ShiftUp(int start);
  void ShiftDown(int start);

  std::vector<std::shared_ptr<TimerNode>> min_heap_;
  uint64_t task_nums_;
  Lock lock_;
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_TIMER_TIMER_HEAP_H_
