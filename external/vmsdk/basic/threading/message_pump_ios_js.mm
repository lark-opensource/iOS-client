// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/threading/message_pump_ios_js.h"

namespace vmsdk {
namespace general {

MessagePump *MessagePump::CreateForJS(Delegate *delegate) { return new MessagePumpIOSJS(delegate); }

const CFTimeInterval kCFTimeIntervalMax = std::numeric_limits<CFTimeInterval>::max();

const CFStringRef kMessageLoopExclusiveRunLoopMode = CFSTR("kMessageLoopExclusiveRunLoopMode");

MessagePumpIOSJS::MessagePumpIOSJS(Delegate *delegate)
    : delegate_(delegate), run_loop_ready_(false), keep_running_(true) {}

void MessagePumpIOSJS::Run(Delegate *delegate) {
  initRunloopAndWork([[NSThread currentThread] isMainThread]);
}

// The runLoop is belongs to layout thread if turn on async-layout
void MessagePumpIOSJS::initRunloopAndWork(bool ismain) {
  run_loop_ = CFRunLoopGetCurrent();
  CFRetain(run_loop_);
  CFRunLoopSourceContext source_context = CFRunLoopSourceContext();
  source_context.info = this;
  source_context.perform = RunWorkSource;
  work_source_ = CFRunLoopSourceCreate(NULL,  // allocator
                                       1,     // priority
                                       &source_context);
  CFRunLoopAddSource(run_loop_, work_source_, kCFRunLoopCommonModes);

  if (ismain) {
    CFRunLoopAddSource(run_loop_, work_source_, kMessageLoopExclusiveRunLoopMode);
    run_loop_ready_ = true;
    ScheduleWork();
  } else {
    // Set a repeating timer with a preposterous firing time and interval.  The
    // timer will effectively never fire as-is.  The firing time will be
    // adjusted as needed when ScheduleDelayedWork is called.
    CFRunLoopTimerContext timer_context = CFRunLoopTimerContext();
    timer_context.info = this;
    delayed_work_timer_ = CFRunLoopTimerCreate(NULL,                // allocator
                                               kCFTimeIntervalMax,  // fire time
                                               kCFTimeIntervalMax,  // interval
                                               0,                   // flags
                                               0,                   // priority
                                               RunDelayedWorkTimer, &timer_context);
    // InvokeForEnabledModes(&CFRunLoopAddTimer, delayed_work_timer_);
    CFRunLoopAddTimer(run_loop_, delayed_work_timer_, kCFRunLoopCommonModes);

    do {
      @autoreleasepool {
        RunWork();
        run_loop_ready_ = true;
        [[NSRunLoop currentRunLoop] run];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
      }
    } while (YES);
  }
}

// FIXME: Dealloc should happen on the same thread as run loop
MessagePumpIOSJS::~MessagePumpIOSJS() {
  run_loop_ready_ = false;
  CFRunLoopSourceInvalidate(work_source_);
  CFRunLoopRemoveSource(run_loop_, work_source_, kCFRunLoopCommonModes);
  CFRunLoopRemoveSource(run_loop_, work_source_, kMessageLoopExclusiveRunLoopMode);
  CFRelease(work_source_);
  CFRelease(run_loop_);
  run_loop_ready_ = false;
}

std::shared_ptr<TimerNode> MessagePumpIOSJS::ScheduleDelayedWorkInWorkThread(Closure *closure,
                                                                             int delayed_time) {
  auto node = std::make_shared<TimerNode>(closure, delayed_time);
  timer_.SetTimerNode(node);
  ScheduleDelayedWorkImpl(delayed_time);
  return node;
}

void MessagePumpIOSJS::RemoveWork(std::shared_ptr<TimerNode> task) { timer_.Remove(task); }

std::shared_ptr<TimerNode> MessagePumpIOSJS::ScheduleIntervalWorkInWorkThread(Closure *closure,
                                                                              int delayed_time) {
  auto node = std::make_shared<TimerNode>(closure, delayed_time, true);
  timer_.SetTimerNode(node);
  ScheduleDelayedWorkImpl(delayed_time);
  return node;
}

// Called from the run loop.
// static
void MessagePumpIOSJS::RunDelayedWorkTimer(CFRunLoopTimerRef timer, void *info) {
  MessagePumpIOSJS *self = static_cast<MessagePumpIOSJS *>(info);
  self->RunWork();
}

// Called from the run loop.
// static
void MessagePumpIOSJS::RunWorkSource(void *info) {
  MessagePumpIOSJS *self = static_cast<MessagePumpIOSJS *>(info);
  self->RunWork();
}

void MessagePumpIOSJS::RunWork() {
  AutoLock lock(lock_);
  if (!keep_running_) {
    return;
  }
  timer_.Loop();
  keep_running_ &= delegate_->DoWork();
  if (keep_running_) {
    int64_t wait_time = 0;
    if (timer_.NextTimeout() != ULLONG_MAX) {
      wait_time = timer_.NextTimeout() - CurrentTimeMilliseconds();
      if (wait_time <= 0) {
        ScheduleWork();
      } else {
        ScheduleDelayedWorkImpl(wait_time);
      }
    }
  }
}

void MessagePumpIOSJS::ScheduleWork() {
  if (run_loop_ready_ && run_loop_ != nil) {
    CFRunLoopSourceSignal(work_source_);
    CFRunLoopWakeUp(run_loop_);
  }
}

void MessagePumpIOSJS::ScheduleDelayedWorkImpl(uint64_t delta) {
  CFRunLoopTimerSetTolerance(delayed_work_timer_, 0);
  const double delta_second = (double)delta / 1000.0;
  CFRunLoopTimerSetNextFireDate(delayed_work_timer_, CFAbsoluteTimeGetCurrent() + delta_second);
}

// Can only be called from the thread that owns the MessageLoop.
void MessagePumpIOSJS::Stop() { keep_running_ = false; }

}  // namespace general
}  // namespace vmsdk
