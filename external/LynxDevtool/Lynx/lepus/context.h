// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_CONTEXT_H_
#define LYNX_LEPUS_CONTEXT_H_

#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

#include "lepus/debugger_base.h"
#include "lepus/lepus_global.h"
#include "lepus/lepus_string.h"
#include "lepus/value-inl.h"

namespace lepus_inspector {
class LepusInspectorSession;
class LepusInspector;
}  // namespace lepus_inspector

struct LEPUSRuntime;
struct LEPUSContext;

namespace lynx {

namespace tasm {
class TemplateAssembler;
}

namespace lepus {
class StringTable;

class LEPUSRuntimeData {
 public:
  LEPUSRuntimeData();
  ~LEPUSRuntimeData();

  LEPUSRuntime* runtime_;
  LEPUSContext* lepus_context_;
};

enum ContextType {
  VMContextType,       // Run low level version lepus with VmContext
  LepusNGContextType,  // Run lepusNG with qucikjs code
  LepusContextType     // Run low level version lepus with LepusNG
};

enum ValueState {
  kNotTraversed,      // array/tabel hasn't be traversed
  kCollected,         // array/tabel is in circle and can be collected
  kCircleWithRef,     // array/tabel is in circle but can't be collected
  kNotCircleWithRef,  // array/tabel isn't in circle and can't be collected
  kOther
};

class Context {
 public:
  virtual ~Context() {}
  Context(ContextType type);
  // virtual interface
  virtual void Initialize() = 0;
  // align to the default value "null"
  virtual const std::string Compile(const std::string& source,
                                    const char* sdk_version = "null") = 0;
  virtual bool Execute(Value* ret = nullptr) = 0;

  virtual bool UpdateTopLevelVariable(const std::string& name,
                                      const Value& val) = 0;
  // shadow equal for table
  virtual bool CheckTableShadowUpdatedWithTopLevelVariable(
      const lepus::Value& update) = 0;

  virtual void ResetTopLevelVariable() = 0;
  virtual void ResetTopLevelVariableByVal(const Value& val) = 0;

  virtual Value CallWithClosure(const lepus::Value& closure,
                                const std::vector<lepus::Value>& args) = 0;
  virtual Value Call(const std::string& name,
                     const std::vector<Value>& args) = 0;
  virtual std::unique_ptr<Value> GetTopLevelVariable(
      bool ignore_callable = false) = 0;
  virtual bool GetTopLevelVariableByName(const std::string& name,
                                         lepus::Value* ret) = 0;

  virtual long GetParamsSize() = 0;
  virtual Value* GetParam(long index) = 0;
  virtual tasm::TemplateAssembler* GetTasmPointer() = 0;
  virtual void SetGlobalData(const String& name, const Value& value) = 0;

  virtual void SetGCThreshold(int64_t threshold){};

  virtual const std::string& name() const { return name_; }

  virtual void ReportErrorWithMsg(const std::string& msg, int32_t error_code){};
  virtual void ReportErrorWithMsg(const std::string& msg,
                                  const std::string& stack,
                                  int32_t error_code){};

  virtual void CleanClosuresInCycleReference() {}
  // process protocol message sent here when then paused
  BASE_EXPORT_FOR_DEVTOOL virtual void ProcessPausedMessages(
      lepus::Context* context, const std::string& message) = 0;
  // interface for devtool to initialize debugger
  BASE_EXPORT_FOR_DEVTOOL virtual void SetDebugger(
      std::shared_ptr<DebuggerBase> debugger) = 0;
  BASE_EXPORT_FOR_DEVTOOL virtual std::shared_ptr<DebuggerBase>
  GetDebugger() = 0;
  BASE_EXPORT_FOR_DEVTOOL virtual void SetInspector(
      lepus_inspector::LepusInspector* inspector) = 0;
  BASE_EXPORT_FOR_DEVTOOL virtual void SetSession(
      lepus_inspector::LepusInspectorSession* session) = 0;
  BASE_EXPORT_FOR_DEVTOOL virtual lepus_inspector::LepusInspectorSession*
  GetSession() = 0;
  BASE_EXPORT_FOR_DEVTOOL virtual lepus_inspector::LepusInspector*
  GetInspector() = 0;
  BASE_EXPORT_FOR_DEVTOOL virtual bool HasFinishedExecution() = 0;

  StringTable* string_table() { return &string_table_; }
  void set_name(const std::string& name) { name_ = name; }

  static Context* GetFromJsContext(LEPUSContext* ctx);
  static std::shared_ptr<Context> CreateContext(bool use_lepusng = false);

  // check context type
  bool IsVMContext() const { return type_ == VMContextType; }
  bool IsLepusNGContext() const { return type_ == LepusNGContextType; }
  bool IsLepusContext() const { return type_ == LepusContextType; }
  virtual LEPUSContext* context() { return nullptr; }
  virtual LEPUSValue GetTopLevelFunction() { return LEPUS_UNDEFINED; }

  static LEPUSLepusRefCallbacks GetLepusRefCall();
  static LEPUSDebuggerCallbacks GetLepusDebuggerCall();

  static CellManager& GetContextCells();
  static ContextCell* RegisterContextCell(lepus::QuickContext* qctx);

  static inline ContextCell* GetContextCellFromCtx(LEPUSContext* ctx) {
    return ctx ? reinterpret_cast<ContextCell*>(LEPUS_GetContextOpaque(ctx))
               : nullptr;
  }

  void ReportError(const std::string& exception_info);
  void PrintMsgToJS(const std::string& level, const std::string& msg);

  virtual void RegisterLepusVerion() = 0;

  // data for collect leak
  static std::mutex& GetTableMutex() {
    static base::NoDestructor<std::mutex> table_mutex;
    return *table_mutex;
  }
  static std::mutex& GetArrayMutex() {
    static base::NoDestructor<std::mutex> array_mutex_;
    return *array_mutex_;
  }
  static std::mutex& GetLeakMutex() {
    static base::NoDestructor<std::mutex> leak_mutex_;
    return *leak_mutex_;
  }
  static std::unordered_map<Dictionary*, ValueState>& GetLeakTable() {
    static base::NoDestructor<std::unordered_map<Dictionary*, ValueState>>
        leak_table;
    return *leak_table;
  }
  static std::unordered_map<CArray*, ValueState>& GetLeakArray() {
    static base::NoDestructor<std::unordered_map<CArray*, ValueState>>
        leak_array;
    return *leak_array;
  }

  BASE_EXPORT_FOR_DEVTOOL static void SetDebugEnabled(bool enable);
  static bool IsDebugEnabled() { return debug_enabled_; }

 protected:
  ContextType type_;
  std::string name_;
  StringTable string_table_;
  tasm::TemplateAssembler* tasm_pointer_{nullptr};
  static bool debug_enabled_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_CONTEXT_H_
