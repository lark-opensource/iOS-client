// Copyright 2019 The Lynx Authors. All rights reserved.

#include "inspector/observer/inspector_runtime_observer.h"

#include "inspector/inspector_manager.h"
#include "inspector/observer/inspector_console_postman.h"

namespace lynx {
namespace devtool {
constexpr char kSingleGroupID[] = "-1";

InspectorRuntimeObserver::InspectorRuntimeObserver(
    const std::shared_ptr<InspectorManager> &manager)
    : manager_(manager) {}

intptr_t InspectorRuntimeObserver::CreateJavascriptDebugger() {
  auto manager = manager_.lock();
  auto ptr = manager != nullptr ? manager->getJavascriptDebugger() : 0;
  if (ptr) {
    debugger_ =
        reinterpret_cast<piper::JavaScriptDebuggerWrapper *>(ptr)->debugger_;
  }
  return ptr;
}

intptr_t InspectorRuntimeObserver::CreateConsolePostMan() {
  return reinterpret_cast<intptr_t>(new InspectorConsolePostMan);
}

void InspectorRuntimeObserver::OnMessagePosted(intptr_t message) {
  auto manager = manager_.lock();
  if (manager != nullptr) {
    manager->SendConsoleMessage(
        *reinterpret_cast<lynx::piper::ConsoleMessage *>(message));
  }
}

intptr_t InspectorRuntimeObserver::CreateInspectorRuntimeManager() {
  auto manager = manager_.lock();
  return manager != nullptr ? manager->createInspectorRuntimeManager() : 0;
}

void InspectorRuntimeObserver::OnJsTaskRunnerReady(
    const fml::RefPtr<fml::TaskRunner> &js_runner) {
  auto manager = manager_.lock();
  if (manager) {
    manager->OnJsTaskRunnerReady(js_runner);
  }
}

void InspectorRuntimeObserver::OnWorkerTaskRunnerReady(
    const fml::RefPtr<fml::TaskRunner> &js_runner) {
  auto manager = manager_.lock();
  if (manager) {
    manager->OnWorkerTaskRunnerReady(js_runner);
  }
}

void InspectorRuntimeObserver::InitWorker(
    const std::shared_ptr<piper::Runtime> &runtime) {
  auto debugger = debugger_.lock();
  if (debugger) {
    debugger->InitWithRuntime(runtime, kSingleGroupID, true);
  }
}

void InspectorRuntimeObserver::OnWorkerDestroy() {
  auto debugger = debugger_.lock();
  if (debugger) {
    debugger->OnDestroy(true);
  }
}

}  // namespace devtool
}  // namespace lynx
