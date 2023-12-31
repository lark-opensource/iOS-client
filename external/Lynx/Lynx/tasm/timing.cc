//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/timing.h"

#include "base/threading/thread_local.h"

namespace lynx {
namespace tasm {

TimingCollector* TimingCollector::Instance() {
  static lynx_thread_local(TimingCollector) instance_;
  return &instance_;
}

void TimingCollector::Mark(TimingKey key, uint64_t timestamp) {
  // If timing_stack_ is empty or the timing key is a SETUP_DIVIDE, no
  // processing is required
  if (timing_stack_.empty() || key == TimingKey::SETUP_DIVIDE) {
    return;
  }
  Timing& top_timings = timing_stack_.top();
  // UpdateData phase must have a timing flag.
  if (key > TimingKey::SETUP_DIVIDE && top_timings.timing_flag_.empty()) {
    return;
  }
  TRACE_EVENT_INSTANT(
      LYNX_TRACE_CATEGORY, nullptr,
      [&top_timings, key](lynx::perfetto::EventContext ctx) {
        ctx.event()->set_name("Timing::" + TimingKeyToString(key) + "." +
                              top_timings.timing_flag_);
      });
  top_timings.timings_[key] =
      timestamp > 0 ? timestamp : base::CurrentSystemTimeMilliseconds();
}

std::string TimingKeyToString(TimingKey key_t) {
  switch (key_t) {
    case TimingKey::SETUP_LOAD_TEMPLATE_START: {
      return "setup_load_template_start";
    }
    case TimingKey::SETUP_LOAD_TEMPLATE_END: {
      return "setup_load_template_end";
    }
    case TimingKey::SETUP_DECODE_START: {
      return "setup_decode_start";
    }
    case TimingKey::SETUP_DECODE_END: {
      return "setup_decode_end";
    }
    case TimingKey::SETUP_LEPUS_EXECUTE_START: {
      return "setup_lepus_excute_start";
    }
    case TimingKey::SETUP_LEPUS_EXECUTE_END: {
      return "setup_lepus_excute_end";
    }
    case TimingKey::SETUP_LOAD_CORE_START: {
      return "setup_load_core_start";
    }
    case TimingKey::SETUP_LOAD_CORE_END: {
      return "setup_load_core_end";
    }
    case TimingKey::SETUP_LOAD_APP_START: {
      return "setup_load_app_start";
    }
    case TimingKey::SETUP_LOAD_APP_END: {
      return "setup_load_app_end";
    }
    case TimingKey::SETUP_CREATE_VDOM_START: {
      return "setup_create_vdom_start";
    }
    case TimingKey::SETUP_CREATE_VDOM_END: {
      return "setup_create_vdom_end";
    }
    case TimingKey::SETUP_DISPATCH_START: {
      return "setup_dispatch_start";
    }
    case TimingKey::SETUP_DISPATCH_END: {
      return "setup_dispatch_end";
    }
    case TimingKey::SETUP_LAYOUT_START: {
      return "setup_layout_start";
    }
    case TimingKey::SETUP_LAYOUT_END: {
      return "setup_layout_end";
    }
    case TimingKey::SETUP_UI_OPERATION_FLUSH_START: {
      return "setup_ui_operation_flush_start";
    }
    case TimingKey::SETUP_UI_OPERATION_FLUSH_END: {
      return "setup_ui_operation_flush_end";
    }
    case TimingKey::SETUP_DRAW_END: {
      return "setup_draw_end";
    }
    case TimingKey::SETUP_RENDER_PAGE_START_SSR: {
      return "setup_render_page_start_ssr";
    }
    case TimingKey::SETUP_RENDER_PAGE_END_SSR: {
      return "setup_render_page_end_ssr";
    }
    case TimingKey::SETUP_DECODE_START_SSR: {
      return "setup_decode_start_ssr";
    }
    case TimingKey::SETUP_DECODE_END_SSR: {
      return "setup_decode_end_ssr";
    }
    case TimingKey::SETUP_DISPATCH_START_SSR: {
      return "setup_dispatch_start_ssr";
    }
    case TimingKey::SETUP_DISPATCH_END_SSR: {
      return "setup_dispatch_end_ssr";
    }
    case TimingKey::SETUP_CREATE_VDOM_START_SSR: {
      return "setup_create_vdom_start_ssr";
    }
    case TimingKey::SETUP_CREATE_VDOM_END_SSR: {
      return "setup_create_vdom_end_ssr";
    }
    case TimingKey::SETUP_RENDER_PAGE_START_AIR: {
      return "setup_render_page_start_air";
    }
    case TimingKey::SETUP_RENDER_PAGE_END_AIR: {
      return "setup_render_page_end_air";
    }
    case TimingKey::UPDATE_SET_STATE_TRIGGER: {
      return "update_set_state_trigger";
    }
    case TimingKey::UPDATE_CREATE_VDOM_START: {
      return "update_create_vdom_start";
    }
    case TimingKey::UPDATE_CREATE_VDOM_END: {
      return "update_create_vdom_end";
    }
    case TimingKey::UPDATE_DISPATCH_START: {
      return "update_dispatch_start";
    }
    case TimingKey::UPDATE_DISPATCH_END: {
      return "update_dispatch_end";
    }
    case TimingKey::UPDATE_LAYOUT_START: {
      return "update_layout_start";
    }
    case TimingKey::UPDATE_LAYOUT_END: {
      return "update_layout_end";
    }
    case TimingKey::UPDATE_UI_OPERATION_FLUSH_START: {
      return "update_ui_operation_flush_start";
    }
    case TimingKey::UPDATE_UI_OPERATION_FLUSH_END: {
      return "update_ui_operation_flush_end";
    }
    case TimingKey::UPDATE_DRAW_END: {
      return "update_draw_end";
    }
    case TimingKey::UPDATE_REFRESH_PAGE_START_AIR: {
      return "update_refresh_page_start_air";
    }
    case TimingKey::UPDATE_REFRESH_PAGE_END_AIR: {
      return "update_refresh_page_end_air";
    }
    case TimingKey::UPDATE_DIFF_VDOM_START: {
      return "update_diff_vdom_start";
    }
    case TimingKey::UPDATE_DIFF_VDOM_END: {
      return "update_diff_vdom_end";
    }
    case TimingKey::UPDATE_LEPUS_UPDATE_PAGE_START: {
      return "update_lepus_update_page_start";
    }
    case TimingKey::UPDATE_LEPUS_UPDATE_PAGE_END: {
      return "update_lepus_update_page_end";
    }
    default:
      return "";
  }
}

}  // namespace tasm
}  // namespace lynx
