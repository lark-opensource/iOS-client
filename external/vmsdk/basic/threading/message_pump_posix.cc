// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/threading/message_pump_posix.h"

#include "basic/log/logging.h"

namespace vmsdk {
namespace general {

MessagePumpPosix::MessagePumpPosix()
    : lock_(), condition_(lock_), keep_running_(true) {}

MessagePumpPosix::~MessagePumpPosix() {}

void MessagePumpPosix::ScheduleWork() { condition_.Signal(); }

void MessagePumpPosix::ScheduleDelayedWork(Closure *closure, int delayed_time) {
  auto node = std::make_shared<TimerNode>(closure, delayed_time);
  timer_.SetTimerNode(node);
  condition_.Signal();
}

std::shared_ptr<TimerNode> MessagePumpPosix::ScheduleDelayedWorkInWorkThread(
    Closure *closure, int delayed_time) {
  auto node = std::make_shared<TimerNode>(closure, delayed_time);
  timer_.SetTimerNode(node);
  condition_.Signal();
  return node;
}

void MessagePumpPosix::RemoveWork(std::shared_ptr<TimerNode> task) {
  timer_.Remove(task);
}

void MessagePumpPosix::ScheduleIntervalWork(Closure *closure,
                                            int delayed_time) {
  auto node = std::make_shared<TimerNode>(closure, delayed_time, true);
  timer_.SetTimerNode(node);
  condition_.Signal();
}

std::shared_ptr<TimerNode> MessagePumpPosix::ScheduleIntervalWorkInWorkThread(
    Closure *closure, int delayed_time) {
  auto node = std::make_shared<TimerNode>(closure, delayed_time, true);
  timer_.SetTimerNode(node);
  condition_.Signal();
  return node;
}

void MessagePumpPosix::Run(Delegate *delegate) {
  {
    while (keep_running_) {
      AutoLock lock(lock_);
      if (keep_running_) {
        timer_.Loop();
        keep_running_ &= delegate->DoWork();
        if (keep_running_) {
          if (timer_.NextTimeout() == ULLONG_MAX) {
            condition_.Wait();
          } else {
            int64_t wait_time =
                timer_.NextTimeout() - CurrentTimeMilliseconds();
            wait_time = wait_time > 0 ? wait_time : 0;
            condition_.Wait(wait_time);
          }
        }
      }
    }
  }
  delegate->DoQuit();
}

// Can only be called from the thread that owns the MessageLoop.
void MessagePumpPosix::Stop() { keep_running_ = false; }

}  // namespace general
}  // namespace vmsdk
