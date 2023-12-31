//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_EVENT_REPORT_TRACKER_H_
#define LYNX_TASM_EVENT_REPORT_TRACKER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "tasm/react/prop_bundle.h"

namespace lynx {
namespace tasm {

//
// Tracker for event reporting.
//
// If you need to report events, you can use the report interface,like:
//  、、、
//      auto event = tasm::PropBundle::Create();
//      event->set_tag("lynx_code_cache");
//      event->SetProps("use_new_code_cache", enable_user_code_cache_);
//      event->SetProps("has_code_cache", false);
//      base::Tracker::Report(std::move(event));
//  、、、
//
// In JS、layout、tasm、main thread, it has an instance of thread local. The
// 'Flush(T&)' method will pass all the events you report to the native facade,
// At the same time, it will carry common data about lynx view.
//
class EventReportTracker {
 public:
  // Upload custom event with common data about lynx view.
  static void Report(std::unique_ptr<tasm::PropBundle> event);

  static std::vector<std::unique_ptr<tasm::PropBundle>> PopAll();

 private:
  static EventReportTracker* Instance();

  EventReportTracker(){};
  EventReportTracker(const EventReportTracker& timing) = delete;
  EventReportTracker& operator=(const EventReportTracker&) = delete;
  EventReportTracker(EventReportTracker&&) = delete;
  EventReportTracker& operator=(EventReportTracker&&) = delete;

  //
  // class tasm::PropBundle {
  //    //    ...
  //    static std::unique_ptr<PropBundle> Create();
  //    //    ...
  //}
  // Creating a 'tasm::PropBundle' object requires the use of the
  // 'tasm::PropBundle::Create()' method, 'tasm::PropBundle::Create()' returns a
  // 'std::unique_ptr'.
  std::vector<std::unique_ptr<tasm::PropBundle>> tracker_event_stack_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_EVENT_REPORT_TRACKER_H_
