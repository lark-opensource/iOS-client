#ifndef DEVTOOL_QUICKJS_HEAPPROFILER_HEAPPROFILER_H
#define DEVTOOL_QUICKJS_HEAPPROFILER_HEAPPROFILER_H

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

#include <memory>
#include <string>
#include <unordered_map>

#include "devtool/quickjs/protocols.h"

void HandleHeapProfilerProtocols(DebuggerParams*);
#endif