// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef MESSAGE_PUMP_IOS_H_
#define MESSAGE_PUMP_IOS_H_

#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#include "basic/task/task.h"
#include "basic/threading/message_pump.h"
#include "basic/timer/timer.h"

namespace vmsdk {
namespace general {
class MessagePumpIOSJS : public MessagePump {
 public:
  MessagePumpIOSJS(Delegate *delegate);

  virtual ~MessagePumpIOSJS();

  virtual void Run(Delegate *delegate) override;

  virtual void Stop() override;

  virtual void ScheduleWork() override;

  virtual void ScheduleDelayedWork(Closure *closure,
                                   int delayed_time) override {}

  virtual void ScheduleIntervalWork(Closure *closure,
                                    int delayed_time) override {}

  virtual std::shared_ptr<TimerNode> ScheduleDelayedWorkInWorkThread(
      Closure *closure, int delayed_time) override;

  virtual void RemoveWork(std::shared_ptr<TimerNode> task) override;

  virtual std::shared_ptr<TimerNode> ScheduleIntervalWorkInWorkThread(
      Closure *closure, int delayed_time) override;

  // Timer callback scheduled by ScheduleDelayedWork.  This does not do any
  // work, but it signals work_source_ so that delayed work can be performed
  // within the appropriate priority constraints.
  static void RunDelayedWorkTimer(CFRunLoopTimerRef timer, void *info);

  // The time that delayed_work_timer_ is scheduled to fire.  This is tracked
  // independently of CFRunLoopTimerGetNextFireDate(delayed_work_timer_)
  // to be able to reset the timer properly after waking from system sleep.
  // See PowerStateNotification.
  CFAbsoluteTime delayed_work_fire_time_;

 private:
  static void RunWorkSource(void *info);
  void RunWork();
  void ScheduleDelayedWorkImpl(uint64_t delta);
  void initRunloopAndWork(bool ismain);

  CFRunLoopRef run_loop_;
  CFRunLoopSourceRef work_source_;
  CFRunLoopTimerRef delayed_work_timer_;

  Timer timer_;
  Lock lock_;

  Delegate *delegate_;
  bool run_loop_ready_;  // flag for status of runLoop, e.g. sometimes runLoop
                         // is not ready when turn on async-layout
  bool keep_running_;
};
}  // namespace general
}  // namespace vmsdk

#endif /* MESSAGE_PUMP_IOS_H_ */
