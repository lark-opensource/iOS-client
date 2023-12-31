// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_THREADING_MESSAGE_PUMP_POSIX_H_
#define VMSDK_BASE_THREADING_MESSAGE_PUMP_POSIX_H_

#include <string>

#include "basic/task/task.h"
#include "basic/threading/condition.h"
#include "basic/threading/message_pump.h"
#include "basic/timer/timer.h"

namespace vmsdk {
namespace general {

class MessagePumpPosix : public MessagePump {
 public:
  MessagePumpPosix();

  virtual ~MessagePumpPosix();

  virtual void Run(Delegate *delegate) override;

  virtual void ScheduleWork() override;

  virtual void ScheduleDelayedWork(Closure *closure, int delayed_time) override;
  virtual std::shared_ptr<TimerNode> ScheduleDelayedWorkInWorkThread(
      Closure *closure, int delayed_time) override;
  virtual void RemoveWork(std::shared_ptr<TimerNode> task) override;

  virtual void ScheduleIntervalWork(Closure *closure,
                                    int delayed_time) override;
  virtual std::shared_ptr<TimerNode> ScheduleIntervalWorkInWorkThread(
      Closure *closure, int delayed_time) override;

  virtual void Stop() override;

 private:
  Lock lock_;

  Condition condition_;

  Timer timer_;

  bool keep_running_;
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_THREADING_MESSAGE_PUMP_POSIX_H_
