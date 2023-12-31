// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_BACKGROUND_LOCK_H_
#define CANVAS_BACKGROUND_LOCK_H_

#include <mutex>

#include "base/no_destructor.h"
#include "canvas/base/log.h"

namespace lynx {
namespace canvas {

// iOS forbids executing GL calls in background. This util helps to prevent it.
class BackgroundLock {
 public:
  static BackgroundLock& Instance() {
    static base::NoDestructor<BackgroundLock> instance_;
    return *instance_;
  }

  void NotifyEnteringForeground() {
    KRYPTON_LOGI("[lock] Entering foreground");
    {
      std::unique_lock<std::mutex> lock(lock_);
      in_background_ = false;
    }
    cv_.notify_one();
  }

  void NotifyEnteringBackground() {
    KRYPTON_LOGI("[lock] Entering background");
    std::unique_lock<std::mutex> lock(lock_);
    in_background_ = true;
  }

  void NotifyBecomeActive() {
    KRYPTON_LOGI("[lock] Become active");
    {
      std::unique_lock<std::mutex> lock(lock_);
      resign_active_ = false;
    }
    cv_.notify_one();
  }

  void NotifyResignActive() {
    KRYPTON_LOGI("[lock] Resign active");
    std::unique_lock<std::mutex> lock(lock_);
    resign_active_ = true;
  }

  void WaitForForeground() {
    std::unique_lock<std::mutex> lock(lock_);
    while (in_background_ || resign_active_) {
      KRYPTON_LOGI("[lock] Blocking thread in background");
      cv_.wait(lock);
      KRYPTON_LOGI("[lock] Waking up thread");
    }
  }

 private:
  bool in_background_ = false;
  bool resign_active_ = false;
  std::mutex lock_;
  std::condition_variable cv_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_BACKGROUND_LOCK_H_
