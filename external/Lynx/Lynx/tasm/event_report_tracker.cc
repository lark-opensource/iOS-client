//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/event_report_tracker.h"

#include "base/threading/thread_local.h"

namespace lynx {
namespace tasm {

EventReportTracker* EventReportTracker::Instance() {
  static lynx_thread_local(EventReportTracker) instance_;
  return &instance_;
}

void EventReportTracker::Report(std::unique_ptr<tasm::PropBundle> event) {
  EventReportTracker* instance = EventReportTracker::Instance();
  instance->tracker_event_stack_.push_back(std::move(event));
}

std::vector<std::unique_ptr<tasm::PropBundle>> EventReportTracker::PopAll() {
  EventReportTracker* instance = EventReportTracker::Instance();
  std::vector<std::unique_ptr<tasm::PropBundle>> stack =
      std::move(instance->tracker_event_stack_);
  instance->tracker_event_stack_.clear();
  return stack;
}

}  // namespace tasm
}  // namespace lynx
