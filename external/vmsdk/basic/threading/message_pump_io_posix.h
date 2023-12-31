// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_THREADING_MESSAGE_PUMP_IO_POSIX_H_
#define VMSDK_BASE_THREADING_MESSAGE_PUMP_IO_POSIX_H_

#include "basic/poller/poller.h"
#include "basic/task/task.h"
#include "basic/threading/condition.h"
#include "basic/threading/message_pump.h"
#include "basic/timer/timer.h"

namespace vmsdk {
namespace general {

class MessagePumpIOPosix : public MessagePump, public Poller::Watcher {
 public:
  MessagePumpIOPosix();

  virtual ~MessagePumpIOPosix();

  virtual void Run(Delegate *delegate);

  virtual void Stop();

  virtual void ScheduleWork();

  virtual void ScheduleDelayedWork(Closure *closure, int delayed_time);

  virtual void ScheduleIntervalWork(Closure *closure, int delayed_time);

  virtual void OnFileCanRead(int fd);

  virtual void OnFileCanWrite(int fd);

  Poller *poller() { return poller_.get(); }

 private:
  bool Init();

  Timer timer_;

  bool loop_running_;

  int wakeup_pipe_in_;
  int wakeup_pipe_out_;

  std::unique_ptr<Poller> poller_;

  bool quit_;
  Lock lock_destroy_;
  Condition condition_destroy_;
};
}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_THREADING_MESSAGE_PUMP_IO_POSIX_H_
