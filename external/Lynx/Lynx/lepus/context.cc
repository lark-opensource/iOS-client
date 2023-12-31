// Copyright 2020 The Lynx Authors. All rights reserved.

#include "lepus/context.h"

#include <unordered_set>
#include <utility>

#include "base/debug/error_code.h"
#include "base/lynx_env.h"
#include "base/threading/thread_local.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/array.h"
#include "lepus/jsvalue_helper.h"
#include "lepus/qjs_callback.h"
#include "lepus/quick_context.h"
#include "lepus/table.h"
#include "lepus/vm_context.h"
#include "tasm/lynx_trace_event.h"

#ifndef LEPUS_PC
#ifndef BUILD_LEPUS
#include "tasm/template_assembler.h"
#endif
#endif

#if defined(MODE_HEADLESS)
#include "headless/headless_event_emitter.h"
#endif

namespace lynx {
namespace lepus {
class LeakVisitor {
 public:
  void ClearData() {
    visit_table.clear();
    visit_array.clear();
    table_edge.clear();
    array_edge.clear();
    out_sum = 0;
    rc_sum = 0;
  }
  std::unordered_set<Dictionary*> visit_table;
  std::unordered_set<CArray*> visit_array;
  std::set<std::pair<Dictionary*, String>> table_edge;
  std::set<std::pair<CArray*, int>> array_edge;
  int out_sum = 0;
  int rc_sum = 0;
};

// traverse leak tables and arrays to get visitor.rc_sum and visitor.out_sum
static __attribute__((unused)) void TraverseCArray(CArray* array,
                                                   LeakVisitor& visitor);

static __attribute__((unused)) void TraverseTable(Dictionary* table,
                                                  LeakVisitor& visitor) {
  if (!table) return;
  visitor.visit_table.insert(table);
  int out = 0;
  Dictionary* table_ptr = nullptr;
  CArray* array_ptr = nullptr;
  for (auto it = table->begin(); it != table->end(); it++) {
    switch (it->second.Type()) {
      case Value_Table: {
        out++;
        table_ptr = reinterpret_cast<Dictionary*>(it->second.Ptr());
        auto ele = visitor.visit_table.find(const_cast<Dictionary*>(table_ptr));
        if (ele != visitor.visit_table.end()) {
          visitor.table_edge.insert(std::make_pair(table, it->first));
        } else {
          TraverseTable(table_ptr, visitor);
        }
        break;
      }
      case Value_Array: {
        out++;
        array_ptr = reinterpret_cast<CArray*>(it->second.Ptr());
        auto ele = visitor.visit_array.find(const_cast<CArray*>(array_ptr));
        if (ele != visitor.visit_array.end()) {
          visitor.table_edge.insert(std::make_pair(table, it->first));
        } else {
          TraverseCArray(array_ptr, visitor);
        }
        break;
      }
      default:
        break;
    }
  }
  visitor.rc_sum += table->SubtleRefCountForDebug();
  visitor.out_sum += out;
}

static __attribute__((unused)) void TraverseCArray(CArray* array,
                                                   LeakVisitor& visitor) {
  if (!array) return;
  visitor.visit_array.insert(array);
  size_t size = array->size();
  int out = 0;
  Dictionary* table_ptr = nullptr;
  CArray* array_ptr = nullptr;
  for (size_t i = 0; i < size; i++) {
    switch (array->get(i).Type()) {
      case Value_Table: {
        out++;
        table_ptr = reinterpret_cast<Dictionary*>(array->get(i).Ptr());
        auto ele = visitor.visit_table.find(const_cast<Dictionary*>(table_ptr));
        if (ele != visitor.visit_table.end()) {
          visitor.array_edge.insert(std::make_pair(array, i));
        } else {
          TraverseTable(table_ptr, visitor);
        }
        break;
      }
      case Value_Array: {
        out++;
        array_ptr = reinterpret_cast<CArray*>(array->get(i).Ptr());
        auto ele = visitor.visit_array.find(const_cast<CArray*>(array_ptr));
        if (ele != visitor.visit_array.end()) {
          visitor.array_edge.insert(std::make_pair(array, i));
        } else {
          TraverseCArray(array_ptr, visitor);
        }
        break;
      }
      default:
        break;
    }
  }
  visitor.rc_sum += array->SubtleRefCountForDebug();
  visitor.out_sum += out;
}

// helper to judge whether all leak tables/arrays have been traversed
static __attribute__((unused)) bool FinishTable(
    std::unordered_map<Dictionary*, ValueState>& table_map) {
  for (auto& it : table_map) {
    if (it.second == kNotTraversed) {
      return false;
    }
  }
  return true;
}

static __attribute__((unused)) bool FinishCArray(
    std::unordered_map<CArray*, ValueState>& array_map) {
  for (auto& it : array_map) {
    if (it.second == kNotTraversed) {
      return false;
    }
  }
  return true;
}

static __attribute__((unused)) Dictionary* GetFirstTable(
    std::unordered_map<Dictionary*, ValueState>& table_map) {
  for (auto& it : table_map) {
    if (it.second == kNotTraversed) {
      if (it.first == nullptr) {
        it.second = kOther;
        continue;
      }
      return it.first;
    }
  }
  return nullptr;
}

static __attribute__((unused)) CArray* GetFirstCArray(
    std::unordered_map<CArray*, ValueState>& array_map) {
  for (auto& it : array_map) {
    if (it.second == kNotTraversed) {
      if (it.first == nullptr) {
        it.second = kOther;
        continue;
      }
      return it.first;
    }
  }
  return nullptr;
}

// break the edge
static __attribute__((unused)) void RemoveCircle(LeakVisitor& visitor) {
  const Value val(5);  // a temporary value
  for (auto it : visitor.table_edge) {
    // set a temporary value to remove circle
    if (!it.first->set(it.second, val)) {
      LOGE("can't modify const table to remove circle");
    }
  }
  for (auto it : visitor.array_edge) {
    // set a temporary value to remove circle
    if (!it.first->set(it.second, val)) {
      LOGE("can't modify const array to remove circle");
    }
  }
}

static __attribute__((unused)) void SetFlagForRef(LeakVisitor& visitor) {
  for (auto& it : Context::GetLeakTable()) {
    if (visitor.visit_table.find(it.first) != visitor.visit_table.end()) {
      it.second = kCollected;
    }
  }
  for (auto& it : Context::GetLeakArray()) {
    if (visitor.visit_array.find(it.first) != visitor.visit_array.end()) {
      it.second = kCollected;
    }
  }
}

#ifdef DUMP_LEAKS
static __attribute__((unused)) void PrintOtherValue(std::ostringstream& output,
                                                    const Value& value) {
  switch (value.Type()) {
    case Value_Nil:
      output << "null";
      break;
    case Value_Undefined:
      output << "undefined";
      break;
    case Value_Double:
      output << StringConvertHelper::DoubleToString(value.Number());
      break;
    case Value_Int32:
      output << value.Int32();
      break;
    case Value_Int64:
      output << value.Int64();
      break;
    case Value_UInt32:
      output << value.UInt32();
      break;
    case Value_UInt64:
      output << value.UInt64();
      break;
    case Value_Bool:
      output << (value.Bool() ? "true" : "false");
      break;
    case Value_String:
      output << value.String()->c_str();
      break;
    case Value_Closure:
    case Value_CFunction:
    case Value_CPointer:
      output << "closure/cfunction/cpointer" << std::endl;
      break;
#if !ENABLE_JUST_LEPUSNG
    case Value_CDate:
      value.Date()->print(output);
      break;
    case Value_RegExp:
      output << "regexp" << std::endl;
      output << "pattern: " << value.RegExp()->get_pattern().str() << std::endl;
      output << "flags: " << value.RegExp()->get_flags().str() << std::endl;
      break;
#endif
    case Value_NaN:
      output << "NaN";
      break;
    case Value_JSObject:
      output << "LEPUSObject id=" << value.LEPUSObject()->JSIObjectID();
      break;
    case Value_ByteArray:
      output << "ByteArray";
      break;
    default:
      output << "unknow type";
      break;
  }
}

static __attribute__((unused)) void PrintTableInCircle(
    std::ostringstream& output, Dictionary* table) {
  output << "curTable: " << table << " rc: " << table->SubtleRefCountForDebug()
         << std::endl;
  output << "{";
  for (auto it = table->begin(); it != table->end(); it++) {
    if (it != table->begin()) {
      output << ", ";
    }
    output << it->first.str() << ":";
    if (it->second.IsTable()) {
      output << "pTable: " << it->second.Ptr();
    } else if (it->second.IsArray()) {
      output << "pArray: " << it->second.Ptr();
    } else {
      PrintOtherValue(output, it->second);
    }
  }
  output << "}" << std::endl;
}

static __attribute__((unused)) void PrintCArrayInCircle(
    std::ostringstream& output, CArray* array) {
  output << "curCArray: " << array << " rc: " << array->SubtleRefCountForDebug()
         << std::endl;
  output << "{";
  size_t size = array->size();
  for (size_t i = 0; i < size; i++) {
    if (array->get(i).IsTable()) {
      output << "pTable_" << array->get(i).Ptr();
    } else if (array->get(i).IsArray()) {
      output << "pArray: " << array->get(i).Ptr();
    } else {
      PrintOtherValue(output, array->get(i));
    }
    if (i != size - 1) {
      output << ", ";
    }
  }
  output << "}" << std::endl;
}

static __attribute__((unused)) void DumpLeak(bool is_circle) {
  std::ostringstream output;
  if (is_circle) {
    output << "====== leak tables/arrays with circle ======" << std::endl;
  } else {
    output << "======= leak tables/arrays without circle =======" << std::endl;
  }
  std::unordered_map<Dictionary*, ValueState> table = Context::GetLeakTable();
  for (auto it : table) {
    PrintTableInCircle(output, it.first);
  }
  std::unordered_map<CArray*, ValueState> array = Context::GetLeakArray();
  for (auto it : array) {
    PrintCArrayInCircle(output, it.first);
  }
  LOGE(output.str() << std::endl);
}
#endif

static __attribute__((unused)) void CollectLeak() {
  {
    std::lock_guard<std::mutex> guard(Context::GetLeakMutex());
    LeakVisitor visitor;
    while (!FinishTable(Context::GetLeakTable()) ||
           !FinishCArray(Context::GetLeakArray())) {
      visitor.ClearData();
      if (!FinishTable(Context::GetLeakTable())) {
        Dictionary* cur_table = GetFirstTable(Context::GetLeakTable());
        if (cur_table == nullptr) {
          continue;
        }
        TraverseTable(cur_table, visitor);
        if (visitor.rc_sum == visitor.out_sum) {
          SetFlagForRef(visitor);
          reinterpret_cast<base::RefCountedThreadSafeStorage*>(cur_table)
              ->AddRef();
          RemoveCircle(visitor);
          reinterpret_cast<base::RefCountedThreadSafeStorage*>(cur_table)
              ->Release();
        } else {
          if (!visitor.table_edge.empty() ||
              !visitor.array_edge.empty()) {  // circle
            Context::GetLeakTable()[cur_table] = kCircleWithRef;
#ifdef DUMP_LEAKS
            DumpLeak(true);
#endif
          } else {  // without circle
            Context::GetLeakTable()[cur_table] = kNotCircleWithRef;
#ifdef DUMP_LEAKS
            DumpLeak(false);
#endif
          }
        }
      } else if (!FinishCArray(Context::GetLeakArray())) {
        CArray* cur_array = GetFirstCArray(Context::GetLeakArray());
        if (cur_array == nullptr) {
          continue;
        }
        TraverseCArray(cur_array, visitor);
        if (visitor.rc_sum == visitor.out_sum) {
          SetFlagForRef(visitor);
          reinterpret_cast<base::RefCountedThreadSafeStorage*>(cur_array)
              ->AddRef();
          RemoveCircle(visitor);
          reinterpret_cast<base::RefCountedThreadSafeStorage*>(cur_array)
              ->Release();
        } else {
          if (!visitor.table_edge.empty() ||
              !visitor.array_edge.empty()) {  // circle
            Context::GetLeakArray()[cur_array] = kCircleWithRef;
#ifdef DUMP_LEAKS
            DumpLeak(true);
#endif
          } else {  // without circle
            Context::GetLeakArray()[cur_array] = kNotCircleWithRef;
#ifdef DUMP_LEAKS
            DumpLeak(false);
#endif
          }
        }
      }
    }
  }
}

static LEPUSValue LepusConvertToObjectCallBack(LEPUSContext* ctx,
                                               LEPUSValue val);

// register for quickjs to free LepusRef
static LEPUSValue LepusRefFreeCallBack(LEPUSRuntime* rt, LEPUSValue val) {
  if (!LEPUS_IsLepusRef(val)) return LEPUS_UNDEFINED;
  LEPUSLepusRef* pref = static_cast<LEPUSLepusRef*>(LEPUS_VALUE_GET_PTR(val));
  reinterpret_cast<base::RefCountedThreadSafeStorage*>(pref->p)->Release();
  pref->p = reinterpret_cast<void*>(0xdeaddead);
  LEPUS_FreeValueRT(rt, pref->lepus_val);
  lepus_free_rt(rt, pref);
  return LEPUS_UNDEFINED;
}

static void LepusReportSetConstValueError(LEPUSContext* ctx,
                                          LEPUSValue this_obj, LEPUSValue prop,
                                          int32_t idx) {
  lepus::QuickContext* qctx =
      QuickContext::Cast(Context::GetFromJsContext(ctx));

  qctx->ReportSetConstValueError(lepus::Value(ctx, this_obj), prop, idx);
}

// callback for quickjs setProperty for LepusRef
static LEPUSValue LepusRefSetPropertyCallBack(LEPUSContext* ctx,
                                              LEPUSValue thisObj,
                                              LEPUSValue prop, int idx,
                                              LEPUSValue val) {
  if (!LEPUS_IsLepusRef(thisObj)) return thisObj;
  LEPUSLepusRef* pref =
      static_cast<LEPUSLepusRef*>(LEPUS_VALUE_GET_PTR(thisObj));

  TRACE_EVENT(LYNX_TRACE_CATEGORY, "QuickContext::LepusRefSetPropertyCallBack");
  Value lepus_val(ctx, val);
  LEPUSValue lepusref_cache = pref->lepus_val;
  const char* name = nullptr;
  bool is_const = false;
  switch (pref->tag) {
    case Value_Table: {
      auto* dic = reinterpret_cast<lepus::Dictionary*>(pref->p);
      if (!(is_const = dic->IsConst())) {
        name = LEPUS_ToCString(ctx, prop);
        reinterpret_cast<Dictionary*>(pref->p)->SetValue(name, lepus_val);
        if (!LEPUS_IsUndefined(lepusref_cache)) {
          LEPUS_SetPropertyStr(ctx, lepusref_cache, name,
                               LEPUS_DupValue(ctx, val));
        }
        LEPUS_FreeCString(ctx, name);
        return LEPUS_UNDEFINED;
      }
    } break;
    case Value_Array: {
      CArray* array = reinterpret_cast<CArray*>(pref->p);
      if (!(is_const = array->IsConst())) {
        bool set_array_prop_result = false;
        uint32_t old_size = static_cast<uint32_t>(array->size());
        if (idx >= 0) {
          array->set(idx, lepus_val);
          for (auto i = old_size; i < static_cast<uint32_t>(idx); ++i) {
            const_cast<lepus::Value&>(array->get(i)).SetUndefined();
          }
          if (!LEPUS_IsUndefined(lepusref_cache)) {
            LEPUS_SetPropertyUint32(ctx, lepusref_cache, idx,
                                    LEPUS_DupValue(ctx, val));
          }
          return LEPUS_UNDEFINED;
        } else {
          LEPUSAtom prop_atom = LEPUS_ValueToAtom(ctx, prop);
          LEPUSAtom len_atom = LEPUS_NewAtom(ctx, "length");
          if (prop_atom == len_atom) {
            uint32_t new_array_len = 0;
            if (LEPUS_ToUint32(ctx, &new_array_len, val) == 0) {
              array->resize(new_array_len);
              for (auto i = old_size; i < new_array_len; ++i) {
                const_cast<lepus::Value&>(array->get(i)).SetUndefined();
              }
              if (!LEPUS_IsUndefined(lepusref_cache)) {
                LEPUS_SetPropertyInternal(ctx, lepusref_cache, len_atom,
                                          LEPUS_NewInt32(ctx, new_array_len),
                                          LEPUS_PROP_THROW);
              }
              set_array_prop_result = true;
            }
          }
          LEPUS_FreeAtom(ctx, prop_atom);
          LEPUS_FreeAtom(ctx, len_atom);
          if (set_array_prop_result) {
            return LEPUS_UNDEFINED;
          }
        }
      }
    } break;

    default:
      assert(false);
      break;
  }

  if (is_const) {
    if (lynx::base::LynxEnv::GetInstance().IsDevtoolComponentAttach()) {
      return LEPUS_ThrowTypeError(ctx,
                                  "Set const Value's property in lepusng\n");
    } else {
      LepusReportSetConstValueError(ctx, thisObj, prop, idx);
      return LEPUS_UNDEFINED;
    }
  }

  return LepusConvertToObjectCallBack(ctx, thisObj);
}

static void LepusRefFreeStringCache(void* old_p, void* p) {
  if (old_p) {
    StringImpl* impl = reinterpret_cast<StringImpl*>(old_p);
    impl->Release();
  }

  if (p) {
    StringImpl* impl = reinterpret_cast<StringImpl*>(p);
    impl->AddRef();
  }
}

static LEPUSValue LepusRefGetPropertyCallBack(LEPUSContext* ctx,
                                              LEPUSValue thisObj,
                                              LEPUSAtom prop, int idx) {
  if (!LEPUS_IsLepusRef(thisObj)) return LEPUS_UNINITIALIZED;
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "QuickContext::LepusRefGetPropertyCallBack");
  LEPUSLepusRef* pref =
      static_cast<LEPUSLepusRef*>(LEPUS_VALUE_GET_PTR(thisObj));
  const char* name = nullptr;
  switch (pref->tag) {
    case Value_Table: {
      name = LEPUS_AtomToCString(ctx, prop);
      auto* dic = reinterpret_cast<Dictionary*>(pref->p);
      if (!dic->Contains(name)) {
        LEPUS_FreeCString(ctx, name);
        return LEPUS_UNINITIALIZED;
      }
      LEPUSValue ret = (dic->GetValue(name, true)).ToJSValue(ctx);
      LEPUS_FreeCString(ctx, name);
      return ret;
    } break;
    case Value_Array: {
      if (idx >= 0) {
        auto* carray = reinterpret_cast<lepus::CArray*>(pref->p);
        if (static_cast<size_t>(idx) < carray->size()) {
          return (carray->get(idx)).ToJSValue(ctx);
        }
        return LEPUS_UNDEFINED;
      } else {
        LEPUSAtom len_atom = LEPUS_NewAtom(ctx, "length");
        if (len_atom == prop) {
          LEPUS_FreeAtom(ctx, len_atom);
          return LEPUS_NewInt64(
              ctx, static_cast<uint32_t>(
                       (reinterpret_cast<CArray*>(pref->p)->size())));
        }
        LEPUS_FreeAtom(ctx, len_atom);
      }

    } break;
    case Value_JSObject:
    case Value_ByteArray: {
      return LEPUS_UNDEFINED;
    }
    default:
      assert(false);
      break;
  }

  return LEPUS_UNINITIALIZED;
}

static size_t LepusRefGetLengthCallBack(LEPUSContext* ctx, LEPUSValue val) {
  if (!LEPUS_IsLepusRef(val)) return 0;
  LEPUSLepusRef* pref = static_cast<LEPUSLepusRef*>(LEPUS_VALUE_GET_PTR(val));
  if (!LEPUS_IsUndefined(pref->lepus_val))
    return LEPUS_GetLength(ctx, pref->lepus_val);
  switch (pref->tag) {
    case Value_Table:
      return reinterpret_cast<Dictionary*>(pref->p)->size();
    case Value_Array:
      return reinterpret_cast<CArray*>(pref->p)->size();
    default:
      assert(false);
      break;
  }
  return 0;
}

static size_t LepusRefDeepEqualCallBack(LEPUSValue val1, LEPUSValue val2) {
  if (!LEPUS_IsLepusRef(val1) || !LEPUS_IsLepusRef(val2)) return 0;
  if (LEPUS_GetLepusRefTag(val1) != LEPUS_GetLepusRefTag(val2)) return 0;
  int tag = LEPUS_GetLepusRefTag(val1);
  void* pv1 = LEPUS_GetLepusRefPoint(val1);
  void* pv2 = LEPUS_GetLepusRefPoint(val2);
  switch (tag) {
    case Value_Table:
      return *static_cast<Dictionary*>(pv1) == *static_cast<Dictionary*>(pv2);
    case Value_Array:
      return *static_cast<CArray*>(pv1) == *static_cast<CArray*>(pv2);
    case Value_JSObject:
      return *static_cast<LEPUSObject*>(pv1) == *static_cast<LEPUSObject*>(pv2);
    default:
      return 0;
  }
}

static LEPUSValue LepusConvertToObjectCallBack(LEPUSContext* ctx,
                                               LEPUSValue val) {
  if (!LEPUS_IsLepusRef(val)) return val;
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "QuickContext::LepusConvertToObjectCallBack");
  LEPUSLepusRef* pref = static_cast<LEPUSLepusRef*>(LEPUS_VALUE_GET_PTR(val));
  if (!LEPUS_IsUndefined(pref->lepus_val)) {
    return pref->lepus_val;
  }
  Value lepus_val;

  switch (pref->tag) {
    case Value_Table: {
      lepus_val.SetTable(LEPUSValueHelper::GetLepusTable(val));
      break;
    }
    case Value_Array: {
      lepus_val.SetArray(LEPUSValueHelper::GetLepusArray(val));
      break;
    }
    case Value_RefCounted:
      lepus_val.SetUndefined();
      break;
    default:
      assert(false);
      lepus_val.SetUndefined();
      break;
  }

  pref->lepus_val = LEPUSValueHelper::ShallowToJSValue(ctx, lepus_val);
  return pref->lepus_val;
}

static LEPUSValue LepusrefToString(LEPUSContext* ctx, LEPUSValue val) {
  if (!LEPUS_IsLepusRef(val)) return LEPUS_UNDEFINED;
  LEPUSLepusRef* pref = static_cast<LEPUSLepusRef*>(LEPUS_VALUE_GET_PTR(val));
  Value lepus_val;
  std::ostringstream s;
  switch (pref->tag) {
    case Value_Table: {
      return LEPUS_NewString(ctx, "[object Object]");
    }

    case Value_Array: {
      lepus_val.SetArray(reinterpret_cast<CArray*>(pref->p));
      s << lepus_val;
      return LEPUS_NewString(ctx, s.str().c_str());
    }

    case Value_JSObject: {
      return LEPUS_NewString(ctx, "[object JSObject]");
    }

    case Value_ByteArray: {
      return LEPUS_NewString(ctx, "[object ByteArray]");
    }

    default: {
      return LEPUS_NewString(ctx, "");
    }
  }

  return LEPUS_UNDEFINED;
}

static bool HasDebugger(lepus::Context* ctx) {
  if (ctx->GetInspector() && ctx->GetDebugger()) {
    return true;
  }
  return false;
}

static void PrintByALog(char* msg) { LOGE(msg); }

// pause the vm
static void RunMessageLoopOnPauseCallBack(LEPUSContext* ctx) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->DebuggerRunMessageLoopOnPause(lctx);
  }
}

// quit pause
static void QuitMessageLoopOnPauseCallBack(LEPUSContext* ctx) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->DebuggerQuitMessageLoopOnPause(lctx);
  }
}

// get protocol messages from front end when vm is running
static void GetMessagesCallBack(LEPUSContext* ctx) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->DebuggerGetMessages(lctx);
  }
}

// send response to front end
static void SendResponseCallBack(LEPUSContext* ctx, int32_t message_id,
                                 const char* message) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->DebuggerSendResponse(lctx, message_id, message);
  }
}

// callbacks for lepusNG debugger
// send notification to front end
static void SendNotificationCallBack(LEPUSContext* ctx, const char* message) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->DebuggerSendNotification(lctx, message);
  }
}

static void FreeMessagesCallBack(LEPUSContext* ctx, char** messages,
                                 int32_t size) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (lctx->GetInspector()) {
    for (size_t m_i = 0; m_i < static_cast<size_t>(size); m_i++) {
      free(messages[m_i]);
    }
    free(messages);
  }
}

static void InspectorCheckCallBack(LEPUSContext* ctx) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->InspectorCheck(lctx);
  }
}

static void DebuggerExceptionCallBack(LEPUSContext* ctx) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->DebuggerException(lctx);
  }
}

static uint8_t IsRuntimeDevtoolOnCallback(LEPUSRuntime* rt) {
  if (Context::IsDebugEnabled()) {
    return 1;
  } else {
    return 0;
  }
}

static void ConsoleMessage(LEPUSContext* ctx, int tag, LEPUSValueConst* argv,
                           int argc) {
  int i;
  const char* str;
  for (i = 0; i < argc; i++) {
    if (i != 0) putchar(' ');
    str = LEPUS_ToCString(ctx, argv[i]);
    if (!str) return;
    fputs(str, stdout);
    LEPUS_FreeCString(ctx, str);
  }
  putchar('\n');
}

static void SendConsoleMessage(LEPUSContext* ctx, LEPUSValue* console_msg) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->DebuggerSendConsoleMessage(lctx, console_msg);
  }
}

static void SendScriptFailToParseMessage(LEPUSContext* ctx,
                                         LEPUSScriptSource* script) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->DebuggerSendScriptFailToParseMessage(lctx, script);
  }
}

static void SendScriptParsedMessage(LEPUSContext* ctx,
                                    LEPUSScriptSource* script) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  if (HasDebugger(lctx)) {
    lctx->GetDebugger()->DebuggerSendScriptParsedMessage(lctx, script);
  }
}

LEPUSLepusRefCallbacks Context::GetLepusRefCall() {
  return {&LepusRefFreeCallBack,        &LepusRefGetPropertyCallBack,
          &LepusRefGetLengthCallBack,   &LepusConvertToObjectCallBack,
          &LepusRefSetPropertyCallBack, &LepusRefFreeStringCache,
          &LepusRefDeepEqualCallBack,   &LepusrefToString};
}

static void SetFuncsAndRegisterVMSDKCallbacks(LEPUSRuntime* rt) {
  std::vector<void*> funcs = {reinterpret_cast<void*>(PrintByALog)};
  if (!base::LynxEnv::GetInstance().IsDisabledLepusngOptimize()) {
    funcs.insert(funcs.end(),
                 {reinterpret_cast<void*>(LepusHasProperty),
                  reinterpret_cast<void*>(LepusDeleteProperty),
                  reinterpret_cast<void*>(LEPUSValueGetOwnPropertyNames),
                  reinterpret_cast<void*>(LEPUSValueDeepEqualCallBack),
                  reinterpret_cast<void*>(LEPUSRefArrayPushCallBack),
                  reinterpret_cast<void*>(LEPUSRefArrayPopCallBack),
                  reinterpret_cast<void*>(LEPUSRefArrayFindCallBack),
                  reinterpret_cast<void*>(LEPUSRefArrayReverse),
                  reinterpret_cast<void*>(LEPUSRefArraySlice)});
  }
  RegisterVMSDKCallbacks(rt, funcs.data(), static_cast<int32_t>(funcs.size()));
}

static void RegisterDebuggerCallbacks(LEPUSRuntime* rt) {
  if (Context::IsDebugEnabled()) {
    void* funcs[14] = {reinterpret_cast<void*>(RunMessageLoopOnPauseCallBack),
                       reinterpret_cast<void*>(QuitMessageLoopOnPauseCallBack),
                       reinterpret_cast<void*>(GetMessagesCallBack),
                       reinterpret_cast<void*>(SendResponseCallBack),
                       reinterpret_cast<void*>(SendNotificationCallBack),
                       reinterpret_cast<void*>(FreeMessagesCallBack),
                       reinterpret_cast<void*>(DebuggerExceptionCallBack),
                       reinterpret_cast<void*>(InspectorCheckCallBack),
                       reinterpret_cast<void*>(ConsoleMessage),
                       reinterpret_cast<void*>(SendScriptParsedMessage),
                       reinterpret_cast<void*>(SendConsoleMessage),
                       reinterpret_cast<void*>(SendScriptFailToParseMessage),
                       reinterpret_cast<void*>(NULL),
                       reinterpret_cast<void*>(IsRuntimeDevtoolOnCallback)};
    RegisterQJSDebuggerCallbacks(rt, reinterpret_cast<void**>(funcs), 14);
  }
}

LEPUSRuntimeData::LEPUSRuntimeData() {
  runtime_ = LEPUS_NewRuntime();
  LEPUS_SetRuntimeInfo(runtime_, "Lynx_LepusNG");

  RegisterDebuggerCallbacks(runtime_);
  SetFuncsAndRegisterVMSDKCallbacks(runtime_);
  lepus_context_ = LEPUS_NewContext(runtime_);
}

LEPUSRuntimeData::~LEPUSRuntimeData() {
  if (!base::LynxEnv::GetInstance().IsDisableCollectLeak()) {
    CollectLeak();
  }
  ContextCell* cell = Context::GetContextCellFromCtx(lepus_context_);
  LEPUS_FreeContext(lepus_context_);
  cell->ctx_ = nullptr;
  cell->qctx_ = nullptr;
  LEPUS_FreeRuntime(runtime_);
  cell->rt_ = nullptr;
}

bool Context::debug_enabled_ = false;

Context::Context(ContextType type) : type_(type) {}
Context* Context::GetFromJsContext(LEPUSContext* ctx) {
  ContextCell* cell = GetContextCellFromCtx(ctx);
  return cell ? cell->qctx_ : nullptr;
}

std::shared_ptr<Context> Context::CreateContext(bool use_lepusng) {
  if (use_lepusng) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "Context::CreateQuickContext");
    return std::make_shared<QuickContext>();
  } else {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "Context::CreateVMContext");
#if !ENABLE_JUST_LEPUSNG
    return std::make_shared<VMContext>();
#else
    LOGE("lepusng sdk do not support vm context");
    assert(false);
    return NULL;
#endif
  }
}

void Context::ReportError(const std::string& exception_info) {
#ifndef LEPUS_PC
#ifndef BUILD_LEPUS
  auto* tasm = GetTasmPointer();
  if (tasm) {
    tasm->ReportError(ErrCode::LYNX_ERROR_CODE_LEPUS, exception_info);
  }
#endif
#endif
}

void Context::PrintMsgToJS(const std::string& level, const std::string& msg) {
#ifndef LEPUS_PC
#ifndef BUILD_LEPUS
  auto* tasm = GetTasmPointer();

  // We want to redirect lepus console in headless mode, and avoid lepus console
  // appearing in js side.
  // TODO(hongzhiyuan.hzy): Consider move this out in future refactor.
#if defined(MODE_HEADLESS)
  headless::EventEmitter<decltype(tasm), std::string>::GetInstance()->EmitSync(
      tasm, "LepusConsole",
      new std::pair<std::string, std::string>({level, msg}));
  return;
#else
  if (tasm) {
    tasm->PrintMsgToJS(level, msg);
  }
#endif
#endif
#endif
}

CellManager::~CellManager() {
  for (auto* itr : cells_) {
    delete itr;
  }
}

ContextCell* CellManager::AddCell(lepus::QuickContext* qctx) {
  LEPUSContext* ctx = qctx->context();
  ContextCell* ret = new ContextCell(qctx, ctx, LEPUS_GetRuntime(ctx));
  cells_.emplace_back(ret);
  return ret;
}

CellManager& Context::GetContextCells() {
  lynx_thread_local(CellManager) cells_;
  return cells_;
}

ContextCell* Context::RegisterContextCell(lepus::QuickContext* qctx) {
  return GetContextCells().AddCell(qctx);
}

void Context::SetDebugEnabled(bool enable) { debug_enabled_ = enable; }

}  // namespace lepus
}  // namespace lynx
