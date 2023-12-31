//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_TIMING_H_
#define LYNX_TASM_TIMING_H_

#include <chrono>
#include <stack>
#include <string>
#include <unordered_map>
#include <utility>

#include "base/timer/time_utils.h"
#include "base/trace_event/trace_event.h"
#include "lepus/value.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace tasm {

// Declaration of timestamp key
enum class TimingKey : int32_t {
  SETUP_LOAD_TEMPLATE_START = 0,
  SETUP_LOAD_TEMPLATE_END,
  SETUP_DECODE_START,
  SETUP_DECODE_END,
  SETUP_LEPUS_EXECUTE_START,
  SETUP_LEPUS_EXECUTE_END,
  SETUP_LOAD_CORE_START,
  SETUP_LOAD_CORE_END,
  SETUP_LOAD_APP_START,
  SETUP_LOAD_APP_END,
  SETUP_CREATE_VDOM_START,
  SETUP_CREATE_VDOM_END,
  SETUP_DISPATCH_START,
  SETUP_DISPATCH_END,
  SETUP_LAYOUT_START,
  SETUP_LAYOUT_END,
  SETUP_UI_OPERATION_FLUSH_START,
  SETUP_UI_OPERATION_FLUSH_END,
  SETUP_DRAW_END,
  // for SSR
  SETUP_RENDER_PAGE_START_SSR,
  SETUP_RENDER_PAGE_END_SSR,
  SETUP_DECODE_START_SSR,
  SETUP_DECODE_END_SSR,
  SETUP_DISPATCH_START_SSR,
  SETUP_DISPATCH_END_SSR,
  SETUP_CREATE_VDOM_START_SSR,
  SETUP_CREATE_VDOM_END_SSR,
  // for SSR end
  // for Air start
  SETUP_RENDER_PAGE_START_AIR,
  SETUP_RENDER_PAGE_END_AIR,
  // for Air end
  SETUP_DIVIDE,
  UPDATE_SET_STATE_TRIGGER,
  UPDATE_CREATE_VDOM_START,
  UPDATE_CREATE_VDOM_END,
  UPDATE_DISPATCH_START,
  UPDATE_DISPATCH_END,
  UPDATE_LAYOUT_START,
  UPDATE_LAYOUT_END,
  UPDATE_UI_OPERATION_FLUSH_START,
  UPDATE_UI_OPERATION_FLUSH_END,
  // for Air start
  UPDATE_REFRESH_PAGE_START_AIR,
  UPDATE_REFRESH_PAGE_END_AIR,
  // for Air end
  UPDATE_DRAW_END,
  // Reload From JS
  UPDATE_RELOAD_FROM_JS,
  // Reload From JS End
  // for ReactLynx no-diff start
  UPDATE_DIFF_VDOM_START,
  UPDATE_DIFF_VDOM_END,
  // for ReactLynx no-diff end
  // for TTML no-diff start
  UPDATE_LEPUS_UPDATE_PAGE_START,
  UPDATE_LEPUS_UPDATE_PAGE_END,
  // for TTML no-diff end
};
using TimingMap = std::unordered_map<TimingKey, uint64_t>;

class Timing {
 public:
  explicit Timing(const std::string& timing_flag = "")
      : timing_flag_(timing_flag) {}
  Timing(TimingKey key, uint64_t timestamp, const std::string& timing_flag = "")
      : timing_flag_(timing_flag) {
    timings_[key] = timestamp;
  }
  Timing(const Timing& s) = delete;
  Timing& operator=(const Timing&) = delete;
  Timing(Timing&&) = default;
  Timing& operator=(Timing&&) = default;

  TimingMap timings_;
  std::string timing_flag_;
};

class TimingCollector {
 public:
  template <typename D>
  class Scope {
   public:
    explicit Scope(D* delegate_ptr, const std::string& flag = "")
        : delegate_ptr_(delegate_ptr) {
      TimingCollector::Instance()->timing_stack_.push(Timing(flag));
    }

    ~Scope() {
      if (delegate_ptr_ != nullptr) {
        auto& timing = TimingCollector::Instance()->timing_stack_.top();
        delegate_ptr_->SetTiming(std::move(timing));
      }
      TimingCollector::Instance()->timing_stack_.pop();
    }

    Scope(const Scope& s) = delete;
    Scope& operator=(const Scope&) = delete;
    Scope(Scope&&) = delete;
    Scope& operator=(Scope&&) = delete;

   private:
    D* delegate_ptr_;
  };

  static TimingCollector* Instance();

  void Mark(TimingKey key, uint64_t timestamp = 0);

  TimingCollector(){};
  TimingCollector(const TimingCollector& timing) = delete;
  TimingCollector& operator=(const TimingCollector&) = delete;
  TimingCollector(TimingCollector&&) = delete;
  TimingCollector& operator=(TimingCollector&&) = delete;

 private:
  std::stack<Timing> timing_stack_;
};

std::string TimingKeyToString(TimingKey key);

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_TIMING_H_
