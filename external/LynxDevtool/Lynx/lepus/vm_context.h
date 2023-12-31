// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_VM_CONTEXT_H_
#define LYNX_LEPUS_VM_CONTEXT_H_

#include <memory>
#include <vector>

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG

#include <list>
#include <stack>
#include <string>
#include <unordered_map>

#include "base/base_export.h"
#include "base/trace_event/trace_event.h"
#include "lepus/context.h"
#include "lepus/debugger_base.h"
#include "lepus/function.h"
#include "lepus/heap.h"
#include "lepus/lepus_string.h"
#include "lepus/value-inl.h"
#include "tasm/lynx_trace_event.h"
namespace lynx {
namespace tasm {
class TemplateBinaryReader;
class TemplateEntry;
}  // namespace tasm

namespace lepus {
class OutputStream;
class DebuggerBase;
class VMContext : public Context {
 public:
  VMContext()
      : Context(VMContextType),
        current_frame_(nullptr),
        current_context_(),
        sdk_version_("null"),
        enable_strict_check_(false),
        enable_top_var_strict_mode_(true),
        closures_(),
        block_context_() {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "VMContext::InnerConstructor");
    DebugDataInitialize();
  }
  virtual ~VMContext() = default;
  virtual void Initialize() override;
  virtual const std::string Compile(const std::string& source,
                                    const char* sdk_version = NULL) override;
  virtual bool Execute(Value* ret = nullptr) override;

  virtual bool UpdateTopLevelVariable(const std::string& name,
                                      const Value& value) override;
  virtual bool CheckTableShadowUpdatedWithTopLevelVariable(
      const lepus::Value& update) override;

  virtual void ResetTopLevelVariable() override;
  virtual void ResetTopLevelVariableByVal(const Value& val) override;

  virtual Value CallWithClosure(const lepus::Value& closure,
                                const std::vector<lepus::Value>& args) override;
  virtual Value Call(const std::string& name,
                     const std::vector<Value>& args) override;

  virtual std::unique_ptr<lepus::Value> GetTopLevelVariable(
      bool ignore_callable = false) override;
  virtual bool GetTopLevelVariableByName(const std::string& name,
                                         lepus::Value* ret) override;
  virtual long GetParamsSize() override;
  virtual Value* GetParam(long index) override;

  void CleanClosuresInCycleReference() override;
  bool CallFunction(Value* function, size_t argc, Value* ret);

  BASE_EXPORT_FOR_DEVTOOL lepus_inspector::LepusInspectorSession* GetSession()
      override;
  BASE_EXPORT_FOR_DEVTOOL lepus_inspector::LepusInspector* GetInspector()
      override;
  BASE_EXPORT_FOR_DEVTOOL Frame* GetCurrentFrame();
  BASE_EXPORT_FOR_DEVTOOL void SetInspector(
      lepus_inspector::LepusInspector* inspector) override;
  BASE_EXPORT_FOR_DEVTOOL void SetSession(
      lepus_inspector::LepusInspectorSession* session) override;
  BASE_EXPORT_FOR_DEVTOOL void ProcessPausedMessages(
      lepus::Context* context, const std::string& message) override;
  BASE_EXPORT_FOR_DEVTOOL void SetDebugger(
      std::shared_ptr<DebuggerBase> debugger) override;
  BASE_EXPORT_FOR_DEVTOOL std::shared_ptr<DebuggerBase> GetDebugger() override;
  BASE_EXPORT_FOR_DEVTOOL lynx::base::scoped_refptr<Function> GetRootFunction();
  // for deserialize
  void SetRootFunction(base::scoped_refptr<Function> func) {
    root_function_ = func;
  }
  bool HasFinishedExecution() override { return false; }

#ifdef LEPUS_TEST
  void Dump();
#endif

  void SetSdkVersion(const std::string& sdk_version);

  std::string GetSdkVersion() { return sdk_version_; }

  void PushCurrentContext(long current_context) {
    current_context_.push(current_context);
  }

  long PopCurrentContextReg() {
    DCHECK(!current_context_.empty());
    long last_context = current_context_.top();
    current_context_.pop();
    return last_context;
  }

  long GetCurrentContextReg() {
    if (current_context_.empty()) {
      return -1;
    }
    return current_context_.top();
  }

  void SetArrayPrototype(Value proto) { array_prototype_ = proto; }

  void SetDatePrototype(Value proto) { date_prototype_ = proto; }

  void SetStringPrototype(Value proto) { string_prototype_ = proto; }

  void SetRegexpPrototype(Value proto) { regexp_prototype_ = proto; }

  void SetNumberPrototype(Value proto) { number_prototype_ = proto; }

  void SetEnableStrictCheck(bool val) { enable_strict_check_ = val; }

  void SetEnableTopVarStrictMode(bool val) {
    enable_top_var_strict_mode_ = val;
  }

  void SetTemplateDebugURL(const std::string& url) {
    template_debug_url_ = url;
  }

  void SetNullPropAsUndef(bool val) { enable_null_prop_as_undef_ = val; }

  void SetClosureFix(bool val) { closure_fix_ = val; }
  virtual tasm::TemplateAssembler* GetTasmPointer() override;

  inline Global* global() { return &global_; }
  inline Global* builtin() { return &builtin_; }
  void SetGlobalData(const String& name, const Value& value) override;
  void SetBuiltinData(const String& name, Value& value) {
    builtin_.Add(name, value);
  }
  Value* SearchGlobalData(const String& name) { return global_.Find(name); }

  static VMContext* Cast(Context* context) {
    DCHECK(context->IsVMContext());
    return static_cast<VMContext*>(context);
  }

  virtual void RegisterLepusVerion() override;

 private:
  // used to control closure context
  class ContextScope {
   public:
    ContextScope(VMContext* ctx,
                 const lynx::base::scoped_refptr<lepus::Closure>& closure)
        : ctx_(ctx) {
      last_closure_context_ = ctx->PrepareClosureContext(closure);
    }
    ~ContextScope() { ctx_->closure_context_ = last_closure_context_; }

   private:
    VMContext* ctx_;
    Value last_closure_context_;
  };

  class ClosureManager {
   public:
    void AddClosure(base::scoped_refptr<lepus::Closure>& closure,
                    bool context_executed);
    ~ClosureManager();
    ClosureManager() : itr_(0){};
    void CleanUpClosuresCreatedAfterExecuted();

   private:
    void ClearClosure();
    std::vector<base::scoped_refptr<lepus::Closure>>
        all_closures_before_executed_;
    std::vector<base::scoped_refptr<lepus::Closure>>
        all_closures_after_executed_;
    std::vector<base::scoped_refptr<lepus::Closure>>::size_type itr_;
  };

  void RunFrame();
  void GenerateClosure(Value* value, long index);
  Value PrepareClosureContext(
      const lynx::base::scoped_refptr<lepus::Closure>& clo);
  void ReportException(
      const std::string& exception_info, int& pc, int& instruction_length,
      lynx::base::scoped_refptr<Closure>& current_frame_closure,
      lynx::base::scoped_refptr<Function>& current_frame_function,
      const Instruction*& current_frame_base, Value*& current_frame_regs,
      bool report_redbox);
  void ReportRedBox(const std::string& exception_info, int& pc);

  std::string BuildBackTrace(std::vector<int> pcs, Frame* exception_frame_);
  Heap heap_;
  Frame* current_frame_;
  std::stack<long> current_context_;

  void DebugDataInitialize();
  void ProcessDebuggerMessages(int32_t current_pc);
  void DebuggerInitializer();
  int32_t debugger_frame_id_;
  lepus_inspector::LepusInspector* inspector_;
  lepus_inspector::LepusInspectorSession* session_;
  std::shared_ptr<DebuggerBase> debugger_base_;

 protected:
  friend class DebuggerBase;
  friend class CodeGenerator;
  friend class ContextBinaryWriter;
  friend class ContextBinaryReader;
  friend class LexicalFunction;
  friend class ContextScope;

  friend class tasm::TemplateEntry;
  friend class tasm::TemplateBinaryReader;
  Heap& heap() { return heap_; }

  Global global_;
  Global builtin_;

  // TODO: to use String instead of String*
  std::unordered_map<String, long> top_level_variables_;
  base::scoped_refptr<Function> root_function_;
  std::stack<Value> context_;
  Value closure_context_;
  StringTable string_table_;
  std::string exception_info_;
  std::string sdk_version_;
  bool enable_strict_check_;
  bool enable_top_var_strict_mode_;
  bool enable_null_prop_as_undef_ = false;
  bool closure_fix_ = false;
  std::string template_debug_url_ = "";

  Value array_prototype_;
  Value date_prototype_;
  Value string_prototype_;
  Value regexp_prototype_;
  Value number_prototype_;

  bool executed_ = false;

  ClosureManager closures_;
  std::stack<Value> block_context_;
};
}  // namespace lepus
}  // namespace lynx

#endif
#endif  // LYNX_LEPUS_VM_CONTEXT_H_
