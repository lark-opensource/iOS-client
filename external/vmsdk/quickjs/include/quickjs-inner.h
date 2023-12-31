/*
 * QuickJS Javascript Engine
 *
 * Copyright (c) 2017-2019 Fabrice Bellard
 * Copyright (c) 2017-2019 Charlie Gordon
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef QUICKJS_INNER_H
#define QUICKJS_INNER_H

#include "base_export.h"
#ifdef __cplusplus
extern "C" {
#endif

#include "cutils.h"
#include "list.h"
#include "quickjs.h"

#ifdef CONFIG_BIGNUM
#include "libbf.h"
#endif

#ifdef ENABLE_MONITOR
#include "monitor/common/vmsdk_monitor.h"
#endif
#ifdef __cplusplus
}
#endif

#if defined(CONFIG_BIGNUM) and defined(ENABLE_LEPUSNG)
#error bignum and lepusng are now conflict!
#endif
#if defined(QJS_UNITTEST) || defined(__WASI_SDK__)
#define QJS_STATIC
#else
#define QJS_STATIC static
#endif

#define OPTIMIZE 1
#define SHORT_OPCODES 1
#if defined(ENABLE_PRIMJS_SNAPSHOT) && !defined(__aarch64__)
#undef ENABLE_PRIMJS_SNAPSHOT
#undef ENABLE_PRIMJS_IC
#endif

#define __exception __attribute__((warn_unused_result))

enum LEPUS_CLASS_ID {
  /* classid tag        */ /* union usage   | properties */
  LEPUS_CLASS_OBJECT = 1,  /* must be first */
  LEPUS_CLASS_ARRAY,       /* u.array       | length */
  LEPUS_CLASS_ERROR,
  LEPUS_CLASS_NUMBER,           /* u.object_data */
  LEPUS_CLASS_STRING,           /* u.object_data */
  LEPUS_CLASS_BOOLEAN,          /* u.object_data */
  LEPUS_CLASS_SYMBOL,           /* u.object_data */
  LEPUS_CLASS_ARGUMENTS,        /* u.array       | length */
  LEPUS_CLASS_MAPPED_ARGUMENTS, /*               | length */
  LEPUS_CLASS_DATE,             /* u.object_data */
  LEPUS_CLASS_MODULE_NS,
  LEPUS_CLASS_C_FUNCTION,          /* u.cfunc */
  LEPUS_CLASS_BYTECODE_FUNCTION,   /* u.func */
  LEPUS_CLASS_BOUND_FUNCTION,      /* u.bound_function */
  LEPUS_CLASS_C_FUNCTION_DATA,     /* u.c_function_data_record */
  LEPUS_CLASS_GENERATOR_FUNCTION,  /* u.func */
  LEPUS_CLASS_FOR_IN_ITERATOR,     /* u.for_in_iterator */
  LEPUS_CLASS_REGEXP,              /* u.regexp */
  LEPUS_CLASS_ARRAY_BUFFER,        /* u.array_buffer */
  LEPUS_CLASS_SHARED_ARRAY_BUFFER, /* u.array_buffer */
  LEPUS_CLASS_UINT8C_ARRAY,        /* u.array (typed_array) */
  LEPUS_CLASS_INT8_ARRAY,          /* u.array (typed_array) */
  LEPUS_CLASS_UINT8_ARRAY,         /* u.array (typed_array) */
  LEPUS_CLASS_INT16_ARRAY,         /* u.array (typed_array) */
  LEPUS_CLASS_UINT16_ARRAY,        /* u.array (typed_array) */
  LEPUS_CLASS_INT32_ARRAY,         /* u.array (typed_array) */
  LEPUS_CLASS_UINT32_ARRAY,        /* u.array (typed_array) */
#ifdef CONFIG_BIGNUM
  LEPUS_CLASS_BIG_INT64_ARRAY,  /* u.array (typed_array) */
  LEPUS_CLASS_BIG_UINT64_ARRAY, /* u.array (typed_array) */
#endif
  LEPUS_CLASS_FLOAT32_ARRAY, /* u.array (typed_array) */
  LEPUS_CLASS_FLOAT64_ARRAY, /* u.array (typed_array) */
  LEPUS_CLASS_DATAVIEW,      /* u.typed_array */
#ifdef CONFIG_BIGNUM
  LEPUS_CLASS_BIG_INT,   /* u.object_data */
  LEPUS_CLASS_BIG_FLOAT, /* u.object_data */
  LEPUS_CLASS_FLOAT_ENV, /* u.float_env */
#endif
  LEPUS_CLASS_MAP,                      /* u.map_state */
  LEPUS_CLASS_SET,                      /* u.map_state */
  LEPUS_CLASS_WEAKMAP,                  /* u.map_state */
  LEPUS_CLASS_WEAKSET,                  /* u.map_state */
  LEPUS_CLASS_MAP_ITERATOR,             /* u.map_iterator_data */
  LEPUS_CLASS_SET_ITERATOR,             /* u.map_iterator_data */
  LEPUS_CLASS_ARRAY_ITERATOR,           /* u.array_iterator_data */
  LEPUS_CLASS_STRING_ITERATOR,          /* u.array_iterator_data */
  LEPUS_CLASS_REGEXP_STRING_ITERATOR,   /* u.regexp_string_iterator_data */
  LEPUS_CLASS_GENERATOR,                /* u.generator_data */
  LEPUS_CLASS_PROXY,                    /* u.proxy_data */
  LEPUS_CLASS_PROMISE,                  /* u.promise_data */
  LEPUS_CLASS_PROMISE_RESOLVE_FUNCTION, /* u.promise_function_data */
  LEPUS_CLASS_PROMISE_REJECT_FUNCTION,  /* u.promise_function_data */
  LEPUS_CLASS_ASYNC_FUNCTION,           /* u.func */
  LEPUS_CLASS_ASYNC_FUNCTION_RESOLVE,   /* u.async_function_data */
  LEPUS_CLASS_ASYNC_FUNCTION_REJECT,    /* u.async_function_data */
  LEPUS_CLASS_ASYNC_FROM_SYNC_ITERATOR, /* u.async_from_sync_iterator_data */
  LEPUS_CLASS_ASYNC_GENERATOR_FUNCTION, /* u.func */
  LEPUS_CLASS_ASYNC_GENERATOR,          /* u.async_generator_data */
  LEPUS_CLASS_WeakRef,
  LEPUS_CLASS_FinalizationRegistry,

  LEPUS_CLASS_INIT_COUNT, /* last entry for predefined classes */
};

typedef enum LEPUSErrorEnum {
  LEPUS_EVAL_ERROR,
  LEPUS_RANGE_ERROR,
  LEPUS_REFERENCE_ERROR,
  LEPUS_SYNTAX_ERROR,
  LEPUS_TYPE_ERROR,
  LEPUS_URI_ERROR,
  LEPUS_INTERNAL_ERROR,
  LEPUS_AGGREGATE_ERROR,

  LEPUS_NATIVE_ERROR_COUNT, /* number of different NativeError objects */
} LEPUSErrorEnum;

#define BUILD_ASYNC_STACK

typedef struct LEPUSShape LEPUSShape;
typedef struct LEPUSString LEPUSString;
typedef struct LEPUSString LEPUSAtomStruct;

typedef struct LEPUSLepusType {
  int32_t array_typeid_;
  int32_t table_typeid_;
  int32_t refcounted_typeid_;
  LEPUSClassID refcounted_cid_;
} LEPUSLepusType;

typedef struct VMSDKCallbacks {
  void (*print_by_alog)(char *msg);
} VMSDKCallbacks;

#ifdef ENABLE_QUICKJS_DEBUGGER
typedef struct QJSDebuggerCallbacks2 {
  // callbacks for quickjs debugger
  void (*run_message_loop_on_pause)(LEPUSContext *ctx);
  void (*quit_message_loop_on_pause)(LEPUSContext *ctx);
  void (*get_messages)(LEPUSContext *ctx);
  void (*send_response)(LEPUSContext *ctx, int32_t message_id,
                        const char *message);
  void (*send_notification)(LEPUSContext *ctx, const char *message);
  void (*free_messages)(LEPUSContext *ctx, char **messages, int32_t size);

  void (*inspector_check)(LEPUSContext *ctx);
  void (*debugger_exception)(LEPUSContext *ctx);
  void (*console_message)(LEPUSContext *ctx, int tag, LEPUSValueConst *argv,
                          int argc);
  void (*script_parsed_ntfy)(LEPUSContext *ctx, LEPUSScriptSource *source);
  void (*console_api_called_ntfy)(LEPUSContext *ctx, LEPUSValue *msg);
  void (*script_fail_parse_ntfy)(LEPUSContext *ctx, LEPUSScriptSource *source);
  void (*debugger_paused)(LEPUSContext *ctx, const uint8_t *cur_pc);
  uint8_t (*is_devtool_on)(LEPUSRuntime *rt);
  void (*send_response_with_view_id)(LEPUSContext *ctx, int32_t message_id,
                                     const char *message, int32_t view_id);
  void (*send_ntfy_with_view_id)(LEPUSContext *ctx, const char *message,
                                 int32_t view_id);
  void (*script_parsed_ntfy_with_view_id)(LEPUSContext *ctx,
                                          LEPUSScriptSource *source,
                                          int32_t view_id);
  void (*script_fail_parse_ntfy_with_view_id)(LEPUSContext *ctx,
                                              LEPUSScriptSource *source,
                                              int32_t view_id);
  void (*set_session_enable_state)(LEPUSContext *ctx, int32_t view_id,
                                   int32_t protocol_type);
  void (*get_session_state)(LEPUSContext *ctx, int32_t view_id,
                            bool *is_already_enabled, bool *is_paused);
  void (*console_api_called_ntfy_with_rid)(LEPUSContext *ctx, LEPUSValue *msg);
  void (*get_session_enable_state)(LEPUSContext *ctx, int32_t view_id,
                                   int32_t protocol_type, bool *ret);
  void (*get_console_stack_trace)(LEPUSContext *ctx, LEPUSValue *ret);
} QJSDebuggerCallbacks2;
#endif

struct LEPUSRuntime {
  LEPUSMallocFunctions mf;
  LEPUSMallocState malloc_state;
  const char *rt_info;

  int atom_hash_size; /* power of two */
  int atom_count;
  int atom_size;
  int atom_count_resize; /* resize hash table at this count */
  uint32_t *atom_hash;
  LEPUSAtomStruct **atom_array;
  int atom_free_index; /* 0 = none */

  int class_count; /* size of class_array */
  LEPUSClass *class_array;

  struct list_head context_list; /* list of LEPUSContext.link */
  /* list of LEPUSGCObjectHeader.link. List of allocated GC objects (used
       by the garbage collector) */
  /* list of allocated objects (used by the garbage collector) */
  struct list_head obj_list; /* list of LEPUSObject.link */
  // <ByteDance begin>
  struct list_head gc_bytecode_list;
  struct list_head gc_obj_list;
  // <ByteDance end>
  struct list_head tmp_obj_list;  /* used during gc */
  struct list_head free_obj_list; /* used during gc */
  struct list_head *el_next;      /* used during gc */
  BOOL in_gc_sweep : 8;
  int c_stack_depth;
  uint64_t malloc_gc_threshold;
#ifdef DUMP_LEAKS
  struct list_head string_list; /* list of LEPUSString.link */
#endif
  /* stack limitation */
  const uint8_t *stack_top;
  size_t stack_size; /* in bytes */

  LEPUSValue current_exception;
  /* true if a backtrace needs to be added to the current exception
     (the backtrace generation cannot be done immediately in a bytecode
     function) */
  BOOL exception_needs_backtrace;
  /* true if inside an out of memory error, to avoid recursing */
  BOOL in_out_of_memory : 8;

  struct LEPUSStackFrame *current_stack_frame;

  LEPUSInterruptHandler *interrupt_handler;
  void *interrupt_opaque;

  struct list_head job_list; /* list of LEPUSJobEntry.link */

  LEPUSModuleNormalizeFunc *module_normalize_func;
  LEPUSModuleLoaderFunc *module_loader_func;
  void *module_loader_opaque;

  BOOL can_block : 8; /* TRUE if Atomics.wait can block */

  /* Shape hash table */
  int shape_hash_bits;
  int shape_hash_size;
  int shape_hash_count; /* number of hashed shapes */
  LEPUSShape **shape_hash;
  VMSDKCallbacks vmsdk_callbacks_;

  struct list_head
      unhandled_rejections;  // record the first unhandled rejection error

#ifdef BUILD_ASYNC_STACK
  LEPUSValue *current_micro_task;
#endif

#ifdef ENABLE_LEPUSNG
  LEPUSLepusRefCallbacks lepus_callbacks_;  // ByteDance
  LEPUSLepusType lepus_type_;
#endif

#ifdef ENABLE_QUICKJS_DEBUGGER
  QJSDebuggerCallbacks2 debugger_callbacks_;
  int32_t next_script_id;  // next script id that can be used
#endif
#ifdef CONFIG_BIGNUM
  bf_context_t bf_ctx;
#endif
  // <ByteDance begin>
  bool use_dlmalloc;
#ifdef ENABLE_PRIMJS_SNAPSHOT
  bool use_primjs;
#endif
  // <ByteDance end>
  void *user_opaque;
};

static const char *const native_error_name[LEPUS_NATIVE_ERROR_COUNT] = {
    "EvalError", "RangeError", "ReferenceError", "SyntaxError",
    "TypeError", "URIError",   "InternalError",  "AggregateError"};

/* Set/Map/WeakSet/WeakMap */

typedef struct LEPUSMapState {
  BOOL is_weak;             /* TRUE if WeakSet/WeakMap */
  struct list_head records; /* list of LEPUSMapRecord.link */
  uint32_t record_count;
  struct list_head *hash_table;
  uint32_t hash_size;              /* must be a power of two */
  uint32_t record_count_threshold; /* count at which a hash table
                                      resize is needed */
} LEPUSMapState;

typedef struct LEPUSUnhandledRejectionEntry {
  struct list_head link;
  LEPUSValue error;
  LEPUSValue promise;
} LEPUSUnhandledRejectionEntry;

typedef struct LEPUSFinalizationRegistryEntry {
  struct list_head link;
  LEPUSObject *obj;
} LEPUSFinalizationRegistryEntry;

struct LEPUSClass {
  uint32_t class_id; /* 0 means free entry */
  LEPUSAtom class_name;
  LEPUSClassFinalizer *finalizer;
  LEPUSClassGCMark *gc_mark;
  LEPUSClassCall *call;
  /* pointers for exotic behavior, can be NULL if none are present */
  const LEPUSClassExoticMethods *exotic;
};

#define LEPUS_MODE_STRICT (1 << 0)
#define LEPUS_MODE_STRIP (1 << 1)
#define LEPUS_MODE_BIGINT (1 << 2)
#define LEPUS_MODE_MATH (1 << 3)

typedef struct LEPUSStackFrame {
  struct LEPUSStackFrame *prev_frame; /* NULL if first stack frame */
  LEPUSValue
      cur_func; /* current function, LEPUS_UNDEFINED if the frame is detached */
  LEPUSValue *arg_buf;           /* arguments */
  LEPUSValue *var_buf;           /* variables */
  struct list_head var_ref_list; /* list of LEPUSVarRef.link */
  const uint8_t *cur_pc;         /* only used in bytecode functions : PC of the
                              instruction after the call */
  int arg_count;
  int lepus_mode; /* for C functions: 0 */
  /* only used in generators. Current stack pointer value. NULL if
     the function is running. */
  LEPUSValue *cur_sp;
#ifdef ENABLE_PRIMJS_PROFILER
  void *cur_fp;  // store the LEPUS_CallInternal fp
#endif
#ifdef ENABLE_QUICKJS_DEBUGGER
  // for debugger: this_obj of the stack frame
  LEPUSValue pthis;
#endif
} LEPUSStackFrame;

typedef struct LEPUSGCHeader {
  uint8_t mark;
} LEPUSGCHeader;

typedef struct LEPUSVarRef {
  LEPUSRefCountHeader header; /* must come first, 32-bit */
  LEPUSGCHeader gc_header;    /* must come after LEPUSRefCountHeader, 8-bit */
  uint8_t is_arg : 1;
  int var_idx;           /* index of the corresponding function variable on
                            the stack */
  struct list_head link; /* prev = NULL if no longer on the stack */
  LEPUSValue *pvalue;    /* pointer to the value, either on the stack or
                         to 'value' */
  LEPUSValue value;      /* used when the variable is no longer on the stack */
} LEPUSVarRef;

#ifdef CONFIG_BIGNUM
typedef struct LEPUSFloatEnv {
  limb_t prec;
  bf_flags_t flags;
  unsigned int status;
} LEPUSFloatEnv;

typedef struct LEPUSBigFloat {
  LEPUSRefCountHeader header; /* must come first, 32-bit */
  bf_t num;
} LEPUSBigFloat;

/* the same structure is used for big integers and big floats. Big
   integers are never infinite or NaNs */
#else
#ifdef ENABLE_LEPUSNG
// <ByteDance begin>
typedef struct LEPUSBigFloat {
  LEPUSRefCountHeader header; /* must come first, 32-bit */
  uint64_t num;
} LEPUSBigFloat;

// <ByteDance end>
#endif
#endif

/* must be large enough to have a negligible runtime cost and small
   enough to call the interrupt callback often. */
#define LEPUS_INTERRUPT_COUNTER_INIT 10000
// <Bytedance begin>
#define DEFAULT_VIRTUAL_STACK_SIZE 1024 * 1024 * 4
#define FALLBACK_VIRTUAL_STACK_SIZE 1024 * 1024 * 1
// <Bytedance end>

// <ByteDance begin>
#ifdef ENABLE_QUICKJS_DEBUGGER
#include "debugger_struct.h"
#endif

#ifdef ENABLE_QUICKJS_SECURITY_MODE

typedef uint8_t (*encode_opcode_type)(LEPUSContext *ctx, uint8_t);
typedef uint8_t (*decode_opcode_type)(LEPUSContext *ctx, uint8_t);
typedef struct LEPUSOpTransformCallBack {
  encode_opcode_type encode_opcode;
  decode_opcode_type decode_opcode;
  int32_t value;
} LEPUSOpTransformCallBack;

#endif

// <Bytedance end>

// <primjs begin>
typedef unsigned char u_char;
typedef u_char *address;
// <primjs end>

typedef enum OPCodeFormat {
#define FMT(f) OP_FMT_##f,
#define DEF(id, size, n_pop, n_push, f)
#include "quickjs-opcode.h"
#undef DEF
#undef FMT
} OPCodeFormat;

typedef enum OPCodeEnum {
#define FMT(f)
#define DEF(id, size, n_pop, n_push, f) OP_##id,
#define def(id, size, n_pop, n_push, f)
#include "quickjs-opcode.h"
#undef def
#undef DEF
#undef FMT
  OP_COUNT, /* excluding temporary opcodes */
  /* temporary opcodes : overlap with the short opcodes */
  OP_TEMP_START = OP_nop + 1,
  OP___dummy = OP_TEMP_START - 1,
#define FMT(f)
#define DEF(id, size, n_pop, n_push, f)
#define def(id, size, n_pop, n_push, f) OP_##id,
#include "quickjs-opcode.h"
#undef def
#undef DEF
#undef FMT
  OP_TEMP_END,
} OPCodeEnum;

struct LEPUSContext {
#ifdef ENABLE_PRIMJS_SNAPSHOT
  address (*dispatch_table)[OP_COUNT];
#endif
// <primjs end>
#ifndef DLMALLOC_WINDOWS
  mstate dlmalloc_state;
#endif
  LEPUSRuntime *rt;
  struct list_head link;

  uint16_t binary_object_count;
  int binary_object_size;

  LEPUSShape *array_shape; /* initial shape for Array objects */

  LEPUSValue *class_proto;
  LEPUSValue function_proto;
  LEPUSValue function_ctor;
  LEPUSValue regexp_ctor;
  LEPUSValue promise_ctor;
  LEPUSValue native_error_proto[LEPUS_NATIVE_ERROR_COUNT];
  LEPUSValue iterator_proto;
  LEPUSValue async_iterator_proto;
  LEPUSValue array_proto_values;
  LEPUSValue throw_type_error;
  LEPUSValue eval_obj;

  LEPUSValue global_obj;     /* global object */
  LEPUSValue global_var_obj; /* contains the global let/const definitions */

  uint64_t random_state;
#ifdef CONFIG_BIGNUM
  bf_context_t *bf_ctx; /* points to rt->bf_ctx, shared by all contexts */
  LEPUSFloatEnv fp_env; /* global FP environment */
#endif
  /* when the counter reaches zero, LEPUSRutime.interrupt_handler is called */
  int interrupt_counter;
  BOOL is_error_property_enabled;

  struct list_head loaded_modules; /* list of LEPUSModuleDef.link */

  /* if NULL, RegExp compilation is not supported */
  LEPUSValue (*compile_regexp)(LEPUSContext *ctx, LEPUSValueConst pattern,
                               LEPUSValueConst flags);
  /* if NULL, eval is not supported */
  LEPUSValue (*eval_internal)(LEPUSContext *ctx, LEPUSValueConst this_obj,
                              const char *input, size_t input_len,
                              const char *filename, int flags, int scope_idx,
                              bool debugger_eval, LEPUSStackFrame *sf);

  void *user_opaque;
  // <ByteDance begin>
  int64_t napi_env;
  BOOL no_lepus_strict_mode;
#if defined(__APPLE__) && !defined(GEN_ANDROID_EMBEDDED)
  uint32_t stack_pos;
  uint8_t *stack;
#endif
#ifdef ENABLE_QUICKJS_DEBUGGER
  LEPUSDebuggerInfo *debugger_info;    // structure for quickjs debugger
  const uint8_t *debugger_current_pc;  // current pc
  struct list_head script_list;        // for debugger: all the debugger scripts
  struct list_head
      bytecode_list;  // for debugger: all the debugger function bytecode
#endif
  uint32_t next_function_id;  // for lepusng debugger encode.
  struct list_head finalization_registries;
  uint8_t
      debuginfo_outside;  // for lepusng debugger encode to avoid break change.
  uint8_t is_profiler_ctx;  // for cpu profiler
  const char *lynx_target_sdk_version;
  BOOL debugger_mode;
  BOOL debugger_parse_script;  // for shared context debugger
  // <bytedance end>

#ifdef ENABLE_QUICKJS_SECURITY_MODE
  LEPUSOpTransformCallBack op_transform_callback;
  uint32_t op_transform_value;
  uint8_t enable_security_feature;
#endif
};

typedef union LEPUSFloat64Union {
  double d;
  uint64_t u64;
  uint32_t u32[2];
} LEPUSFloat64Union;

enum {
  LEPUS_ATOM_TYPE_STRING = 1,
  LEPUS_ATOM_TYPE_GLOBAL_SYMBOL,
  LEPUS_ATOM_TYPE_SYMBOL,
  LEPUS_ATOM_TYPE_PRIVATE,
};

enum {
  LEPUS_ATOM_HASH_SYMBOL,
  LEPUS_ATOM_HASH_PRIVATE,
};

typedef enum {
  LEPUS_ATOM_KIND_STRING,
  LEPUS_ATOM_KIND_SYMBOL,
  LEPUS_ATOM_KIND_PRIVATE,
} LEPUSAtomKindEnum;

#define LEPUS_ATOM_HASH_MASK ((1 << 30) - 1)

typedef struct LEPUSClosureVar {
  uint8_t is_local : 1;
  uint8_t is_arg : 1;
  uint8_t is_const : 1;
  uint8_t is_lexical : 1;
  uint8_t var_kind : 4; /* see LEPUSVarKindEnum */
  /* 9 bits available */
  uint16_t var_idx; /* is_local = TRUE: index to a normal variable of the
                  parent function. otherwise: index to a closure
                  variable of the parent function */
  LEPUSAtom var_name;
} LEPUSClosureVar;

#define ARG_SCOPE_INDEX 1
#define ARG_SCOPE_END (-2)
#define DEBUG_SCOPE_INDEX (-3)

typedef struct LEPUSVarScope {
  int parent; /* index into fd->scopes of the enclosing scope */
  int first;  /* index into fd->vars of the last variable in this scope */
} LEPUSVarScope;

typedef enum {
  /* XXX: add more variable kinds here instead of using bit fields */
  LEPUS_VAR_NORMAL,
  LEPUS_VAR_FUNCTION_DECL,     /* lexical var with function declaration */
  LEPUS_VAR_NEW_FUNCTION_DECL, /* lexical var with async/generator function
                                  declaration */
  LEPUS_VAR_CATCH,
  LEPUS_VAR_FUNCTION_NAME,
  LEPUS_VAR_PRIVATE_FIELD,
  LEPUS_VAR_PRIVATE_METHOD,
  LEPUS_VAR_PRIVATE_GETTER,
  LEPUS_VAR_PRIVATE_SETTER, /* must come after LEPUS_VAR_PRIVATE_GETTER */
  LEPUS_VAR_PRIVATE_GETTER_SETTER, /* must come after LEPUS_VAR_PRIVATE_SETTER
                                    */
} LEPUSVarKindEnum;

typedef struct LEPUSVarDef {
  LEPUSAtom var_name;
  int scope_level; /* index into fd->scopes of this variable lexical scope */
  int scope_next;  /* index into fd->vars of the next variable in the
                    * same or enclosing lexical scope */
  uint8_t is_const : 1;
  uint8_t is_lexical : 1;
  uint8_t is_captured : 1;
  uint8_t var_kind : 4;   /* see LEPUSVarKindEnum */
  int func_pool_idx : 24; /* only used during compilation */
} LEPUSVarDef;

/* for the encoding of the pc2line table */
#define PC2LINE_BASE (-1)
#define PC2LINE_RANGE 5
#define PC2LINE_OP_FIRST 1
#define PC2LINE_DIFF_PC_MAX ((255 - PC2LINE_OP_FIRST) / PC2LINE_RANGE)

// <ByteDance begin>
#define LINE_NUMBER_BITS_COUNT 24
#define COLUMN_NUMBER_BITS_COUNT 40
// for compatibility
#define OLD_LINE_NUMBER_BITS_COUNT 12
// use 2 bits for type.
#define LINE_COLUMN_TYPE_SHIFT 62
// <ByteDance end>

typedef enum LEPUSFunctionKindEnum {
  LEPUS_FUNC_NORMAL = 0,
  LEPUS_FUNC_GENERATOR = (1 << 0),
  LEPUS_FUNC_ASYNC = (1 << 1),
  LEPUS_FUNC_ASYNC_GENERATOR = (LEPUS_FUNC_GENERATOR | LEPUS_FUNC_ASYNC),
} LEPUSFunctionKindEnum;

// <primjs begin>
typedef struct TypeGetFeedBack {
  intptr_t offset;
  LEPUSShape *shape;
  LEPUSShape *proto_shape;
  uint8_t miss;
} TypeGetFeedBack;

typedef struct TypeSetFeedBack {
  intptr_t offset;
  LEPUSShape *old_shape;
  LEPUSShape *new_shape;
  uint8_t length;
} TypeSetFeedBack;

#define DEFAULT_FEEDBACK_SIZE 4

typedef TypeGetFeedBack TypeGetFeedBackVec[DEFAULT_FEEDBACK_SIZE];
typedef TypeSetFeedBack TypeSetFeedBackVec[DEFAULT_FEEDBACK_SIZE];

enum class EntryMode { INTERPRETER, BASELINE };

#define JIT_THRESHOLD 6

// <primjs end>

typedef struct LEPUSFunctionBytecode {
  LEPUSRefCountHeader header; /* must come first, 32-bit */
  LEPUSGCHeader gc_header;    /* must come after header, 8-bit */
  uint8_t lepus_mode;
  uint8_t has_prototype : 1; /* true if a prototype field is necessary */
  uint8_t has_simple_parameter_list : 1;
  uint8_t is_derived_class_constructor : 1;
  /* true if home_object needs to be initialized */
  uint8_t need_home_object : 1;
  uint8_t func_kind : 2;
  uint8_t new_target_allowed : 1;
  uint8_t super_call_allowed : 1;
  uint8_t super_allowed : 1;
  uint8_t arguments_allowed : 1;
  uint8_t has_debug : 1;
  uint8_t read_only_bytecode : 1;
  /* XXX: 4 bits available */
  uint8_t *byte_code_buf; /* (self pointer) */
  int byte_code_len;
  LEPUSAtom func_name;
  LEPUSVarDef *vardefs; /* arguments + local variables (arg_count + var_count)
                        (self pointer) */
  LEPUSClosureVar
      *closure_var; /* list of variables in the closure (self pointer) */
  uint16_t arg_count;
  uint16_t var_count;
  uint16_t defined_arg_count; /* for length function property */
  uint16_t stack_size;        /* maximum stack size */
  LEPUSValue *cpool;          /* constant pool (self pointer) */
  int cpool_count;
  int closure_var_count;
// <primjs begin>
#ifdef ENABLE_PRIMJS_IC
  TypeGetFeedBackVec *get_feedback_vec;
  TypeSetFeedBackVec *set_feedback_vec;
  uint32_t get_feedback_vec_size;
  uint32_t set_feedback_vec_size;
#endif

  // Jit entry
  // Attention: initial value is generate_normal_entry
  // After Jit: it's jit entry
#ifdef ENABLE_PRIMJS_BASELINEJIT
  uint8_t *jit_entry;
  EntryMode entry_mode = EntryMode::INTERPRETER;
  int jit_code_size;
  // Execuate Count
  uint32_t execuate_count;
  uint8_t **labels;
#endif

  // We will enable this in baselinejit
#if 0
  int *jump_target_bits;
  int *force_bits;
#endif

// <primjs end>
#ifdef ENABLE_QUICKJS_DEBUGGER
  DebuggerFuncLevelState func_level_state;
  struct list_head link; /*ctx->bytecode_list*/
  LEPUSScriptSource *script;
#endif
  // <ByteDance begin>
  struct list_head gc_link;
  uint32_t function_id;  // for lepusNG debugger encode
  // <ByteDance end>
  struct {
    /* debug info, move to separate structure to save memory? */
    LEPUSAtom filename;
    int line_num;
    int source_len;
    int pc2line_len;
#ifdef ENABLE_QUICKJS_DEBUGGER
    int64_t column_num;
#endif
    uint8_t *pc2line_buf;
    char *source;
  } debug;
  // ATTENTION: NEW MEMBERS MUST BE ADDED IN FRONT OF DEBUG FIELD!
} LEPUSFunctionBytecode;

typedef struct LEPUSBoundFunction {
  LEPUSValue func_obj;
  LEPUSValue this_val;
  int argc;
  LEPUSValue argv[0];
} LEPUSBoundFunction;

typedef enum LEPUSIteratorKindEnum {
  LEPUS_ITERATOR_KIND_KEY,
  LEPUS_ITERATOR_KIND_VALUE,
  LEPUS_ITERATOR_KIND_KEY_AND_VALUE,
} LEPUSIteratorKindEnum;

typedef struct LEPUSForInIterator {
  LEPUSValue obj;
  BOOL is_array;
  uint32_t array_length;
  uint32_t idx;
} LEPUSForInIterator;

typedef struct LEPUSRegExp {
  LEPUSString *pattern;
  LEPUSString *bytecode; /* also contains the flags */
} LEPUSRegExp;

typedef struct LEPUSProxyData {
  LEPUSValue target;
  LEPUSValue handler;
  LEPUSValue proto;
  uint8_t is_func;
  uint8_t is_revoked;
} LEPUSProxyData;

typedef struct LEPUSArrayBuffer {
  int byte_length; /* 0 if detached */
  uint8_t detached;
  uint8_t shared; /* if shared, the array buffer cannot be detached */
  uint8_t *data;  /* NULL if detached */
  struct list_head array_list;
  void *opaque;
  LEPUSFreeArrayBufferDataFunc *free_func;
} LEPUSArrayBuffer;

typedef struct LEPUSTypedArray {
  struct list_head link; /* link to arraybuffer */
  LEPUSObject *obj;      /* back pointer to the TypedArray/DataView object */
  LEPUSObject *buffer;   /* based array buffer */
  uint32_t offset;       /* offset in the array buffer */
  uint32_t length;       /* length in the array buffer */
} LEPUSTypedArray;

typedef struct LEPUSAsyncFunctionState {
  LEPUSValue this_val; /* 'this' generator argument */
  int argc;            /* number of function arguments */
  BOOL throw_flag;     /* used to throw an exception in LEPUS_CallInternal() */
  LEPUSStackFrame frame;
#ifdef ENABLE_PRIMJS_SNAPSHOT
  LEPUSValue *_arg_buf;
#endif
} LEPUSAsyncFunctionState;

/* XXX: could use an object instead to avoid the
   LEPUS_TAG_ASYNC_FUNCTION tag for the GC */
typedef struct LEPUSAsyncFunctionData {
  LEPUSRefCountHeader header; /* must come first, 32-bit */
  LEPUSGCHeader gc_header;    /* must come after LEPUSRefCountHeader, 8-bit */
  LEPUSValue resolving_funcs[2];
  BOOL is_active; /* true if the async function state is valid */
  LEPUSAsyncFunctionState func_state;
} LEPUSAsyncFunctionData;

typedef struct LEPUSReqModuleEntry {
  LEPUSAtom module_name;
  LEPUSModuleDef *module; /* used using resolution */
} LEPUSReqModuleEntry;

typedef enum LEPUSExportTypeEnum {
  LEPUS_EXPORT_TYPE_LOCAL,
  LEPUS_EXPORT_TYPE_INDIRECT,
} LEPUSExportTypeEnum;

typedef struct LEPUSExportEntry {
  union {
    struct {
      int var_idx;          /* closure variable index */
      LEPUSVarRef *var_ref; /* if != NULL, reference to the variable */
    } local;                /* for local export */
    int req_module_idx;     /* module for indirect export */
  } u;
  LEPUSExportTypeEnum export_type;
  LEPUSAtom local_name;  /* '*' if export ns from. not used for local
                         export after compilation */
  LEPUSAtom export_name; /* exported variable name */
} LEPUSExportEntry;

typedef struct LEPUSStarExportEntry {
  int req_module_idx; /* in req_module_entries */
} LEPUSStarExportEntry;

typedef struct LEPUSImportEntry {
  int var_idx; /* closure variable index */
  LEPUSAtom import_name;
  int req_module_idx; /* in req_module_entries */
} LEPUSImportEntry;

struct LEPUSModuleDef {
  LEPUSRefCountHeader header; /* must come first, 32-bit */
  LEPUSAtom module_name;
  struct list_head link;

  LEPUSReqModuleEntry *req_module_entries;
  int req_module_entries_count;
  int req_module_entries_size;

  LEPUSExportEntry *export_entries;
  int export_entries_count;
  int export_entries_size;

  LEPUSStarExportEntry *star_export_entries;
  int star_export_entries_count;
  int star_export_entries_size;

  LEPUSImportEntry *import_entries;
  int import_entries_count;
  int import_entries_size;

  LEPUSValue module_ns;
  LEPUSValue func_obj;            /* only used for LEPUS modules */
  LEPUSModuleInitFunc *init_func; /* only used for C modules */
  BOOL resolved : 8;
  BOOL instantiated : 8;
  BOOL evaluated : 8;
  BOOL eval_mark : 8; /* temporary use during lepus_evaluate_module() */
  /* true if evaluation yielded an exception. It is saved in
     eval_exception */
  BOOL eval_has_exception : 8;
  LEPUSValue eval_exception;
};

typedef struct LEPUSJobEntry {
  struct list_head link;
  LEPUSContext *ctx;
  LEPUSJobFunc *job_func;
  int argc;
  LEPUSValue argv[0];
} LEPUSJobEntry;

typedef struct LEPUSProperty {
  union {
    LEPUSValue value;      /* LEPUS_PROP_NORMAL */
    struct {               /* LEPUS_PROP_GETSET */
      LEPUSObject *getter; /* NULL if undefined */
      LEPUSObject *setter; /* NULL if undefined */
    } getset;
    LEPUSVarRef *var_ref; /* LEPUS_PROP_VARREF */
    struct {              /* LEPUS_PROP_AUTOINIT */
      LEPUSValue (*init_func)(LEPUSContext *ctx, LEPUSObject *obj,
                              LEPUSAtom prop, void *opaque);
      void *opaque;
    } init;
  } u;
} LEPUSProperty;

#define LEPUS_PROP_INITIAL_SIZE 2
#define LEPUS_PROP_INITIAL_HASH_SIZE 4 /* must be a power of two */
#define LEPUS_ARRAY_INITIAL_SIZE 2

typedef struct LEPUSShapeProperty {
  uint32_t hash_next : 26; /* 0 if last in list */
  uint32_t flags : 6;      /* LEPUS_PROP_XXX */
  LEPUSAtom atom;          /* LEPUS_ATOM_NULL = free property entry */
} LEPUSShapeProperty;

struct LEPUSShape {
  uint32_t prop_hash_end[0];  /* hash table of size hash_mask + 1
                                 before the start of the structure. */
  LEPUSRefCountHeader header; /* must come first, 32-bit */
  LEPUSGCHeader gc_header;    /* must come after LEPUSRefCountHeader, 8-bit */
  /* true if the shape is inserted in the shape hash table. If not,
     LEPUSShape.hash is not valid */
  uint8_t is_hashed;
  /* If true, the shape may have small array index properties 'n' with 0
     <= n <= 2^31-1. If false, the shape is guaranteed not to have
     small array index properties */
  uint8_t has_small_array_index;
  uint32_t hash; /* current hash value */
  uint32_t prop_hash_mask;
  int prop_size; /* allocated properties */
  int prop_count;
  LEPUSShape *shape_hash_next; /* in LEPUSRuntime.shape_hash[h] list */
  LEPUSObject *proto;
  LEPUSShapeProperty prop[0]; /* prop_size elements */
};
struct LEPUSObject {
  LEPUSRefCountHeader header; /* must come first, 32-bit */
  LEPUSGCHeader gc_header;    /* must come after LEPUSRefCountHeader, 8-bit */
  uint8_t extensible : 1;
  uint8_t free_mark : 1;      /* only used when freeing objects with cycles */
  uint8_t is_exotic : 1;      /* TRUE if object has exotic property handlers */
  uint8_t fast_array : 1;     /* TRUE if u.array is used for get/put */
  uint8_t is_constructor : 1; /* TRUE if object is a constructor function */
  uint8_t is_uncatchable_error : 1; /* if TRUE, error is not catchable */
  uint8_t is_class : 1;             /* TRUE if object is a class constructor */
  uint8_t tmp_mark : 1;             /* used in LEPUS_WriteObjectRec() */
  uint16_t class_id;                /* see LEPUS_CLASS_x */
  /* byte offsets: 8/8 */
  struct list_head link; /* object list */
  /* byte offsets: 16/24 */
  LEPUSShape *shape;   /* prototype and property names + flag */
  LEPUSProperty *prop; /* array of properties */
  /* byte offsets: 24/40 */
  struct LEPUSMapRecord
      *first_weak_ref; /* XXX: use a bit and an external hash table? */
  /* byte offsets: 28/48 */
  union {
    void *opaque;
    struct LEPUSBoundFunction *bound_function; /* LEPUS_CLASS_BOUND_FUNCTION */
    struct LEPUSCFunctionDataRecord
        *c_function_data_record; /* LEPUS_CLASS_C_FUNCTION_DATA */
    struct LEPUSForInIterator
        *for_in_iterator;                  /* LEPUS_CLASS_FOR_IN_ITERATOR */
    struct LEPUSArrayBuffer *array_buffer; /* LEPUS_CLASS_ARRAY_BUFFER,
                                              LEPUS_CLASS_SHARED_ARRAY_BUFFER */
    struct LEPUSTypedArray
        *typed_array; /* LEPUS_CLASS_UINT8C_ARRAY..LEPUS_CLASS_DATAVIEW */
#ifdef CONFIG_BIGNUM
    struct LEPUSFloatEnv *float_env; /* LEPUS_CLASS_FLOAT_ENV */
#endif
    struct LEPUSMapState *map_state; /* LEPUS_CLASS_MAP..LEPUS_CLASS_WEAKSET */
    struct LEPUSMapIteratorData
        *map_iterator_data; /* LEPUS_CLASS_MAP_ITERATOR,
                               LEPUS_CLASS_SET_ITERATOR */
    struct LEPUSArrayIteratorData
        *array_iterator_data; /* LEPUS_CLASS_ARRAY_ITERATOR,
                                 LEPUS_CLASS_STRING_ITERATOR */
    struct LEPUSRegExpStringIteratorData
        *regexp_string_iterator_data; /* LEPUS_CLASS_REGEXP_STRING_ITERATOR */
    struct LEPUSGeneratorData *generator_data; /* LEPUS_CLASS_GENERATOR */
    struct LEPUSProxyData *proxy_data;         /* LEPUS_CLASS_PROXY */
    struct LEPUSPromiseData *promise_data;     /* LEPUS_CLASS_PROMISE */
    struct LEPUSPromiseFunctionData
        *promise_function_data; /* LEPUS_CLASS_PROMISE_RESOLVE_FUNCTION,
                                   LEPUS_CLASS_PROMISE_REJECT_FUNCTION */
    struct LEPUSAsyncFunctionData
        *async_function_data; /* LEPUS_CLASS_ASYNC_FUNCTION_RESOLVE,
                                 LEPUS_CLASS_ASYNC_FUNCTION_REJECT */
    struct LEPUSAsyncFromSyncIteratorData
        *async_from_sync_iterator_data; /* LEPUS_CLASS_ASYNC_FROM_SYNC_ITERATOR
                                         */
    struct LEPUSAsyncGeneratorData
        *async_generator_data; /* LEPUS_CLASS_ASYNC_GENERATOR */
    struct {                   /* LEPUS_CLASS_BYTECODE_FUNCTION: 12/24 bytes */
      /* also used by LEPUS_CLASS_GENERATOR_FUNCTION, LEPUS_CLASS_ASYNC_FUNCTION
       * and LEPUS_CLASS_ASYNC_GENERATOR_FUNCTION */
      struct LEPUSFunctionBytecode *function_bytecode;
      LEPUSVarRef **var_refs;
      LEPUSObject *home_object; /* for 'super' access */
    } func;
    struct { /* LEPUS_CLASS_C_FUNCTION: 12/20 bytes */
      LEPUSCFunctionType c_function;
      uint8_t length;
      uint8_t cproto;
      int16_t magic;
    } cfunc;
    /* array part for fast arrays and typed arrays */
    struct { /* LEPUS_CLASS_ARRAY, LEPUS_CLASS_ARGUMENTS,
                LEPUS_CLASS_UINT8C_ARRAY..LEPUS_CLASS_FLOAT64_ARRAY */
      union {
        uint32_t size; /* LEPUS_CLASS_ARRAY, LEPUS_CLASS_ARGUMENTS */
        struct LEPUSTypedArray
            *typed_array; /* LEPUS_CLASS_UINT8C_ARRAY..LEPUS_CLASS_FLOAT64_ARRAY
                           */
      } u1;
      union {
        LEPUSValue *values; /* LEPUS_CLASS_ARRAY, LEPUS_CLASS_ARGUMENTS */
        void *ptr; /* LEPUS_CLASS_UINT8C_ARRAY..LEPUS_CLASS_FLOAT64_ARRAY */
        int8_t *int8_ptr; /* LEPUS_CLASS_INT8_ARRAY */
        uint8_t
            *uint8_ptr; /* LEPUS_CLASS_UINT8_ARRAY, LEPUS_CLASS_UINT8C_ARRAY */
        int16_t *int16_ptr;   /* LEPUS_CLASS_INT16_ARRAY */
        uint16_t *uint16_ptr; /* LEPUS_CLASS_UINT16_ARRAY */
        int32_t *int32_ptr;   /* LEPUS_CLASS_INT32_ARRAY */
        uint32_t *uint32_ptr; /* LEPUS_CLASS_UINT32_ARRAY */
        int64_t *int64_ptr;   /* LEPUS_CLASS_INT64_ARRAY */
        uint64_t *uint64_ptr; /* LEPUS_CLASS_UINT64_ARRAY */
        float *float_ptr;     /* LEPUS_CLASS_FLOAT32_ARRAY */
        double *double_ptr;   /* LEPUS_CLASS_FLOAT64_ARRAY */
      } u;
      uint32_t count;       /* <= 2^31-1. 0 for a detached typed array */
    } array;                /* 12/20 bytes */
    LEPUSRegExp regexp;     /* LEPUS_CLASS_REGEXP: 8/16 bytes */
    LEPUSValue object_data; /* for LEPUS_SetObjectData(): 8/16/16 bytes */
  } u;
  /* byte sizes: 40/48/72 */
};

enum {
  LEPUS_ATOM_NULL,
#define DEF(name, str) LEPUS_ATOM_##name,
#include "quickjs-atom.h"
#undef DEF
  LEPUS_ATOM_END,
};
#define LEPUS_ATOM_LAST_KEYWORD LEPUS_ATOM_super
#define LEPUS_ATOM_LAST_STRICT_KEYWORD LEPUS_ATOM_yield

static const char lepus_atom_init[] =
#define DEF(name, str) str "\0"
#include "quickjs-atom.h"
#undef DEF
    ;

typedef struct LEPUSOpCode {
#if defined(ENABLE_PRIMJS_SNAPSHOT) || defined(DUMP_BYTECODE)
  const char *name;
#endif

  uint8_t size; /* in bytes */
  /* the opcodes remove n_pop items from the top of the stack, then
     pushes n_push items */
  uint8_t n_pop;
  uint8_t n_push;
  uint8_t fmt;
} LEPUSOpCode;

extern const LEPUSOpCode opcode_info[];

#if SHORT_OPCODES
/* After the final compilation pass, short opcodes are used. Their
   opcodes overlap with the temporary opcodes which cannot appear in
   the final bytecode. Their description is after the temporary
   opcodes in opcode_info[]. */
#define short_opcode_info(op)                                              \
  opcode_info[(op) >= OP_TEMP_START ? (op) + (OP_TEMP_END - OP_TEMP_START) \
                                    : (op)]
#else
#define short_opcode_info(op) opcode_info[op]
#endif

// <primjs begin>

#if defined(ANDROID) || defined(__ANDROID__)
#include <android/log.h>

#define LOG_TAG "PRIMJS"

#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#endif

#define PRINT_LOG_TO_FILE 0

#ifdef ENABLE_PRIMJS_TRACE
#if defined(ANDROID) || defined(__ANDROID__)
#if PRINT_LOG_TO_FILE
extern FILE *log_f;
#define PRIM_LOG(...)            \
  do {                           \
    fprintf(log_f, __VA_ARGS__); \
    fflush(log_f);               \
  } while (0)
#else
#define PRIM_LOG(...) \
  __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#endif  // PRINT_LOG_TO_FILE
#else
#define PRIM_LOG printf
#endif  // ANDROID
#else
#define PRIM_LOG(...)
#endif  // ENABLE_PRIMJS_TRACE

#define OP_DEFINE_METHOD_METHOD 0
#define OP_DEFINE_METHOD_GETTER 1
#define OP_DEFINE_METHOD_SETTER 2
#define OP_DEFINE_METHOD_ENUMERABLE 4

#define LEPUS_THROW_VAR_RO 0
#define LEPUS_THROW_VAR_REDECL 1
#define LEPUS_THROW_VAR_UNINITIALIZED 2
#define LEPUS_THROW_ERROR_DELETE_SUPER 3

#define LEPUS_CALL_FLAG_CONSTRUCTOR (1 << 0)
#define LEPUS_CALL_FLAG_COPY_ARGV (1 << 1)
#define LEPUS_CALL_FLAG_GENERATOR (1 << 2)

#define __exception __attribute__((warn_unused_result))

/* LEPUSAtom support */
#define LEPUS_ATOM_TAG_INT (1U << 31)
#define LEPUS_ATOM_MAX_INT (LEPUS_ATOM_TAG_INT - 1)
#define LEPUS_ATOM_MAX ((1U << 30) - 1)

/* return the max count from the hash size */
#define LEPUS_ATOM_COUNT_RESIZE(n) ((n)*2)

/* argument of OP_special_object */
typedef enum {
  OP_SPECIAL_OBJECT_ARGUMENTS,
  OP_SPECIAL_OBJECT_MAPPED_ARGUMENTS,
  OP_SPECIAL_OBJECT_THIS_FUNC,
  OP_SPECIAL_OBJECT_NEW_TARGET,
  OP_SPECIAL_OBJECT_HOME_OBJECT,
  OP_SPECIAL_OBJECT_VAR_OBJECT,
} OPSpecialObjectEnum;

#define FUNC_RET_AWAIT 0
#define FUNC_RET_YIELD 1
#define FUNC_RET_YIELD_STAR 2

#define HINT_STRING 0
#define HINT_NUMBER 1
#define HINT_NONE 2
#ifdef CONFIG_BIGNUM
#define HINT_INTEGER 3
#endif
/* don't try Symbol.toPrimitive */
#define HINT_FORCE_ORDINARY (1 << 4)

#define prim_abort()                               \
  {                                                \
    printf("[%s:%d] Abort\n", __FILE__, __LINE__); \
    abort();                                       \
  }

#ifdef __cplusplus
extern "C" {
#endif
QJS_HIDE LEPUSValue LEPUS_GetPropertyInternalImpl(
    LEPUSContext *ctx, LEPUSValueConst obj, LEPUSAtom prop,
    LEPUSValueConst this_obj, BOOL throw_ref_error,
    TypeGetFeedBack *feedback = NULL);

QJS_HIDE LEPUSValue LEPUS_GetPropertyWithIC(LEPUSContext *ctx,
                                            LEPUSValueConst this_obj,
                                            LEPUSAtom prop,
                                            TypeGetFeedBack *feedback_vec);

QJS_HIDE void prim_js_print(const char *msg);

QJS_HIDE void prim_js_print_register(uint64_t reg_val);

QJS_HIDE void prim_js_print_trace(int bytecode, int tos);

QJS_HIDE void prim_js_print_func(LEPUSContext *ctx, LEPUSValue func_obj);

QJS_HIDE void LEPUS_FreeValueRef(LEPUSContext *ctx, LEPUSValue v);

QJS_HIDE LEPUSValue lepus_closure(LEPUSContext *ctx, LEPUSValue bfunc,
                                  LEPUSVarRef **cur_var_refs,
                                  LEPUSStackFrame *sf);

QJS_HIDE void DebuggerPause(LEPUSContext *ctx, LEPUSValue val,
                            const uint8_t *pc);

QJS_HIDE LEPUSValue __JS_AtomToValue(LEPUSContext *ctx, LEPUSAtom atom,
                                     BOOL force_string);

QJS_HIDE BOOL lepus_check_stack_overflow(LEPUSContext *ctx, size_t alloca_size);

QJS_HIDE LEPUSValue LEPUS_ThrowStackOverflow(LEPUSContext *ctx);

QJS_HIDE void build_backtrace(
    LEPUSContext *ctx, LEPUSValueConst error_obj, const char *filename,
    /* <ByteDance begin> */ int64_t line_num, /* <ByteDance end> */
    const uint8_t *cur_pc, int backtrace_flags, uint8_t is_parse_error = 0);

QJS_HIDE LEPUSValue LEPUS_NewSymbolFromAtom(LEPUSContext *ctx, LEPUSAtom descr,
                                            int atom_type);

QJS_HIDE LEPUSValue LEPUS_ToObject(LEPUSContext *ctx, LEPUSValueConst val);

QJS_HIDE LEPUSValue PRIM_JS_NewObject(LEPUSContext *ctx);

QJS_HIDE LEPUSValue lepus_build_arguments(LEPUSContext *ctx, int argc,
                                          LEPUSValueConst *argv);

QJS_HIDE LEPUSValue lepus_build_mapped_arguments(LEPUSContext *ctx, int argc,
                                                 LEPUSValueConst *argv,
                                                 LEPUSStackFrame *sf,
                                                 int arg_count);

QJS_HIDE void prim_close_var_refs(LEPUSContext *ctx, LEPUSStackFrame *sf);

QJS_HIDE LEPUSValue lepus_build_rest(LEPUSContext *ctx, int first, int argc,
                                     LEPUSValueConst *argv);

QJS_HIDE LEPUSValue lepus_function_apply(LEPUSContext *ctx,
                                         LEPUSValueConst this_val, int argc,
                                         LEPUSValueConst *argv, int magic);

QJS_HIDE int LEPUS_CheckBrand(LEPUSContext *ctx, LEPUSValueConst obj,
                              LEPUSValueConst func);

QJS_HIDE int LEPUS_AddBrand(LEPUSContext *ctx, LEPUSValueConst obj,
                            LEPUSValueConst home_obj);

QJS_HIDE int LEPUS_ThrowTypeErrorReadOnly(LEPUSContext *ctx, int flags,
                                          LEPUSAtom atom);

QJS_HIDE LEPUSValue LEPUS_ThrowSyntaxErrorVarRedeclaration(LEPUSContext *ctx,
                                                           LEPUSAtom prop);

QJS_HIDE LEPUSValue LEPUS_ThrowReferenceErrorUninitialized(LEPUSContext *ctx,
                                                           LEPUSAtom name);

QJS_HIDE int LEPUS_IteratorClose(LEPUSContext *ctx, LEPUSValueConst enum_obj,
                                 BOOL is_exception_pending);

QJS_HIDE LEPUSValue LEPUS_CallConstructorInternal(LEPUSContext *ctx,
                                                  LEPUSValueConst func_obj,
                                                  LEPUSValueConst new_target,
                                                  int argc, LEPUSValue *argv,
                                                  int flags);

QJS_HIDE int LEPUS_CheckGlobalVar(LEPUSContext *ctx, LEPUSAtom prop);

QJS_HIDE LEPUSValue LEPUS_GetPropertyValue(LEPUSContext *ctx,
                                           LEPUSValueConst this_obj,
                                           LEPUSValue prop);

QJS_HIDE int LEPUS_DefineGlobalVar(LEPUSContext *ctx, LEPUSAtom prop,
                                   int def_flags);

QJS_HIDE LEPUSValue PRIM_JS_NewArray(LEPUSContext *ctx);

QJS_HIDE LEPUSValue lepus_regexp_constructor_internal(LEPUSContext *ctx,
                                                      LEPUSValueConst ctor,
                                                      LEPUSValue pattern,
                                                      LEPUSValue bc);

QJS_HIDE int LEPUS_SetPropertyValue(LEPUSContext *ctx, LEPUSValueConst this_obj,
                                    LEPUSValue prop, LEPUSValue val, int flags);

QJS_HIDE int LEPUS_CheckDefineGlobalVar(LEPUSContext *ctx, LEPUSAtom prop,
                                        int flags);

QJS_HIDE int LEPUS_DefineGlobalFunction(LEPUSContext *ctx, LEPUSAtom prop,
                                        LEPUSValueConst func, int def_flags);

QJS_HIDE LEPUSValue LEPUS_GetPrivateField(LEPUSContext *ctx,
                                          LEPUSValueConst obj,
                                          LEPUSValueConst name);

QJS_HIDE int LEPUS_DefinePrivateField(LEPUSContext *ctx, LEPUSValueConst obj,
                                      LEPUSValueConst name, LEPUSValue val);

QJS_HIDE int LEPUS_DefineObjectName(LEPUSContext *ctx, LEPUSValueConst obj,
                                    LEPUSAtom name, int flags);

QJS_HIDE int LEPUS_DefineObjectNameComputed(LEPUSContext *ctx,
                                            LEPUSValueConst obj,
                                            LEPUSValueConst str, int flags);

QJS_HIDE int LEPUS_SetPrototypeInternal(LEPUSContext *ctx, LEPUSValueConst obj,
                                        LEPUSValueConst proto_val,
                                        BOOL throw_flag);

QJS_HIDE void lepus_method_set_home_object(LEPUSContext *ctx,
                                           LEPUSValueConst func_obj,
                                           LEPUSValueConst home_obj);

QJS_HIDE int LEPUS_DefinePropertyValueValue(LEPUSContext *ctx,
                                            LEPUSValueConst this_obj,
                                            LEPUSValue prop, LEPUSValue val,
                                            int flags);

QJS_HIDE __exception int lepus_append_enumerate(LEPUSContext *ctx,
                                                LEPUSValue *sp);

QJS_HIDE int lepus_method_set_properties(LEPUSContext *ctx,
                                         LEPUSValueConst func_obj,
                                         LEPUSAtom name, int flags,
                                         LEPUSValueConst home_obj);

QJS_HIDE int prim_js_copy_data_properties(LEPUSContext *ctx, LEPUSValue *sp,
                                          int mask);

QJS_HIDE int LEPUS_ToBoolFree(LEPUSContext *ctx, LEPUSValue val);

QJS_HIDE int lepus_op_define_class(LEPUSContext *ctx, LEPUSValue *sp,
                                   LEPUSAtom class_name, int class_flags,
                                   LEPUSVarRef **cur_var_refs,
                                   LEPUSStackFrame *sf);

QJS_HIDE void close_lexical_var(LEPUSContext *ctx, LEPUSStackFrame *sf, int idx,
                                int is_arg);

QJS_HIDE int LEPUS_SetPropertyGeneric(LEPUSContext *ctx, LEPUSObject *p,
                                      LEPUSAtom prop, LEPUSValue val,
                                      LEPUSValueConst this_obj, int flags);

QJS_HIDE int LEPUS_SetPrivateField(LEPUSContext *ctx, LEPUSValueConst obj,
                                   LEPUSValueConst name, LEPUSValue val);

QJS_HIDE LEPUSValue LEPUS_ThrowTypeErrorNotAnObject(LEPUSContext *ctx);

QJS_HIDE int prim_js_with_op(LEPUSContext *ctx, LEPUSValue *sp, LEPUSAtom atom,
                             int is_with, int opcode);

QJS_HIDE LEPUSVarRef *get_var_ref(LEPUSContext *ctx, LEPUSStackFrame *sf,
                                  int var_idx, BOOL is_arg);

QJS_HIDE LEPUSProperty *add_property(LEPUSContext *ctx, LEPUSObject *p,
                                     LEPUSAtom prop, int prop_flags);

QJS_HIDE LEPUSValue prim_js_op_eval(LEPUSContext *ctx, int scope_idx,
                                    LEPUSValue op1);

QJS_HIDE int prim_js_with_op(LEPUSContext *ctx, LEPUSValue *sp, LEPUSAtom atom,
                             int is_with, int opcode);

QJS_HIDE LEPUSValue LEPUS_GetGlobalVarImpl(LEPUSContext *ctx, LEPUSAtom prop,
                                           BOOL throw_ref_error,
                                           TypeGetFeedBack *feedback = NULL);

QJS_HIDE int LEPUS_GetGlobalVarRef(LEPUSContext *ctx, LEPUSAtom prop,
                                   LEPUSValue *sp);

QJS_HIDE LEPUSValue prim_js_for_in_start(LEPUSContext *ctx, LEPUSValue op);

QJS_HIDE int lepus_for_in_next(LEPUSContext *ctx, LEPUSValue *sp);

QJS_HIDE int lepus_for_await_of_next(LEPUSContext *ctx, LEPUSValue *sp);

QJS_HIDE int lepus_iterator_get_value_done(LEPUSContext *ctx, LEPUSValue *sp);

QJS_HIDE int lepus_for_of_start(LEPUSContext *ctx, LEPUSValue *sp,
                                BOOL is_async);

QJS_HIDE int lepus_for_of_next(LEPUSContext *ctx, LEPUSValue *sp, int offset);

QJS_HIDE LEPUSValue *prim_js_iterator_close_return(LEPUSContext *ctx,
                                                   LEPUSValue *sp);

QJS_HIDE int prim_js_async_iterator_close(LEPUSContext *ctx, LEPUSValue *sp);

QJS_HIDE int prim_js_async_iterator_get(LEPUSContext *ctx, LEPUSValue *sp,
                                        int flags);

QJS_HIDE LEPUSValue primjs_get_super_ctor(LEPUSContext *ctx, LEPUSValue op);

QJS_HIDE int prim_js_iterator_call(LEPUSContext *ctx, LEPUSValue *sp,
                                   int flags);

QJS_HIDE LEPUSValue prim_js_unary_arith_slow(LEPUSContext *ctx, LEPUSValue op1,
                                             OPCodeEnum op);

QJS_HIDE LEPUSValue LEPUS_ToPrimitiveFree(LEPUSContext *ctx, LEPUSValue val,
                                          int hint);

QJS_HIDE LEPUSValue LEPUS_ConcatString(LEPUSContext *ctx, LEPUSValue op1,
                                       LEPUSValue op2);

QJS_HIDE LEPUSValue prim_js_unary_arith_slow(LEPUSContext *ctx, LEPUSValue op1,
                                             OPCodeEnum op);

QJS_HIDE LEPUSValue prim_js_add_slow(LEPUSContext *ctx, LEPUSValue op1,
                                     LEPUSValue op2);

QJS_HIDE no_inline LEPUSValue prim_js_not_slow(LEPUSContext *ctx,
                                               LEPUSValue op);

QJS_HIDE LEPUSValue prim_js_binary_arith_slow(LEPUSContext *ctx, LEPUSValue op1,
                                              LEPUSValue op2, OPCodeEnum op);

QJS_HIDE double prim_js_fmod_double(double a, double b);

QJS_HIDE int lepus_post_inc_slow(LEPUSContext *ctx, LEPUSValue *sp,
                                 OPCodeEnum op);

QJS_HIDE LEPUSValue prim_js_binary_logic_slow(LEPUSContext *ctx, LEPUSValue op1,
                                              LEPUSValue op2, OPCodeEnum op);

QJS_HIDE LEPUSValue prim_js_shr_slow(LEPUSContext *ctx, LEPUSValue op1,
                                     LEPUSValue op2);

QJS_HIDE LEPUSValue prim_js_relation_slow(LEPUSContext *ctx, LEPUSValue op1,
                                          LEPUSValue op2, OPCodeEnum op);

QJS_HIDE LEPUSValue prim_js_eq_slow(LEPUSContext *ctx, LEPUSValue op1,
                                    LEPUSValue op2, int is_neq);

QJS_HIDE LEPUSValue prim_js_strict_eq_slow(LEPUSContext *ctx, LEPUSValue op1,
                                           LEPUSValue op2, BOOL is_neq);

QJS_HIDE LEPUSValue prim_js_operator_instanceof(LEPUSContext *ctx,
                                                LEPUSValue op1, LEPUSValue op2);

QJS_HIDE LEPUSValue prim_js_operator_in(LEPUSContext *ctx, LEPUSValue op1,
                                        LEPUSValue op2);

QJS_HIDE __exception int lepus_operator_typeof(LEPUSContext *ctx,
                                               LEPUSValue op1);

QJS_HIDE LEPUSValue prim_js_operator_delete(LEPUSContext *ctx, LEPUSValue op1,
                                            LEPUSValue op2);

QJS_HIDE int LEPUS_SetPropertyInternalImpl(LEPUSContext *ctx,
                                           LEPUSValueConst this_obj,
                                           LEPUSAtom prop, LEPUSValue val,
                                           int flags,
                                           TypeSetFeedBack *feedback = NULL);

QJS_HIDE int LEPUS_SetPropertyWithIC(LEPUSContext *ctx,
                                     LEPUSValueConst this_obj, LEPUSAtom prop,
                                     LEPUSValue val, int flags,
                                     TypeSetFeedBack *feedback_vec);

QJS_HIDE int set_array_length(LEPUSContext *ctx, LEPUSObject *p,
                              LEPUSProperty *prop, LEPUSValue val, int flags);

QJS_HIDE BOOL LEPUS_IsUncatchableError(LEPUSContext *ctx, LEPUSValueConst val);
QJS_HIDE LEPUSAtom lepus_value_to_atom(LEPUSContext *ctx, LEPUSValueConst val);
QJS_HIDE LEPUSValue LEPUS_ThrowReferenceErrorNotDefined(LEPUSContext *ctx,
                                                        LEPUSAtom name);

#ifdef ENABLE_PRIMJS_SNAPSHOT
typedef LEPUSValue (*QuickJsCallStub)(LEPUSValue this_arg,
                                      LEPUSValue new_target,
                                      LEPUSValue func_obj, address entry_point,
                                      int argc, LEPUSValue *argv, int flags);

extern QuickJsCallStub entry;
QJS_HIDE void compile_function(LEPUSContext *, LEPUSFunctionBytecode *bytecode);
#endif

// <primjs end>

#ifndef NO_QUICKJS_COMPILER
LEPUSValue lepus_dynamic_import(LEPUSContext *ctx, LEPUSValueConst specifier);
#endif

#ifdef __cplusplus
}
#endif

#endif /* QUICKJS_INNER_H */