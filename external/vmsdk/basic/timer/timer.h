// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_TIMER_TIMER_H_
#define VMSDK_BASE_TIMER_TIMER_H_

#include <memory>
#include <vector>

#include "basic/timer/timer_heap.h"

namespace vmsdk {
namespace general {
class Timer {
 public:
  void Loop();

  uint64_t NextTimeout() { return timer_heap_.NextTimeout(); }

  void SetTimerNode(std::shared_ptr<TimerNode> node) { timer_heap_.Push(node); }

  void Remove(std::shared_ptr<TimerNode> node);

 private:
  TimerHeap timer_heap_;
  std::vector<std::shared_ptr<TimerNode>> temporary_poped_tasks_;
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_TIMER_TIMER_H_
