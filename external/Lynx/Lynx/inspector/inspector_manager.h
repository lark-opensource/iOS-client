// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_INSPECTOR_MANAGER_H_
#define LYNX_INSPECTOR_INSPECTOR_MANAGER_H_

#include <memory>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/closure.h"
#include "base/log/logging.h"
#include "inspector/style_sheet.h"
#include "tasm/template_assembler.h"
#include "third_party/fml/task_runner.h"

namespace lynx {

namespace piper {
struct ConsoleMessage;
}  // namespace piper

namespace tasm {
class TemplateAssembler;
}  // namespace tasm

namespace runtime {
class LynxRuntime;
}

namespace base {
class TaskRunner;
}  // namespace base

namespace devtool {
class InspectorHierarchyObserver;

using lynx::tasm::HmrData;

class InspectorManager : public std::enable_shared_from_this<InspectorManager> {
 public:
  InspectorManager() = default;
  virtual ~InspectorManager() = default;

  virtual void SendConsoleMessage(const piper::ConsoleMessage& message) = 0;
  virtual intptr_t getJavascriptDebugger() = 0;
  virtual intptr_t getLepusDebugger(const std::string& url) = 0;
  virtual intptr_t createInspectorRuntimeManager() = 0;
  virtual intptr_t GetLynxDevtoolFunction() = 0;

  BASE_EXPORT_FOR_DEVTOOL void RunOnJSThread(lynx::base::closure closure,
                                             int32_t delay = -1);
  BASE_EXPORT_FOR_DEVTOOL void RunOnWorkerThread(lynx::base::closure closure);
  BASE_EXPORT_FOR_DEVTOOL static void RunOnMainThread(
      lynx::base::closure closure);

  void OnTasmCreated(intptr_t ptr);

  virtual void Call(const std::string& function, const std::string& params) = 0;

  void TranspondMessage(const std::string& response);

  intptr_t GetFirstPerfContainer();

  void SetLynxEnv(const std::string& key, bool value);

  void OnJsTaskRunnerReady(const fml::RefPtr<fml::TaskRunner>& js_runner);
  void OnWorkerTaskRunnerReady(const fml::RefPtr<fml::TaskRunner>& runner);
  bool IsJsRunnerReady() { return js_runner_.get() != nullptr; }

  intptr_t GetDefaultProcessor();
  intptr_t GetProcessorMap();

  void HotModuleReplaceWithHmrData(const std::vector<tasm::HmrData>& data,
                                   const std::string& message);
  void HotModuleReplace(const lepus::Value& data, const std::string& message);

 protected:
  std::weak_ptr<tasm::TemplateAssembler> tasm_weak_ptr_;
  std::shared_ptr<InspectorHierarchyObserver> hierarchy_observer_sp_;
  fml::RefPtr<fml::TaskRunner> js_runner_;
  fml::RefPtr<fml::TaskRunner> worker_runner_;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_INSPECTOR_MANAGER_H_
