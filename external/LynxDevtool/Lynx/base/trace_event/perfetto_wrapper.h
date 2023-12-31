// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TRACE_EVENT_PERFETTO_WRAPPER_H_
#define LYNX_BASE_TRACE_EVENT_PERFETTO_WRAPPER_H_
#if LYNX_ENABLE_TRACING

#include "tasm/lynx_trace_event.h"

// export perfetto symbols
#define PERFETTO_COMPONENT_EXPORT __attribute__((visibility("default")))
#include "third_party/perfetto/perfetto.h"

PERFETTO_DEFINE_CATEGORIES(
    lynx::perfetto::Category(LYNX_TRACE_CATEGORY)
        .SetDescription("Events in lynx template assembler"),
    lynx::perfetto::Category(LYNX_TRACE_CATEGORY_ATRACE)
        .SetDescription("Events from the system trace API"),
    lynx::perfetto::Category(LYNX_TRACE_CATEGORY_VITALS)
        .SetDescription("Lynx vitals event"),
    lynx::perfetto::Category(LYNX_TRACE_CATEGORY_JSB)
        .SetDescription("Events from Lynx JSB API"),
    lynx::perfetto::Category(LYNX_TRACE_CATEGORY_JAVASCRIPT)
        .SetDescription("Events from Lynx JS API"),
    lynx::perfetto::Category(LYNX_TRACE_CATEGORY_SCREENSHOTS)
        .SetDescription("Screenshot trace event"),
    lynx::perfetto::Category(LYNX_TRACE_CATEGORY_FPS)
        .SetDescription("FPS trace event"),
    lynx::perfetto::Category(LYNX_TRACE_CATEGORY_DEVTOOL_TIMELINE)
        .SetDescription("Devtool timeline trace event"),
    lynx::perfetto::Category("__metadata")
        .SetDescription("Metadata section in trace file"));

#endif  // LYNX_ENABLE_TRACING
#endif  // LYNX_BASE_TRACE_EVENT_PERFETTO_WRAPPER_H_
