#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_CONTEXT_WRAPPER_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_CONTEXT_WRAPPER_H_

#include <memory>
#include <string>
#include <unordered_map>

#include "Lynx/jsbridge/quickjs/quickjs_debugger_base.h"
#include "Lynx/lepus/lepus_inspector.h"
#include "jsbridge/jsi/jsi.h"

struct LEPUSContext;
struct LEPUSRuntime;

namespace lynx {
namespace debug {
class QuickjsDebuggerBase;
}

namespace piper {
using RegisterWasmFuncType = void (*)(void*, void*);

using InspectorSessionMap =
    std::unordered_map<int32_t, lepus_inspector::LepusInspectorSession*>;
using EnableMap = std::unordered_map<int32_t, bool[3]>;

class BASE_EXPORT_FOR_DEVTOOL QuickjsContextWrapper : public piper::JSIContext {
 public:
  QuickjsContextWrapper(std::shared_ptr<VMInstance> vm);
  ~QuickjsContextWrapper();

  BASE_EXPORT_FOR_DEVTOOL LEPUSContext* getContext() const;
  LEPUSRuntime* getRuntime() const;

  // debugger related functions
  BASE_EXPORT_FOR_DEVTOOL lepus_inspector::LepusInspectorSession* GetSession(
      int32_t);
  // get all the sessions
  BASE_EXPORT_FOR_DEVTOOL
  const InspectorSessionMap& GetSessions();
  // get session enable state
  const EnableMap& GetEnableMap();
  void SetDebuggerEnableState(int32_t key, bool value);
  void SetRuntimeEnableState(int32_t key, bool value);
  void SetProfilerEnableState(int32_t key, bool value);
  bool GetDebuggerEnableState(int32_t key);
  bool GetRuntimeEnableState(int32_t key);
  bool GetProfilerEnableState(int32_t key);
  BASE_EXPORT_FOR_DEVTOOL lepus_inspector::QJSInspector* GetInspector();
  BASE_EXPORT_FOR_DEVTOOL void ProcessPausedMessages(LEPUSContext* ctx,
                                                     const std::string& message,
                                                     int32_t);
  BASE_EXPORT_FOR_DEVTOOL void SetDebugger(
      std::shared_ptr<debug::QuickjsDebuggerBase> debugger);
  BASE_EXPORT_FOR_DEVTOOL std::shared_ptr<debug::QuickjsDebuggerBase>
  GetDebugger();
  BASE_EXPORT_FOR_DEVTOOL void SetInspector(
      lepus_inspector::QJSInspector* inspector);
  BASE_EXPORT_FOR_DEVTOOL void SetSession(
      int32_t, lepus_inspector::LepusInspectorSession* session);
  static QuickjsContextWrapper* GetFromJsContext(LEPUSContext* ctx);
  // clear all the sessions
  BASE_EXPORT_FOR_DEVTOOL void ClearSessions();
  // remove session by view id
  BASE_EXPORT_FOR_DEVTOOL void RemoveSession(int32_t view_id);
  // for shared context qjs debugger
  BASE_EXPORT_FOR_DEVTOOL void PrepareQJSDebugger();
  // set context pause state
  void set_paused(bool paused);
  // get context pause state
  bool paused();

  static RegisterWasmFuncType& RegisterWasmFunc();

  static RegisterWasmFuncType register_wasm_func_;

 private:
  LEPUSContext* ctx_;

  // for quickjs debugtger
  lepus_inspector::QJSInspector* inspector_;
  std::shared_ptr<debug::QuickjsDebuggerBase> quickjs_debugger_;
  // sessions, key: view_id, value: session
  InspectorSessionMap sessions_;
  // session enable state map: key: view_id, value: is enabled:
  // Debugger/Runtime/Profiler
  EnableMap session_enable_map_;
  bool paused_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_CONTEXT_WRAPPER_H_
