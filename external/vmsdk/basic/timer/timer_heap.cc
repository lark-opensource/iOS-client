// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/timer/timer_heap.h"

#include "basic/log/logging.h"

namespace vmsdk {
namespace general {

std::shared_ptr<TimerNode> TimerHeap::Pop() {
  AutoLock lock(lock_);
  std::shared_ptr<TimerNode> node = min_heap_[0];
  min_heap_[0] = min_heap_.back();
  min_heap_.pop_back();
  ShiftDown(0);
  return node;
}

void TimerHeap::Remove(std::shared_ptr<TimerNode> node) {
  AutoLock lock(lock_);
  int index = -1;
  for (int i = 0; i < min_heap_.size(); i++) {
    if (min_heap_[i] == node) {
      min_heap_[i] = min_heap_.back();
      min_heap_.pop_back();
      index = i;
    }
  }
  if (index != -1) {
    ShiftDown(index);
  }
}

void TimerHeap::Push(std::shared_ptr<TimerNode> node) {
  AutoLock lock(lock_);
  task_nums_++;
  node->task_id_ = task_nums_;
  min_heap_.push_back(node);
  ShiftUp(static_cast<int>(min_heap_.size()) - 1);
}

void TimerHeap::ShiftUp(int start) {
  int current = start;
  int parent = (current - 1) / 2;
  while (current > 0 && *min_heap_[current] < *min_heap_[parent]) {
    std::shared_ptr<TimerNode> node = min_heap_[current];
    min_heap_[current] = min_heap_[parent];
    min_heap_[parent] = node;
    current = parent;
    parent = (current - 1) / 2;
  }
}

void TimerHeap::ShiftDown(int start) {
  if (min_heap_.empty()) return;
  while (true) {
    int left_child = start * 2 + 1;
    int right_child = start * 2 + 2;
    int index = 0;
    if (right_child <= (min_heap_.size() - 1)) {
      if (*min_heap_[start] < *min_heap_[left_child] &&
          *min_heap_[start] < *min_heap_[right_child]) {
        break;
      } else {
        if (*min_heap_[left_child] < *min_heap_[right_child]) {
          index = left_child;
        } else {
          index = right_child;
        }
      }
    } else if (left_child == min_heap_.size() - 1) {
      if (*min_heap_[left_child] < *min_heap_[start]) {
        index = left_child;
      } else {
        break;
      }
    } else {
      break;
    }

    std::shared_ptr<TimerNode> node = min_heap_[index];
    min_heap_[index] = min_heap_[start];
    min_heap_[start] = node;
    start = index;
  }
}
}  // namespace general
}  // namespace vmsdk
