#include "jsbridge/quickjs/quickjs_context_wrapper.h"

#include <climits>

#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/quickjs/quickjs_context_wrapper_callbacks.h"
#include "jsbridge/quickjs/quickjs_helper.h"
#include "jsbridge/quickjs/quickjs_runtime_wrapper.h"

namespace lynx {
namespace piper {

// get sessions
const InspectorSessionMap& QuickjsContextWrapper::GetSessions() {
  return sessions_;
}

// get debugger enable map
const EnableMap& QuickjsContextWrapper::GetEnableMap() {
  return session_enable_map_;
}

// set debugger enable state
void QuickjsContextWrapper::SetDebuggerEnableState(int32_t key, bool value) {
  session_enable_map_[key][0] = value;
}

// set runtime enable state
void QuickjsContextWrapper::SetRuntimeEnableState(int32_t key, bool value) {
  session_enable_map_[key][1] = value;
}

// set profiler enable state
void QuickjsContextWrapper::SetProfilerEnableState(int32_t key, bool value) {
  session_enable_map_[key][2] = value;
}

// get debugger enable state
bool QuickjsContextWrapper::GetDebuggerEnableState(int32_t key) {
  return session_enable_map_[key][0];
}

// get runtime enable state
bool QuickjsContextWrapper::GetRuntimeEnableState(int32_t key) {
  return session_enable_map_[key][1];
}

// get profiler enable state
bool QuickjsContextWrapper::GetProfilerEnableState(int32_t key) {
  return session_enable_map_[key][2];
}

// get session
lepus_inspector::LepusInspectorSession* QuickjsContextWrapper::GetSession(
    int32_t view_id) {
  return sessions_[view_id];
}

// get inspector
lepus_inspector::QJSInspector* QuickjsContextWrapper::GetInspector() {
  return inspector_;
}

// set inspector
void QuickjsContextWrapper::SetInspector(
    lepus_inspector::QJSInspector* inspector) {
  inspector_ = inspector;
}

// set session
void QuickjsContextWrapper::SetSession(
    int32_t view_id, lepus_inspector::LepusInspectorSession* session) {
  sessions_[view_id] = session;
  for (size_t i = 0; i < 3; i++) {
    session_enable_map_[view_id][i] = false;
  }
}

// remove session by view id
void QuickjsContextWrapper::RemoveSession(int32_t view_id) {
  sessions_.erase(view_id);
  session_enable_map_.erase(view_id);
}

// clear all the sessions
void QuickjsContextWrapper::ClearSessions() {
  sessions_.clear();
  session_enable_map_.clear();
}

// set debugger and initialize debugger related data structure
void QuickjsContextWrapper::SetDebugger(
    std::shared_ptr<debug::QuickjsDebuggerBase> debugger) {
  quickjs_debugger_ = debugger;
  if (quickjs_debugger_) {
    quickjs_debugger_->DebuggerInitialize(ctx_);
  }
}

// get debugger
std::shared_ptr<debug::QuickjsDebuggerBase>
QuickjsContextWrapper::GetDebugger() {
  return quickjs_debugger_;
}

// process protocol messages when vm is paused
void QuickjsContextWrapper::ProcessPausedMessages(LEPUSContext* ctx,
                                                  const std::string& message,
                                                  int32_t view_id) {
  if (quickjs_debugger_) {
    quickjs_debugger_->ProcessPausedMessages(ctx, message, view_id);
  }
}

// register debugger related function callbacks
static void RegisterQJSDebuggerCallbacks(LEPUSRuntime* rt) {
  // register quickjs debugger related callback functions
  int32_t callback_size = 0;
  void** funcs = GetQJSCallbackFuncs(callback_size);
  RegisterQJSDebuggerCallbacks(rt, funcs, callback_size);
  free(funcs);
}

// for shared context qjs debugger
void QuickjsContextWrapper::PrepareQJSDebugger() {
  int32_t callback_size = 0;
  void** funcs = GetQJSCallbackFuncs(callback_size);
  PrepareQJSDebuggerForSharedContext(
      ctx_, funcs, callback_size,
      base::LynxEnv::GetInstance().IsDevtoolConnected());
  free(funcs);
}

QuickjsContextWrapper::QuickjsContextWrapper(std::shared_ptr<VMInstance> vm)
    : JSIContext(vm), paused_(false) {
  std::shared_ptr<QuickjsRuntimeInstance> iso =
      std::static_pointer_cast<QuickjsRuntimeInstance>(vm);

  LEPUSRuntime* rt = iso->Runtime();

  // if in quickjs debugger mode, register debugger related function
  if (base::LynxEnv::GetInstance().IsDevtoolEnabled() && IsQuickjsDebugOn()) {
    RegisterQJSDebuggerCallbacks(rt);
  }

  LEPUSContext* ctx;
  ctx = LEPUS_NewContext(rt);
  if (!ctx) {
    LOGR("init quickjs context failed!");
    return;
  }
  ctx_ = ctx;
  // register webassembly here, on ctx.global
  RegisterWasmFunc()(ctx, nullptr);

  LEPUS_SetMaxStackSize(ctx_, static_cast<size_t>(ULLONG_MAX));
  LEPUS_SetContextOpaque(ctx_, this);
}

QuickjsContextWrapper* QuickjsContextWrapper::GetFromJsContext(
    LEPUSContext* ctx) {
  return reinterpret_cast<QuickjsContextWrapper*>(LEPUS_GetContextOpaque(ctx));
}

QuickjsContextWrapper::~QuickjsContextWrapper() {
  if (ctx_) {
    LEPUS_FreeContext(ctx_);
  }
  LOGI("~QuickjsContextWrapper " << this << " LEPUSContext:" << ctx_);
}

LEPUSRuntime* QuickjsContextWrapper::getRuntime() const {
  std::shared_ptr<QuickjsRuntimeInstance> vm =
      std::static_pointer_cast<QuickjsRuntimeInstance>(vm_);
  return vm->Runtime();
}

LEPUSContext* QuickjsContextWrapper::getContext() const { return ctx_; }

void QuickjsContextWrapper::set_paused(bool paused) { paused_ = paused; }

bool QuickjsContextWrapper::paused() { return paused_; }

// static
RegisterWasmFuncType QuickjsContextWrapper::register_wasm_func_ = [](void*,
                                                                     void*) {};
// static
RegisterWasmFuncType& QuickjsContextWrapper::RegisterWasmFunc() {
  static RegisterWasmFuncType RegisterWebAssembly = register_wasm_func_;
  return RegisterWebAssembly;
}

}  // namespace piper
}  // namespace lynx
