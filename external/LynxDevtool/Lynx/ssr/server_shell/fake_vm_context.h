// Copyright 2022 The Lynx Authors. All rights reserved.
#ifndef LYNX_SSR_SERVER_SHELL_FAKE_VM_CONTEXT_H_
#define LYNX_SSR_SERVER_SHELL_FAKE_VM_CONTEXT_H_

#include <memory>
#include <string>
#include <vector>

#include "lepus/context.h"

namespace lynx {
namespace ssr {

// only for ssr Serialize
class SSRSerializeContext : public lepus::Context {
 public:
  SSRSerializeContext() : lepus::Context(lepus::ContextType::VMContextType) {}
  ~SSRSerializeContext(){};
  void Initialize() override {}
  // align to the default value "null"
  const std::string Compile(const std::string& source,
                            const char* sdk_version = "null") override {
    return "";
  }
  bool Execute(lepus::Value* ret = nullptr) override { return false; }

  bool UpdateTopLevelVariable(const std::string& name,
                              const lepus::Value& val) override {
    return false;
  }
  // shadow equal for table
  bool CheckTableShadowUpdatedWithTopLevelVariable(
      const lepus::Value& update) override {
    return false;
  }

  void ResetTopLevelVariable() override {}
  void ResetTopLevelVariableByVal(const lepus::Value& val) override {}

  lepus::Value CallWithClosure(const lepus::Value& closure,
                               const std::vector<lepus::Value>& args) override {
    return lepus::Value();
  }
  lepus::Value Call(const std::string& name,
                    const std::vector<lepus::Value>& args) override {
    return lepus::Value();
  }
  std::unique_ptr<lepus::Value> GetTopLevelVariable(
      bool ignore_callable = false) override {
    return nullptr;
  }
  bool GetTopLevelVariableByName(const std::string& name,
                                 lepus::Value* ret) override {
    return false;
  }

  long GetParamsSize() override { return 0; }
  lepus::Value* GetParam(long index) override { return nullptr; }
  tasm::TemplateAssembler* GetTasmPointer() override { return nullptr; }
  void SetGlobalData(const lepus::String& name,
                     const lepus::Value& value) override {}

  // process protocol message sent here when then paused
  void ProcessPausedMessages(lepus::Context* context,
                             const std::string& message) override {}
  // interface for devtool to initialize debugger
  void SetDebugger(std::shared_ptr<lepus::DebuggerBase> debugger) override {}
  std::shared_ptr<lepus::DebuggerBase> GetDebugger() override {
    return nullptr;
  }
  void SetInspector(lepus_inspector::LepusInspector* inspector) override {}
  void SetSession(lepus_inspector::LepusInspectorSession* session) override {}
  lepus_inspector::LepusInspectorSession* GetSession() override {
    return nullptr;
  }
  lepus_inspector::LepusInspector* GetInspector() override { return nullptr; }
  bool HasFinishedExecution() override { return false; }
  void RegisterLepusVerion() override {}
};

}  // namespace ssr
}  // namespace lynx

#endif  // LYNX_SSR_SERVER_SHELL_FAKE_VM_CONTEXT_H_
