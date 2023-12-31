#ifndef QUICKJS_DEBUGGER_TAKE_SNAPSHOT_H_
#define QUICKJS_DEBUGGER_TAKE_SNAPSHOT_H_

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"

#ifdef __cplusplus
}
#endif

#include <memory>
#include <unordered_map>

#include "quickjs/heapprofiler/include/heapprofiler.h"

void lepus_profile_take_heap_snapshot(LEPUSContext* ctx);
#endif
