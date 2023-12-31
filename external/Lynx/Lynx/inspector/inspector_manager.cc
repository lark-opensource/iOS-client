// Copyright 2019 The Lynx Authors. All rights reserved.

#include "inspector/inspector_manager.h"

#include <map>
#include <utility>

#include "base/any.h"
#include "base/lynx_env.h"
#include "base/perf_collector.h"
#include "base/string/string_number_convert.h"
#include "base/threading/task_runner_manufactor.h"
#include "config/config.h"
#include "css/css_value.h"
#include "inspector/observer/inspector_hierarchy_observer.h"
#include "inspector/observer/inspector_lepus_context_observer.h"
#include "inspector/observer/inspector_runtime_observer.h"
#include "jsbridge/bindings/console_message_postman.h"
#include "jsbridge/runtime/lynx_runtime.h"
#include "shell/lynx_actor.h"
#include "shell/lynx_shell.h"
#include "tasm/react/element.h"
#if ENABLE_ARK_REPLAY
#include "tasm/replay/ark_test_replay.h"
#endif
#include "tasm/template_assembler.h"

namespace lynx {
namespace devtool {

using GetFunctionForElementMapPtr =
    std::map<lynxdev::devtool::DevtoolFunction,
             std::function<void(const base::any&)>> (*)();

// TODO(heshan):will refactor when split tasm
void InspectorManager::OnTasmCreated(intptr_t ptr) {
  auto* shell = reinterpret_cast<lynx::shell::LynxShell*>(ptr);
  shell->SetLynxRuntimeObserver(
      std::make_shared<InspectorRuntimeObserver>(shared_from_this()));
  auto tasm_sp = shell->GetTasm();
  if (tasm_sp != nullptr) {
    tasm_sp->SetLepusContextObserver(
        std::make_shared<InspectorLepusContextObserver>(shared_from_this()));
  }
  tasm_weak_ptr_ = tasm_sp;
  hierarchy_observer_sp_ = std::make_shared<InspectorHierarchyObserver>();
  hierarchy_observer_sp_->SetInspectorManager(shared_from_this());
  hierarchy_observer_sp_->EnsureUIImplObserver();
  const std::unique_ptr<tasm::ElementManager>& element_manager =
      tasm_sp->page_proxy()->element_manager();
  auto* func_ptr =
      reinterpret_cast<GetFunctionForElementMapPtr>(GetLynxDevtoolFunction());
  element_manager->devtool_func_map_ = (*func_ptr)();
  element_manager->SetDevtoolFlag(true);
  element_manager->SetHierarchyObserverOnLayout(hierarchy_observer_sp_);
  element_manager->SetHierarchyObserver(hierarchy_observer_sp_);
#if ENABLE_ARK_REPLAY
  tasm::replay::ArkTestReplay::GetInstance().SetInspectorManager(
      shared_from_this());
#endif
}

void InspectorManager::OnJsTaskRunnerReady(
    const fml::RefPtr<fml::TaskRunner>& js_runner) {
  js_runner_ = js_runner;
}

void InspectorManager::OnWorkerTaskRunnerReady(
    const fml::RefPtr<fml::TaskRunner>& runner) {
  worker_runner_ = runner;
}

void InspectorManager::TranspondMessage(const std::string& response) {
  Call("TranspondMessage", response);
}

intptr_t InspectorManager::GetFirstPerfContainer() {
  return reinterpret_cast<intptr_t>(
      lynx::base::PerfCollector::GetInstance().getFirstPerfContainer());
}

void InspectorManager::SetLynxEnv(const std::string& key, bool value) {
  lynx::base::LynxEnv::GetInstance().SetEnv(key, value);
}

intptr_t InspectorManager::GetDefaultProcessor() {
  auto tasm_sp = tasm_weak_ptr_.lock();
  if (tasm_sp != nullptr) {
    return reinterpret_cast<intptr_t>(&(tasm_sp->GetDefaultProcessor()));
  }
  return 0;
}

intptr_t InspectorManager::GetProcessorMap() {
  auto tasm_sp = tasm_weak_ptr_.lock();
  if (tasm_sp != nullptr) {
    return reinterpret_cast<intptr_t>(&(tasm_sp->GetProcessorMap()));
  }
  return 0;
}

void InspectorManager::RunOnJSThread(lynx::base::closure closure,
                                     int32_t delay) {
  if (js_runner_) {
    if (delay == -1) {
      fml::TaskRunner::RunNowOrPostTask(js_runner_, std::move(closure));
    } else {
      js_runner_->PostDelayedTask(
          std::move(closure),
          fml::TimeDelta::FromMilliseconds(static_cast<int64_t>(delay)));
    }
  }
}

void InspectorManager::RunOnWorkerThread(lynx::base::closure closure) {
  if (worker_runner_) {
    fml::TaskRunner::RunNowOrPostTask(worker_runner_, std::move(closure));
  }
}

void InspectorManager::RunOnMainThread(lynx::base::closure closure) {
  base::UIThread::GetRunner()->PostTask(std::move(closure));
}

void InspectorManager::HotModuleReplaceWithHmrData(
    const std::vector<tasm::HmrData>& data, const std::string& message) {
  auto tasm_sp = tasm_weak_ptr_.lock();
  if (tasm_sp != nullptr) {
    tasm_sp->HotModuleReplaceInternal(data, message);
  }
}

void InspectorManager::HotModuleReplace(const lepus::Value& data,
                                        const std::string& message) {
  auto tasm_sp = tasm_weak_ptr_.lock();
  if (tasm_sp != nullptr) {
    tasm_sp->HotModuleReplace(data, message);
  }
}

}  // namespace devtool

}  // namespace lynx
