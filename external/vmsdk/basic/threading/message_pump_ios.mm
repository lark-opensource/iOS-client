// Copyright 2017 The Vmsdk Authors. All rights reserved.

#include "basic/threading/message_pump_ios.h"

namespace vmsdk {
namespace general {

MessagePump *MessagePump::Create(Delegate *delegate) { return new MessagePumpIOS(delegate); }

const CFStringRef kMessageLoopExclusiveRunLoopMode = CFSTR("kMessageLoopExclusiveRunLoopMode");

void CallWithEHFrame(void (^block)(void)) { block(); }

MessagePumpIOS::MessagePumpIOS(Delegate *delegate) : delegate_(delegate), run_loop_ready_(false) {}

// The runLoop is belongs to layout thread if turn on async-layout
void MessagePumpIOS::Run(Delegate *delegate) {
  run_loop_ = CFRunLoopGetCurrent();
  CFRetain(run_loop_);
  CFRunLoopSourceContext source_context = CFRunLoopSourceContext();
  source_context.info = this;
  source_context.perform = RunWorkSource;
  work_source_ = CFRunLoopSourceCreate(NULL,  // allocator
                                       1,     // priority
                                       &source_context);
  CFRunLoopAddSource(run_loop_, work_source_, kCFRunLoopCommonModes);
  CFRunLoopAddSource(run_loop_, work_source_, kMessageLoopExclusiveRunLoopMode);
  run_loop_ready_ = true;
  ScheduleWork();
}

// FIXME: Dealloc should happen on the same thread as run loop
MessagePumpIOS::~MessagePumpIOS() {
  CFRunLoopSourceInvalidate(work_source_);
  CFRunLoopRemoveSource(run_loop_, work_source_, kCFRunLoopCommonModes);
  CFRunLoopRemoveSource(run_loop_, work_source_, kMessageLoopExclusiveRunLoopMode);
  CFRelease(work_source_);

  CFRelease(run_loop_);
  run_loop_ready_ = false;
}

void MessagePumpIOS::RunWorkSource(void *info) {
  MessagePumpIOS *self = static_cast<MessagePumpIOS *>(info);
  CallWithEHFrame(^{
    self->RunWork();
  });
}

void MessagePumpIOS::RunWork() { delegate_->DoWork(); }

void MessagePumpIOS::ScheduleWork() {
  if (run_loop_ready_) {
    CFRunLoopSourceSignal(work_source_);
    CFRunLoopWakeUp(run_loop_);
  }
}
}  // namespace general
}  // namespace vmsdk
