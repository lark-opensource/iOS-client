// this file do not need to copy to LYNX!
#ifndef DEBUGGER_STRUCT_H
#define DEBUGGER_STRUCT_H

#include <stdint.h>

#include <memory>

#include "list.h"
#include "quickjs.h"
#define DEBUGGER_MAX_SCOPE_LEVEL 23

#define QJSDebuggerStringPool(V)                                \
  V(stack, "stack")                                             \
  V(string, "string")                                           \
  V(message, "message")                                         \
  V(undefined, "undefined")                                     \
  V(capital_undefined, "Undefined")                             \
  V(object, "object")                                           \
  V(lepus_js, "lepus.js")                                       \
  V(lepus, "lepus")                                             \
  V(arraybuffer, "arraybuffer")                                 \
  V(function, "function")                                       \
  V(exception, "exception")                                     \
  V(null, "null")                                               \
  V(capital_null, "Null")                                       \
  V(number, "number")                                           \
  V(bigint, "bigint")                                           \
  V(boolean, "boolean")                                         \
  V(size, "size")                                               \
  V(proto, "__proto__")                                         \
  V(capital_object, "Object")                                   \
  V(capital_promise, "Promise")                                 \
  V(capital_symbol, "Symbol")                                   \
  V(symbol, "symbol")                                           \
  V(capital_arraybuffer, "ArrayBuffer")                         \
  V(capital_uncaught, "Uncaught")                               \
  V(capital_javascript, "JavaScript")                           \
  V(minus_one, "-1")                                            \
  V(debugger_context, "debugger context")                       \
  V(anonymous, "<anonymous>")                                   \
  V(uncaught, "uncaught")                                       \
  V(unknown, "unknown")                                         \
  V(empty_string, "")                                           \
  V(function_location, "[[FunctionLocation]]")                  \
  V(generator_function_location, "[[GeneratorLocation]]")       \
  V(is_generator, "[[IsGenerator]]")                            \
  V(internal_location, "internal#location")                     \
  V(entries, "[[Entries]]")                                     \
  V(capital_weak_ref, "WeakRef")                                \
  V(capital_fr, "FinalizationRegistry")                         \
  V(capital_array_iterator, "ArrayIterator")                    \
  V(capital_string_iterator, "StringIterator")                  \
  V(capital_set_iterator, "SetIterator")                        \
  V(capital_map_iterator, "MapIterator")                        \
  V(capital_regexp_string_iterator, "RegExpStringIterator")     \
  V(capital_async_function, "AsyncFunction")                    \
  V(capital_async_generator, "AsyncGenerator")                  \
  V(capital_async_generator_function, "AsyncGeneratorFunction") \
  V(capital_async_function_resolve, "AsyncFunctionResolve")     \
  V(capital_async_function_reject, "AsyncFunctionReject")       \
  V(capital_async_from_sync_iterator, "AsyncFromSyncIterator")  \
  V(capital_promise_resolve_func, "PromiseResolveFunction")     \
  V(capital_promise_reject_func, "PromiseRejectFunction")       \
  V(capital_array, "Array")                                     \
  V(array, "array")                                             \
  V(capital_proxy, "Proxy")                                     \
  V(proxy, "proxy")                                             \
  V(capital_regexp, "Regexp")                                   \
  V(regexp, "regexp")                                           \
  V(capital_dataview, "DataView")                               \
  V(dataview, "dataview")                                       \
  V(error, "error")                                             \
  V(typedarray, "typedarray")                                   \
  V(capital_date, "Date")                                       \
  V(date, "date")                                               \
  V(capital_function, "Function")                               \
  V(capital_generator_function, "GeneratorFunction")            \
  V(capital_generator, "Generator")                             \
  V(capital_weak_set, "WeakSet")                                \
  V(weak_set, "weakset")                                        \
  V(capital_weak_map, "WeakMap")                                \
  V(weak_map, "weakmap")                                        \
  V(capital_set, "Set")                                         \
  V(set, "set")                                                 \
  V(capital_map, "Map")                                         \
  V(map, "map")                                                 \
  V(generator, "generator")                                     \
  V(promise, "promise")                                         \
  V(generator_state, "[[GeneratorState]]")                      \
  V(generator_function, "[[GeneratorFunction]]")

namespace VMSDK {
namespace CpuProfiler {
class CpuProfiler;
}
}  // namespace VMSDK

typedef enum DebuggerFuncLevelState {
  NO_DEBUGGER,
  DEBUGGER_TOP_LEVEL_FUNCTION,
  DEBUGGER_LOW_LEVEL_FUNCTION,
} DebuggerFuncLevelState;

// location of the pc, including line and column number
typedef struct LEPUSDebuggerLocation {
  // script id of this position
  int32_t script_id;
  int32_t line;
  int64_t column;
} LEPUSDebuggerLocation;

typedef struct LEPUSDebuggerConsole {
  LEPUSValue messages;
  int32_t length;
} LEPUSDebuggerConsole;

struct LEPUSScriptSource {
  struct list_head link; /* ctx->script_list */
  // script url
  char *url;
  // script source
  char *source;
  // script hash
  char *hash;
  // script id
  int32_t id;
  // script length
  int32_t length;
  int32_t end_line;
  // source map url
  char *source_map_url;
  bool is_debug_file;
};

// data structure of debugger breakpoint
struct LEPUSBreakpoint {
  // url:line:column
  LEPUSValue breakpoint_id;
  // script url
  char *script_url;
  // script id
  int32_t script_id;
  // line number
  int32_t line;
  // column number
  int64_t column;
  // condition
  LEPUSValue condition;
  // pc hit this breakpoint
  const uint8_t *pc;
  // specific location
  uint8_t specific_location;
  bool is_adjust;
};

// data structure used by get properties related protocols
typedef struct DebuggerSuspendedState {
  LEPUSValue get_properties_array;
  uint32_t get_properties_array_len;
} DebuggerSuspendedState;

typedef struct DebuggerLiteralPool {
#define DebuggerDefineStringPool(name, str) LEPUSValue name;
  QJSDebuggerStringPool(DebuggerDefineStringPool)
#undef DebuggerDefineStringPool
} DebuggerLiteralPool;

typedef struct DebuggerFixeShapeObj {
  LEPUSValue response;
  LEPUSValue notification;
  LEPUSValue breakpoint;
  LEPUSValue bp_location;
  LEPUSValue result;
  LEPUSValue preview_prop;
} DebuggerFixeShapeObj;

// data structure of debugger info
struct LEPUSDebuggerInfo {
  LEPUSContext *ctx;  // context
  // start line, start column, end line, end column, hash, script size
  uint8_t exception_breakpoint;  // if need to break when there is an exception,
  // paused if the value is 1
  uint8_t exception_breakpoint_before;   // save for state before, use for
                                         // setskipallpauses
  LEPUSDebuggerLocation *step_location;  // location when press step button
  struct queue *message_queue;           // protocol messages queue
  int32_t breakpoints_num;               // breakpoints number
  uint8_t breakpoints_is_active;         // if breakpoints are active
  uint8_t breakpoints_is_active_before;  // save for state before, use for
                                         // setskipallpauses
  uint32_t step_depth;                   // stack depth when press step button
  bool step_statement;
  uint8_t next_statement_count;

  struct DebuggerSuspendedState
      pause_state;  // need update when restart runframe
  struct DebuggerSuspendedState running_state;
  uint8_t step_over_valid;  // if step over is valid
  uint8_t step_type;  // step_type mode, including step in, step over, step out
  // and continue
  char *source_code;
  int32_t end_line_num;
  int32_t is_debugger_enabled;
  int32_t is_runtime_enabled;
  LEPUSDebuggerConsole console;  // use for console.xxx
  LEPUSBreakpoint *bps;
  int32_t breakpoints_capacity;
  int32_t next_breakpoint_id;
  void *opaque;
  int32_t max_async_call_stack_depth;
  int32_t script_num;
  uint8_t special_breakpoints;  // for debugger.continueToLocation protocol

  int32_t is_profiling_enabled;  // if profiling is enabled, true after
                                 // Profiler.enable
  bool cpu_profiling_started;    // if profiling is started, true after
                                 // Profiler.start
  uint32_t profiler_interval;    // sampling interval, default val: 100
  std::shared_ptr<VMSDK::CpuProfiler::CpuProfiler> cpu_profiler;
  struct DebuggerLiteralPool *literal_pool;
  struct DebuggerFixeShapeObj *debugger_obj;
};

#endif