// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_UTIL_COUNT_DOWN_WAITABLE_EVENT_H_
#define CANVAS_UTIL_COUNT_DOWN_WAITABLE_EVENT_H_

#include <mutex>

#include "base/compiler_specific.h"
#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
class CountDownWaitableEvent {
 public:
  CountDownWaitableEvent(int32_t max_count) : count_(max_count - 1) {}

  CountDownWaitableEvent(const CountDownWaitableEvent&) = delete;
  CountDownWaitableEvent& operator=(const CountDownWaitableEvent&) = delete;

  void CountDown() {
    std::unique_lock<std::mutex> lk(mutex_);
    while (count_ < 0) {
      static size_t wait_count = 0;
      wait_count++;
      bool should_print = wait_count % kDownSampleRatio == 0;
      if (UNLIKELY(should_print)) {
        KRYPTON_LOGE("JS thread block due to GPU busy.");
      }
      cv_.wait(lk);
      if (UNLIKELY(should_print)) {
        KRYPTON_LOGE("JS thread wake from last block.");
      }
    }
    count_--;
  }

  void CountUp() {
    {
      std::lock_guard<std::mutex> locker(mutex_);
      count_++;
    }
    cv_.notify_one();
  }

 private:
  static const size_t kDownSampleRatio = 100;

  int32_t count_;
  std::mutex mutex_;
  std::condition_variable cv_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_UTIL_COUNT_DOWN_WAITABLE_EVENT_H_
