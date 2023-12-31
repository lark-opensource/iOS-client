// Copyright 2020 The Lynx Authors. All rights reserved.

#include "tracing/frame_trace_service.h"

#if LYNX_ENABLE_TRACING
#include "base/log/logging.h"
#include "tracing/trace_event_devtool.h"

namespace lynx {
namespace base {
namespace tracing {

FrameTraceService::FrameTraceService() : thread_("CrBrowserMain") {}

void FrameTraceService::Initialize() {
  thread_.GetTaskRunner()->PostTask([] {
    TRACE_EVENT_DEVTOOL(
        LYNX_TRACE_CATEGORY_DEVTOOL_TIMELINE, "TracingStartedInBrowser",
        [](TraceEvent* event) {
          auto* legacy_event = event->set_legacy_event();
          legacy_event->set_phase('I');
          legacy_event->set_unscoped_id(1);
          auto* debug = event->add_debug_annotations();
          debug->set_name("data");
          std::string data =
              R"({"frameTreeNodeId":"", "frames":[{"frame":"","name":"","processId":)";
          // just a placeholder for protocol
          data += "0";
          data += R"(,"url":""}],"persistentIds":true})";
          debug->set_legacy_json_value(data);
        });
    TRACE_EVENT_DEVTOOL(LYNX_TRACE_CATEGORY_DEVTOOL_TIMELINE, "SetLayerTreeId",
                        [](TraceEvent* event) {
                          auto* legacy_event = event->set_legacy_event();
                          legacy_event->set_phase('I');
                          legacy_event->set_unscoped_id(1);
                          auto* debug = event->add_debug_annotations();
                          debug->set_name("data");
                          const std::string data =
                              R"({"frame":"", "layerTreeId":1})";
                          debug->set_legacy_json_value(data);
                        });
  });
}

void FrameTraceService::SendScreenshots(const std::string& snapshot) {
  thread_.GetTaskRunner()->PostTask(
      [self = shared_from_this(), snapshot]() { self->Screenshots(snapshot); });
}

void FrameTraceService::Screenshots(const std::string& snapshot) {
  TRACE_EVENT_DEVTOOL(LYNX_TRACE_CATEGORY_SCREENSHOTS, "Screenshot",
                      [&snapshot](TraceEvent* event) {
                        auto* legacy_event = event->set_legacy_event();
                        legacy_event->set_phase('O');
                        legacy_event->set_unscoped_id(1);
                        auto* debug = event->add_debug_annotations();
                        debug->set_name("snapshot");
                        debug->set_string_value(snapshot);
                      });
}

void FrameTraceService::SendFPSData(const uint64_t& startTime,
                                    const uint64_t& endTime) {
  thread_.GetTaskRunner()->PostTask(
      [self = shared_from_this(), startTime, endTime]() {
        self->FPSTrace(startTime, endTime);
      });
}

void FrameTraceService::FPSTrace(const uint64_t startTime,
                                 const uint64_t endTime) {
  lynx::base::tracing::TraceBackend::TraceEventWithTimestamp(
      LYNX_TRACE_CATEGORY_FPS, "NeedsBeginFrameChanged", startTime,
      TRACE_EVENT_PHASE_BEGIN, [](TraceEvent* event) {
        auto* legacy_event = event->set_legacy_event();
        legacy_event->set_phase('I');
        legacy_event->set_unscoped_id(1);
        auto* dataDebug = event->add_debug_annotations();
        const std::string data = R"({"needsBeginFrame":1})";
        dataDebug->set_name("data");
        dataDebug->set_legacy_json_value(data);
        auto* idDebug = event->add_debug_annotations();
        idDebug->set_name("layerTreeId");
        idDebug->set_int_value(1);
      });
  lynx::base::tracing::TraceBackend::TraceEventWithTimestamp(
      LYNX_TRACE_CATEGORY_FPS, "BeginFrame", startTime, TRACE_EVENT_PHASE_BEGIN,
      [](TraceEvent* event) {
        auto* legacy_event = event->set_legacy_event();
        legacy_event->set_phase('I');
        legacy_event->set_unscoped_id(1);
        auto* idDebug = event->add_debug_annotations();
        idDebug->set_name("layerTreeId");
        idDebug->set_int_value(1);
      });
  lynx::base::tracing::TraceBackend::TraceEventWithTimestamp(
      LYNX_TRACE_CATEGORY_FPS, "DrawFrame", endTime, TRACE_EVENT_PHASE_BEGIN,
      [endTime](TraceEvent* event) {
        auto* legacy_event = event->set_legacy_event();
        legacy_event->set_phase('b');
        legacy_event->set_unscoped_id(1);
        auto* dataDebug = event->add_debug_annotations();
        dataDebug->set_name("presentationTimestamp");
        dataDebug->set_int_value(endTime / 1000);
        auto* idDebug = event->add_debug_annotations();
        idDebug->set_name("layerTreeId");
        idDebug->set_int_value(1);
      });
  lynx::base::tracing::TraceBackend::TraceEventWithTimestamp(
      LYNX_TRACE_CATEGORY_FPS, "DrawFrame", endTime, TRACE_EVENT_PHASE_END,
      [](TraceEvent* event) {
        auto* legacy_event = event->set_legacy_event();
        legacy_event->set_phase('e');
        legacy_event->set_unscoped_id(1);
      });
}

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING
