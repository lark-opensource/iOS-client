// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_PIPELINE_OPTION_H_
#define LYNX_TASM_REACT_PIPELINE_OPTION_H_

#include <sys/types.h>

#include <string>

#include "base/trace_event/trace_event.h"

namespace lynx {
namespace tasm {

struct PipelineOptions {
  int64_t operation_id = 0;
  // Used to mark the time-consuming of a setstate
  std::string timing_flag;
  bool is_first_screen = false;
  // true if there are UI patched
  bool has_patched = false;
  // true if has layout
  // TODO(heshan):put to a new struct like LayoutResultBundle
  // which may just consumed by FinishLayoutOperation
  bool has_layout = false;
  // true if need call DispatchLayoutUpdates
  bool trigger_layout_ = true;
  // This variable records the order of native update data. Used for syncFlush
  // only.
  uint32_t native_update_data_order_ = 0;
  // the component id of list
  int list_comp_id = 0;
#if LYNX_ENABLE_TRACING && !LYNX_ENABLE_TRACING_BACKEND_NATIVE
  void UpdateTraceDebugInfo(TraceEvent* event) const {
    auto* debug_operation_id = event->add_debug_annotations();
    debug_operation_id->set_name("operation_id");
    debug_operation_id->set_string_value(std::to_string(operation_id));
    auto* debug_timing_flag = event->add_debug_annotations();
    debug_timing_flag->set_name("timing_flag");
    debug_timing_flag->set_string_value(timing_flag);
    auto* debug_is_first_screen = event->add_debug_annotations();
    debug_is_first_screen->set_name("is_first_screen");
    debug_is_first_screen->set_string_value(is_first_screen ? "true" : "false");
    auto* debug_has_patched = event->add_debug_annotations();
    debug_has_patched->set_name("has_patched");
    debug_has_patched->set_string_value(has_patched ? "true" : "false");
    auto* debug_has_layout = event->add_debug_annotations();
    debug_has_layout->set_name("has_layout");
    debug_has_layout->set_string_value(has_layout ? "true" : "false");
  }
#endif
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_PIPELINE_OPTION_H_
