// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef MESSAGE_PUMP_IOS_H_
#define MESSAGE_PUMP_IOS_H_

#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#include "basic/threading/message_pump.h"

namespace vmsdk {
namespace general {
class MessagePumpIOS : public MessagePump {
 public:
  MessagePumpIOS(Delegate *delegate);

  virtual ~MessagePumpIOS();

  virtual void Run(Delegate *delegate);

  virtual void ScheduleWork();

  virtual void ScheduleDelayedWork(Closure *closure, int delayed_time) {}

  virtual void ScheduleIntervalWork(Closure *closure, int delayed_time) {}

 private:
  static void RunWorkSource(void *info);
  void RunWork();
  CFRunLoopRef run_loop_;
  CFRunLoopSourceRef work_source_;
  Delegate *delegate_;
  bool run_loop_ready_;  // flag for status of runLoop, e.g. sometimes runLoop
                         // is not ready when turn on async-layout
};
}  // namespace general
}  // namespace vmsdk

#endif /* MESSAGE_PUMP_IOS_H_ */
