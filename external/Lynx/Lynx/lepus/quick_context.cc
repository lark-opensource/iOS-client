// Copyright 2019 The Lynx Authors. All rights reserved.
#include "lepus/quick_context.h"

#include <assert.h>

#include "base/debug/error_code.h"
#include "base/lynx_env.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/array.h"
#include "lepus/exception.h"
#include "lepus/jsvalue_helper.h"
#include "lepus/path_parser.h"
#include "lepus/table.h"
#include "lepus/value.h"
#include "lepus_error_helper.h"
#include "tasm/lynx_trace_event.h"

#if ENABLE_CLI
#include "lepus/context_binary_writer.h"
#endif

#ifndef LEPUS_PC
#ifndef BUILD_LEPUS
#include "tasm/template_assembler.h"
#endif
#endif
#include "base/string/string_number_convert.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace lepus {
#define RENDERER_FUNCTION(name)                                       \
  static LEPUSValue name(LEPUSContext* ctx, LEPUSValueConst this_val, \
                         int argc, LEPUSValueConst* argv)

static std::string GetPrintStr(LEPUSContext* ctx, int32_t argc,
                               LEPUSValueConst* argv) {
  std::ostringstream ss;
  for (int32_t i = 0; i < argc; i++) {
    lepus::Value(ctx, argv[i]).PrintValue(ss);
    if (i < argc - 1) {
      ss << " ";
    }
  }
  return ss.str();
}

RENDERER_FUNCTION(Console_Log) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  std::string result = GetPrintStr(ctx, argc, argv);
  lctx->PrintMsgToJS("log", "lepus-console: " + result);

#if defined(LEPUS_PC)
  LOGI("lepus-console: " + result);
#endif
  return LEPUS_UNDEFINED;
}

RENDERER_FUNCTION(Console_Profile) {
  if (argc == 0) {
    return LEPUS_UNDEFINED;
  }
  std::ostringstream ss;
  ss << "Lepus::";
  lepus::Value(ctx, argv[0]).PrintValue(ss);

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, nullptr,
                    [&](lynx::perfetto::EventContext ctx) {
                      ctx.event()->set_name(ss.str());
                    });

  return LEPUS_UNDEFINED;
}

RENDERER_FUNCTION(Console_ProfileEnd) {
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

  return LEPUS_UNDEFINED;
}

RENDERER_FUNCTION(Console_ALog) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  std::string result = GetPrintStr(ctx, argc, argv);
  lctx->PrintMsgToJS("alog", "lepus-console: " + result);
  return LEPUS_UNDEFINED;
}

RENDERER_FUNCTION(Console_Report) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  std::string result = GetPrintStr(ctx, argc, argv);
  lctx->PrintMsgToJS("report", "lepus-console: " + result);
  return LEPUS_UNDEFINED;
}
RENDERER_FUNCTION(Console_Error) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  std::string result = GetPrintStr(ctx, argc, argv);
  lctx->PrintMsgToJS("error", "lepus-console: " + result);
  const std::string result_msg = "console.error: \n\n" + result;
  lctx->ReportErrorWithMsg(result_msg, ErrCode::LYNX_ERROR_CODE_LEPUS);
  return LEPUS_UNDEFINED;
}

RENDERER_FUNCTION(Console_Warn) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  std::string result = GetPrintStr(ctx, argc, argv);
  lctx->PrintMsgToJS("warn", "lepus-console: " + result);
  return LEPUS_UNDEFINED;
}

RENDERER_FUNCTION(Console_Debug) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  std::string result = GetPrintStr(ctx, argc, argv);
  lctx->PrintMsgToJS("debug", "lepus-console: " + result);
  return LEPUS_UNDEFINED;
}

RENDERER_FUNCTION(Console_Info) {
  lepus::Context* lctx = lepus::Context::GetFromJsContext(ctx);
  std::string result = GetPrintStr(ctx, argc, argv);
  lctx->PrintMsgToJS("info", "lepus-console: " + result);
  return LEPUS_UNDEFINED;
}

void RegisterQuickCFun(QuickContext* ctx, LEPUSValue& obj, const char* name,
                       int argc, LEPUSCFunction* func) {
  LEPUSValue cf = LEPUS_NewCFunction(ctx->context(), func, name, argc);
  LEPUSValueHelper::SetProperty(ctx->context(), obj, name, cf);
}

void RegisterConsole(QuickContext* ctx) {
  LEPUSValue obj = LEPUS_NewObject(ctx->context());
  RegisterQuickCFun(ctx, obj, "profile", 1, Console_Profile);
  RegisterQuickCFun(ctx, obj, "profileEnd", 0, Console_ProfileEnd);
  RegisterQuickCFun(ctx, obj, "log", 1, Console_Log);
  RegisterQuickCFun(ctx, obj, "alog", 1, Console_ALog);
  RegisterQuickCFun(ctx, obj, "report", 1, Console_Report);
  RegisterQuickCFun(ctx, obj, "info", 1, Console_Info);
  RegisterQuickCFun(ctx, obj, "warn", 1, Console_Warn);
  RegisterQuickCFun(ctx, obj, "error", 1, Console_Error);
  RegisterQuickCFun(ctx, obj, "debug", 1, Console_Debug);
  ctx->RegisterGlobalProperty("console", obj);
}

QuickContext::QuickContext()
    : Context(ContextType::LepusNGContextType),
      top_level_function_(LEPUS_UNDEFINED),
      use_lepus_strict_mode_(false),
      debug_source_(""),
      end_line_num_(-1),
      lepusng_finished_(false),
      debuginfo_outside_(false) {
  LEPUSLepusRefCallbacks callbacks = Context::GetLepusRefCall();
  RegisterLepusRefCallbacks(runtime_, &callbacks);
  LEPUS_SetMaxStackSize(context(), static_cast<size_t>(ULLONG_MAX));
  LEPUS_SetContextOpaque(lepus_context_, Context::RegisterContextCell(this));
  Initialize();
  RegisterLepusType(runtime_, Value_Array, Value_Table);
  // data associated with debugger need to be initialized
  DebugDataInitialize();
}

QuickContext::~QuickContext() {
  if (!LEPUS_IsUndefined(top_level_function_)) {
    LEPUS_FreeValue(context(), top_level_function_);
  }
  if (debugger_base_) {
    debugger_base_->DebuggerFree(this);
  }
}

void QuickContext::ReportErrorWithMsg(const std::string& msg,
                                      const std::string& stack,
                                      int32_t error_code) {
#ifndef LEPUS_PC
#ifndef BUILD_LEPUS
  auto formatted_message = FormatExceptionMessage(msg, stack, "");
  ReportErrorWithMsg(formatted_message, error_code);
#endif
#endif
}

void QuickContext::ReportErrorWithMsg(const std::string& msg,
                                      int32_t error_code) {
#ifndef LEPUS_PC
#ifndef BUILD_LEPUS
  // enable outside debug information only when targetSdkVersion is bigger than
  // "2.7" and "debuginfo_outside_" is true when encode
  auto* tasm = GetTasmPointer();
  if (!tasm) {
    return;
  }
  const std::string target_sdk_version = tasm->TargetSdkVersion();
  if (tasm::Config::IsHigherOrEqual(target_sdk_version, LYNX_VERSION_2_7) &&
      debuginfo_outside_) {
    tasm->ReportLepusNGError(error_code, msg);
  } else {
    ReportError(msg);
  }
#endif
#endif
}

void QuickContext::DebugDataInitialize() {
  debugger_base_ = nullptr;
  inspector_ = nullptr;
  session_ = nullptr;
}

QuickContext* QuickContext::Cast(Context* context) {
  assert(context->IsLepusNGContext());
  return static_cast<QuickContext*>(context);
}

void QuickContext::Initialize() {
  // if in lepusNG debug mode, use debug protocol to display console.xxx
  // messages
  if (!IsDebugEnabled()) {
    RegisterConsole(this);
  }
  RegisterLepusVerion();
}

void QuickContext::RegisterLepusVerion() {
  LEPUSContext* ctx = context();
  LEPUSAtom atom = LEPUS_NewAtom(ctx, "__lepus_version__");
  LEPUSValue global_obj = LEPUS_GetGlobalObject(ctx);
  LEPUS_DefinePropertyValue(ctx, global_obj, atom,
                            LEPUS_NewString(ctx, LYNX_LEPUS_VERSION),
                            LEPUS_PROP_ENUMERABLE);
  LEPUS_FreeAtom(ctx, atom);
  LEPUS_FreeValue(ctx, global_obj);
}

void QuickContext::SetTopLevelFunction(LEPUSValue val) {
  if (!LEPUS_IsUndefined(top_level_function_)) {
    LEPUS_FreeValue(context(), top_level_function_);
  }

  top_level_function_ = val;
  if (debugger_base_) {
    debugger_base_->PrepareDebugInfo();
  }
}

bool QuickContext::HasFinishedExecution() { return lepusng_finished_; }

void QuickContext::SetDebuggerSourceAndEndLine(const std::string& source) {
  debug_source_ = source;
  int32_t line = 0;
  // compute end line num
  for (const auto& ch : source) {
    if (ch == '\n') {
      line++;
    }
  }
  if (line > 0) {
    // line number start from 0
    line = line - 1;
  }
  end_line_num_ = line;
}

LEPUSValue QuickContext::GetTopLevelFunction() { return top_level_function_; }

const std::string QuickContext::Compile(const std::string& source,
                                        const char* sdk_version) {
#if ENABLE_CLI || ENABLE_HMR
  if (sdk_version) {
    sdk_version_ = sdk_version;
  }
  if (debuginfo_outside_) {
    SetLynxTargetSdkVersion(context(), sdk_version_.c_str());
  }

  int eval_flags;
  LEPUSValue obj;

  SetDebuggerSourceAndEndLine(source);
  eval_flags = LEPUS_EVAL_FLAG_COMPILE_ONLY | LEPUS_EVAL_TYPE_GLOBAL;
  obj = LEPUS_Eval(context(), source.data(), source.length(), "", eval_flags);
  if (LEPUS_IsException(obj)) {
    std::string exception_message = "compile error: " + GetExceptionMessage();
    LOGE(exception_message);
    return exception_message;
  }

  SetTopLevelFunction(obj);
#endif
  return std::string();
}

void QuickContext::SetEnableStrictCheck(bool val) {
  use_lepus_strict_mode_ = val;
}

void QuickContext::SetStackSize(uint32_t stack_size) {
  stack_size_ = stack_size;
  if (stack_size_ > 0) {
    LEPUS_SetVirtualStackSize(context(), stack_size_);
  }
}

bool QuickContext::Execute(Value* ret_val) {
  if (LEPUS_IsUndefined(top_level_function_)) {
    LOGE("no compiled function object");
    return false;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LEPUS_NG_EXECUTE);

  lepusng_finished_ = false;
  if (!use_lepus_strict_mode_) {
    LEPUS_SetNoStrictMode(context());
  }
  // dup function object to avoid free
  // it will free when :
  // 1. compile other top level function
  // 2. QuickContext was destruct
  LEPUS_DupValue(context(), top_level_function_);
  LEPUSValue global = LEPUS_GetGlobalObject(context());
  LEPUSValue ret = LEPUS_EvalFunction(context(), top_level_function_, global);
  LEPUS_FreeValue(context(), global);
  if (LEPUS_IsException(ret)) {
    constexpr const static char* kErrorPrefix =
        "QuickContext::Execute() exception!!!\n";
    const std::string log = GetExceptionMessage(kErrorPrefix);
    LOGE("Run error:\n" << log);
    ReportErrorWithMsg(log, ErrCode::LYNX_ERROR_CODE_LEPUS);
  }
  if (ret_val) {
    *ret_val = Value(lepus_context_, ret);
  } else {
    LEPUS_FreeValue(context(), ret);
  }
  lepusng_finished_ = true;
  return true;
}

Value QuickContext::Call(const std::string& name,
                         const std::vector<lepus::Value>& args) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, nullptr,
              [&](lynx::perfetto::EventContext ctx) {
                ctx.event()->set_name("QuickContext::Call:" + name);
              });
  std::vector<LEPUSValue> quick_args(args.size());
  decltype(quick_args.size()) i = 0;
  for (auto& it : args) {
    quick_args[i++] = it.ToJSValue((lepus_context_));
  }
  Value ret(lepus_context_, GetAndCall(name, quick_args));
  for (auto it : quick_args) {
    LEPUS_FreeValue(lepus_context_, it);
  }
  return ret;
}

Value QuickContext::CallWithClosure(const lepus::Value& closure,
                                    const std::vector<lepus::Value>& args) {
  LEPUSValue lepus_closure = closure.ToJSValue(lepus_context_);
  DCHECK(LEPUSValueHelper::IsJsFunction(lepus_context_, lepus_closure));
  std::vector<LEPUSValue> quick_args(args.size());
  decltype(args.size()) i = 0;
  for (auto& it : args) {
    quick_args[i++] = it.ToJSValue(lepus_context_);
  }

  Value ret(lepus_context_, InternalCall(lepus_closure, quick_args));
  for (auto it : quick_args) {
    LEPUS_FreeValue(context(), it);
  }
  LEPUS_FreeValue(lepus_context_, lepus_closure);
  return ret;
}

long QuickContext::GetParamsSize() {
  assert(false);
  return 0;
}

Value* QuickContext::GetParam(long index) {
  assert(false);
  return nullptr;
}

const std::string& QuickContext::name() const { return name_; }

bool QuickContext::CheckTableShadowUpdatedWithTopLevelVariable(
    const lepus::Value& update) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "QuickContext::CheckTableShadowUpdatedWithTopLevelVariable");
  bool enable_deep_check = false;
#if ENABLE_INSPECTOR && LYNX_ENABLE_TRACING
  if (lynx::base::LynxEnv::GetInstance().IsTableDeepCheckEnabled()) {
    enable_deep_check = true;
  }
#endif
  auto update_type = update.Type();
  if (update_type != ValueType::Value_Table) {
    return true;
  }
  // page new data from setData
  auto update_table_value = update.Table();
  // shadow compare new_data_table && top level
  // if any top level data are different, need update;
  for (auto& update_data_iterator : *update_table_value) {
    auto key = update_data_iterator.first.str();
    auto val = update_data_iterator.second;
    auto result = ParseValuePath(key);
    if (result.empty()) {
      return true;
    }
    auto front_value = result.begin();
    LEPUSAtom atom = LEPUS_NewAtom(context(), front_value->c_str());
    Value value(lepus_context_, LEPUS_GetGlobalVar(context(), atom, false));
    result.erase(front_value);
    for (auto it = begin(result); it != end(result); ++it) {
      if (value.IsTable()) {
        auto key = it->c_str();
        if (!value.Table()->Contains(key)) {
          // target table did not have this new key
          LEPUS_FreeAtom(context(), atom);
          return true;
        }
        value = (value.Table()->GetValue(key));
      } else if (value.IsArray()) {
        int index;
        if (lynx::base::StringToInt(*it, &index, 10)) {
          if (static_cast<size_t>(index) >= value.Array()->size()) {
            // the array's size is smaller.
            LEPUS_FreeAtom(context(), atom);
            return true;
          }
          value = value.Array()->get(index);
        }
      }
    }

    if (value.IsUndefined() || value.IsJSUndefined() || value.IsNil()) {
      LEPUS_FreeAtom(context(), atom);
      return true;
    }
    if (!enable_deep_check &&
        tasm::CheckTableValueNotEqual(value.ToLepusValue(), val)) {
      LEPUS_FreeAtom(context(), atom);
      return true;
    }
#if ENABLE_INSPECTOR && LYNX_ENABLE_TRACING
    if (enable_deep_check &&
        tasm::CheckTableDeepUpdated(value.ToLepusValue(), val, false)) {
      LEPUS_FreeAtom(context(), atom);
      return true;
    }
#endif
    LEPUS_FreeAtom(context(), atom);
  }
  return false;
}

bool QuickContext::UpdateTopLevelVariable(const std::string& name,
                                          const lepus::Value& val) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "QuickContext::UpdateTopLevelVariable");
  auto result = ParseValuePath(name);
  if (!result.empty()) {
    // for performance.
    if (result.size() == 1) {
      LEPUSAtom atom = LEPUS_NewAtom(context(), name.c_str());
      LEPUSValue lepus_val = val.ToJSValue(lepus_context_);
      int ret = LEPUS_SetGlobalVar(context(), atom, lepus_val, 2);
      LEPUS_FreeAtom(context(), atom);
      return ret >= 0;
    }
    auto front_value = result.begin();
    LEPUSAtom atom = LEPUS_NewAtom(context(), front_value->c_str());
    Value value(lepus_context_, LEPUS_GetGlobalVar(context(), atom, false));
    if (value.IsUndefined() || value.IsJSUndefined() || value.IsNil()) {
      LEPUS_FreeAtom(context(), atom);
      return false;
    }
    result.erase(front_value);
    lepus::Value::UpdateValueByPath(value, val, result);
    LEPUSValue lepus_val_new = value.ToJSValue(lepus_context_);
    int ret = LEPUS_SetGlobalVar(context(), atom, lepus_val_new, 2);
    LEPUS_FreeAtom(context(), atom);
    return ret >= 0;
  }
  return false;
}

void QuickContext::ResetTopLevelVariable() {
  // TODO(nihao) lepus NG support reset top var.
}

void QuickContext::ResetTopLevelVariableByVal(const Value& val) {
  // TODO(nihao) lepus NG support reset top var.
}

std::unique_ptr<lepus::Value> QuickContext::GetTopLevelVariable(
    bool ignore_callable) {
  // assert(false);
  LOGE("GetTopLevelVariable.... \n");
  return std::make_unique<lepus::Value>();
}

LEPUSValue QuickContext::GetProperty(const std::string& name,
                                     LEPUSValue this_obj) {
  LEPUSAtom atom = LEPUS_NewAtom(context(), name.c_str());
  LEPUSValue ret = LEPUS_GetProperty(context(), this_obj, atom);
  LEPUS_FreeAtom(context(), atom);
  if (LEPUS_IsException(ret)) return LEPUS_UNDEFINED;
  return ret;
}

bool QuickContext::GetTopLevelVariableByName(const std::string& name,
                                             lepus::Value* ret) {
  LEPUSAtom atom = LEPUS_NewAtom(context(), name.c_str());
  Value variable(context(), LEPUS_GetGlobalVar(context(), atom, false));
  LEPUS_FreeAtom(context(), atom);
  if (variable.IsEmpty()) {
    return false;
  }
  *ret = variable;
  return true;
}

void QuickContext::SetGlobalData(const String& name, const Value& value) {
  RegisterGlobalProperty(name.c_str(), value.ToJSValue(context()));
}

void QuickContext::SetGCThreshold(int64_t threshold) {
  LEPUS_SetGCThreshold(runtime_, threshold);
}

LEPUSValue QuickContext::GetAndCall(const std::string& name,
                                    const std::vector<LEPUSValue>& args) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "QuickContext::GetAndCall");
  LEPUSAtom name_atom = LEPUS_NewAtom(context(), name.c_str());
  LEPUSValue caller = LEPUS_GetGlobalVar(context(), name_atom, 0);
  LEPUSValue ret = InternalCall(caller, args);
  LEPUS_FreeAtom(context(), name_atom);
  LEPUS_FreeValue(context(), caller);
  return ret;
}

std::string QuickContext::FormatExceptionMessage(const std::string& message,
                                                 const std::string& stack,
                                                 const std::string& prefix) {
  std::string ret(prefix);
  ret = ret + "lepusng exception: ";
  ret += message;

  ret += " backtrace:\n";
  ret += stack;

  if (template_debug_url_ != "") {
    // add template_debug.json url to backtrace info
    ret += "\ntemplate_debug_url:" + template_debug_url_;
  }
  return ret;
}

// private
std::string QuickContext::GetExceptionMessage(const char* prefix) {
  LEPUSValue exception_val = LEPUS_GetException(context());

  auto message = LepusErrorHelper::GetErrorMessage(context(), exception_val);
  auto stack = LepusErrorHelper::GetErrorStack(context(), exception_val);

  return FormatExceptionMessage(message, stack, prefix);
}

void QuickContext::SetProperty(const char* name, LEPUSValue obj,
                               LEPUSValue val) {
  LEPUSValueHelper::SetProperty(lepus_context_, obj, name, val);
}

void QuickContext::RegisterGlobalProperty(const char* name, LEPUSValue val) {
  LEPUSAtom name_atom = LEPUS_NewAtom(context(), name);
  LEPUS_SetGlobalVar(context(), name_atom, val, 0);

  LEPUS_FreeAtom(context(), name_atom);
}

void QuickContext::RegisterGlobalFunction(const char* name,
                                          LEPUSCFunction* func, int argc) {
  LEPUSValue c_func = LEPUS_NewCFunction(context(), func, name, argc);
  RegisterGlobalProperty(name, c_func);
}

#if ENABLE_CLI
void QuickContext::Serialize(ContextBinaryWriter* writer) {
  size_t out_buf_len;
  uint8_t* out_buf = LEPUS_WriteObject(
      context(), &out_buf_len, top_level_function_, LEPUS_WRITE_OBJ_BYTECODE);
  writer->WriteU64Leb128(static_cast<uint64_t>(out_buf_len));
  writer->WriteData(out_buf, out_buf_len, "quick bytecode");
  lepus_free(context(), out_buf);
}

const std::string& QuickContext::GetDebugSourceCode() { return debug_source_; }

int32_t QuickContext::GetDebugEndLineNum() { return end_line_num_; }
#endif

LEPUSValue QuickContext::SearchGlobalData(const std::string& name) {
  LEPUSAtom name_atom = LEPUS_NewAtom(context(), name.c_str());
  LEPUSValue lepus_val = LEPUS_GetGlobalVar(context(), name_atom, 0);
  LEPUS_FreeAtom(context(), name_atom);
  return lepus_val;
}

bool QuickContext::DeSerialize(const uint8_t* buf, uint64_t size) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LEPUS_NG_DESERIALIZE);
  LEPUSValue val = LEPUS_EvalBinary(context(), buf, static_cast<size_t>(size),
                                    LEPUS_EVAL_BINARY_LOAD_ONLY);
  if (LEPUS_IsException(val)) {
    std::string msg = GetExceptionMessage();
    LOGE("QuickContext deserialize error " << msg);
    return false;
  }

  SetTopLevelFunction(val);
  return true;
}

bool QuickContext::EvalBinary(const uint8_t* buf, uint64_t size, Value* ret) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LEPUS_NG_EVAL_BINARY);
  LEPUSValue val = LEPUS_EvalBinary(context(), buf, static_cast<size_t>(size),
                                    LEPUS_EVAL_BINARY_LOAD_ONLY);
  if (LEPUS_IsException(val)) {
    std::string msg = GetExceptionMessage();
    LOGE("QuickContext EvalBinary error: " << msg);
    return false;
  }
  LEPUSValue top_level_function =
      LEPUS_DupValue(context(), top_level_function_);
  SetTopLevelFunction(val);
  Execute(ret);
  top_level_function_ = top_level_function;
  LEPUS_FreeValue(context(), val);
  return true;
}

LEPUSValue QuickContext::InternalCall(LEPUSValue caller,
                                      const std::vector<LEPUSValue>& args) {
  LEPUSValue global = LEPUS_GetGlobalObject(context());
  LEPUSValue ret =
      LEPUS_Call(context(), caller, global, static_cast<int>(args.size()),
                 const_cast<LEPUSValue*>(args.data()));
  if (LEPUS_IsException(ret)) {
    const std::string log = GetExceptionMessage();
    LOGE(" Call exception: " << log);
    ReportErrorWithMsg(log, ErrCode::LYNX_ERROR_CODE_LEPUS);
    LEPUS_FreeValue(context(), global);
    return LEPUS_UNDEFINED;
  }
  LEPUS_FreeValue(context(), global);

  return ret;
}

tasm::TemplateAssembler* QuickContext::GetTasmPointer() {
  if (tasm_pointer_ != nullptr) {
    return tasm_pointer_;
  }
#ifndef LEPUS_PC
#ifndef BUILD_LEPUS
  LEPUSValue tasm_pointer_value = SearchGlobalData("$kTemplateAssembler");
  if (LEPUSValueHelper::IsJSCpointer(tasm_pointer_value)) {
    tasm_pointer_ = reinterpret_cast<tasm::TemplateAssembler*>(
        LEPUSValueHelper::JSCpointer(tasm_pointer_value));
    LEPUS_FreeValue(context(), tasm_pointer_value);
    return tasm_pointer_;
  }
  LEPUS_FreeValue(context(), tasm_pointer_value);
#endif
#endif
  LOGE("Not Found TemplateAssembler Instance");
  return nullptr;
}

void QuickContext::ReportSetConstValueError(const lepus::Value& val,
                                            LEPUSValue prop, int32_t idx) {
  std::stringstream ss;
  ss << "Set const Value's property in lepusng\n\nThe property is ";
  if (idx < 0) {
    ss << "\"" << lepus::Value(lepus_context_, prop).ToString() << "\"";
  } else {
    ss << "[" << idx << "]";
  }
  ss << ".\nThe const Value's "
        "content is :";
  val.PrintValue(ss);
  ReportErrorWithMsg(ss.str(), ErrCode::LYNX_ERROR_CODE_LEPUS);
}

// for lepusNG debugger
lepus_inspector::LepusInspectorSession* QuickContext::GetSession() {
  return session_;
}

lepus_inspector::LepusInspector* QuickContext::GetInspector() {
  return inspector_;
}

void QuickContext::SetInspector(lepus_inspector::LepusInspector* inspector) {
  inspector_ = inspector;
}

void QuickContext::SetSession(lepus_inspector::LepusInspectorSession* session) {
  session_ = session;
}

void QuickContext::SetDebugger(std::shared_ptr<DebuggerBase> debugger) {
  debugger_base_ = debugger;
  if (debugger_base_) {
    debugger_base_->DebuggerInitialize(this);
    debugger_base_->PrepareDebugInfo();
  }
}

std::shared_ptr<DebuggerBase> QuickContext::GetDebugger() {
  return debugger_base_;
}

void QuickContext::ProcessPausedMessages(lepus::Context* context,
                                         const std::string& message) {
  if (debugger_base_) {
    debugger_base_->ProcessPausedMessages(context, message);
  }
}

void QuickContext::set_debuginfo_outside(bool val) {
  debuginfo_outside_ = true;
}

bool QuickContext::debuginfo_outside() { return debuginfo_outside_; }

}  // namespace lepus
}  // namespace lynx
