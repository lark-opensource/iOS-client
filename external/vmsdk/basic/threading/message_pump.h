// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_THREADING_MESSAGE_PUMP_H_
#define VMSDK_BASE_THREADING_MESSAGE_PUMP_H_

#include "basic/task/callback.h"
#include "basic/timer/timer_node.h"

namespace vmsdk {
namespace general {

class TimerNode;
class MessagePump {
 public:
  class Delegate {
   public:
    virtual ~Delegate() {}
    virtual bool DoWork() = 0;
    virtual void DoQuit() = 0;
  };

  MessagePump() {}

  virtual ~MessagePump() {}

  virtual void Run(Delegate *delegate) {}

  virtual void Stop() {}

  virtual void ScheduleWork() = 0;

  virtual void ScheduleDelayedWork(Closure *closure, int delayed_time) = 0;
  virtual std::shared_ptr<TimerNode> ScheduleDelayedWorkInWorkThread(
      Closure *closure, int delayed_time) {
    return std::shared_ptr<TimerNode>(nullptr);
  }
  virtual void RemoveWork(std::shared_ptr<TimerNode> task) {}

  virtual void ScheduleIntervalWork(Closure *closure, int delayed_time) = 0;
  virtual std::shared_ptr<TimerNode> ScheduleIntervalWorkInWorkThread(
      Closure *closure, int delayed_time) {
    return std::shared_ptr<TimerNode>(nullptr);
  }

  static MessagePump *Create(Delegate *delegate);
  static MessagePump *CreateForJS(Delegate *delegate);
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_THREADING_MESSAGE_PUMP_H_
