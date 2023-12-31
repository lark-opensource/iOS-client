// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_QUICK_CONTEXT_H_
#define LYNX_LEPUS_QUICK_CONTEXT_H_

#include <memory>
#include <string>
#include <vector>

#include "config/config.h"
#include "lepus/context.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace lepus {

class ContextBinaryWriter;

// use quickjs enginer as lepus context
class QuickContext : private LEPUSRuntimeData, public Context {
 public:
  static QuickContext* Cast(Context* context);
  QuickContext();
  virtual ~QuickContext();
  virtual void Initialize() override;
  virtual const std::string Compile(const std::string& source,
                                    const char* sdk_version = NULL) override;
  virtual bool Execute(Value* ret = nullptr) override;

  virtual Value Call(const std::string& name,
                     const std::vector<lepus::Value>& args) override;

  virtual Value CallWithClosure(const lepus::Value& closure,
                                const std::vector<lepus::Value>& args) override;

  virtual long GetParamsSize() override;
  virtual Value* GetParam(long index) override;
  virtual const std::string& name() const override;
  virtual bool UpdateTopLevelVariable(const std::string& name,
                                      const lepus::Value& val) override;
  virtual bool CheckTableShadowUpdatedWithTopLevelVariable(
      const lepus::Value& update) override;
  virtual void ResetTopLevelVariable() override;
  virtual void ResetTopLevelVariableByVal(const Value& val) override;

  virtual std::unique_ptr<lepus::Value> GetTopLevelVariable(
      bool ignore_callable = false) override;
  virtual LEPUSContext* context() override { return lepus_context_; }
  virtual bool GetTopLevelVariableByName(const std::string& name,
                                         lepus::Value* ret) override;

  virtual void SetGlobalData(const String& name, const Value& value) override;
  virtual void SetGCThreshold(int64_t threshold) override;

  void SetEnableStrictCheck(bool val);
  void SetStackSize(uint32_t stack_size);
  void RegisterGlobalFunction(const char* name, LEPUSCFunction* func,
                              int argc = 0);
  void RegisterGlobalProperty(const char* name, LEPUSValue val);
#if ENABLE_CLI
  // serialize
  void Serialize(ContextBinaryWriter* writer);
  const std::string& GetDebugSourceCode();
  int32_t GetDebugEndLineNum();
#endif

  // deserialize
  LEPUSValue SearchGlobalData(const std::string& name);
  bool DeSerialize(const uint8_t* buf, uint64_t size);

  // DeSerialize & Execute
  bool EvalBinary(const uint8_t* buf, uint64_t size, Value* ret);

  LEPUSValue GetAndCall(const std::string& name,
                        const std::vector<LEPUSValue>& args);
  LEPUSValue InternalCall(LEPUSValue func, const std::vector<LEPUSValue>& args);
  void SetProperty(const char* name, LEPUSValue obj, LEPUSValue val);
  virtual tasm::TemplateAssembler* GetTasmPointer() override;

  inline void set_napi_env(void* env) { napi_env_ = env; }
  inline void* napi_env() { return napi_env_; }

  // lepusNG debugger
  void DebugDataInitialize();
  BASE_EXPORT_FOR_DEVTOOL void ProcessPausedMessages(
      lepus::Context* context, const std::string& message) override;
  BASE_EXPORT_FOR_DEVTOOL lepus_inspector::LepusInspectorSession* GetSession()
      override;
  BASE_EXPORT_FOR_DEVTOOL lepus_inspector::LepusInspector* GetInspector()
      override;
  BASE_EXPORT_FOR_DEVTOOL void SetDebugger(
      std::shared_ptr<DebuggerBase> debugger) override;
  BASE_EXPORT_FOR_DEVTOOL std::shared_ptr<DebuggerBase> GetDebugger() override;
  BASE_EXPORT_FOR_DEVTOOL void SetInspector(
      lepus_inspector::LepusInspector* inspector) override;
  BASE_EXPORT_FOR_DEVTOOL void SetSession(
      lepus_inspector::LepusInspectorSession* session) override;
  virtual void RegisterLepusVerion() override;
  void SetDebuggerSourceAndEndLine(const std::string& source);
  BASE_EXPORT_FOR_DEVTOOL virtual LEPUSValue GetTopLevelFunction() override;
  void SetTemplateDebugURL(const std::string& url) {
    template_debug_url_ = url;
  }
  std::string GetSdkVersion() { return sdk_version_; }
  bool HasFinishedExecution() override;

  void ReportSetConstValueError(const lepus::Value& val, LEPUSValue prop,
                                int32_t idx);

  void set_debuginfo_outside(bool val);
  bool debuginfo_outside();
  void ReportErrorWithMsg(const std::string& msg, int32_t error_code) override;
  void ReportErrorWithMsg(const std::string& msg, const std::string& stack,
                          int32_t error_code) override;

 private:
  void SetTopLevelFunction(LEPUSValue val);
  std::string FormatExceptionMessage(const std::string& message,
                                     const std::string& stack,
                                     const std::string& prefix);

  LEPUSValue GetProperty(const std::string& name, LEPUSValue this_obj);
  LEPUSValue top_level_function_;

  // private function
  std::string GetExceptionMessage(const char* prefix = "");
  // TODO: optimize it
  // runtime_ may can shared between context
  bool use_lepus_strict_mode_;
  uint32_t stack_size_ = 0;

  // Napi::Env
  void* napi_env_{nullptr};

  // for lepusNG debugger
  lepus_inspector::LepusInspector* inspector_;
  lepus_inspector::LepusInspectorSession* session_;
  std::shared_ptr<DebuggerBase> debugger_base_;
  // lepusNG debugger source code
  std::string debug_source_;
  // lepusNG debugger source end line num
  int32_t end_line_num_;
  std::string template_debug_url_ = "";
  // align to VMContext;
  std::string sdk_version_ = "null";
  bool lepusng_finished_;
  bool debuginfo_outside_;
};

}  // namespace lepus
}  // namespace lynx
#endif  // LYNX_LEPUS_QUICK_CONTEXT_H_
