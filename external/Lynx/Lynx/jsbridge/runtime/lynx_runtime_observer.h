// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RUNTIME_LYNX_RUNTIME_OBSERVER_H_
#define LYNX_JSBRIDGE_RUNTIME_LYNX_RUNTIME_OBSERVER_H_

#include <memory>

#include "third_party/fml/task_runner.h"

namespace lynx {
namespace piper {
class JSIExecutor;
struct ConsoleMessage;
class ConsoleMessagePostMan;
}  // namespace piper

namespace runtime {
class LynxRuntime;
}

namespace base {
class TaskRunner;
}  // namespace base

namespace runtime {

// use for call inspector, please not dependent on anything
class LynxRuntimeObserver {
 public:
  LynxRuntimeObserver() = default;
  virtual ~LynxRuntimeObserver() = default;

  virtual intptr_t CreateJavascriptDebugger() = 0;
  virtual void OnMessagePosted(intptr_t message) = 0;
  virtual intptr_t CreateConsolePostMan() = 0;
  virtual intptr_t CreateInspectorRuntimeManager() = 0;
  virtual void OnJsTaskRunnerReady(
      const fml::RefPtr<fml::TaskRunner>& js_runner) = 0;
  virtual void OnWorkerTaskRunnerReady(
      const fml::RefPtr<fml::TaskRunner>& js_runner) = 0;

  virtual const std::weak_ptr<piper::JavaScriptDebugger>& GetJSDebugger() = 0;

  virtual void InitWorker(const std::shared_ptr<piper::Runtime>& runtime) = 0;
  virtual void OnWorkerDestroy() = 0;
};

}  // namespace runtime
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RUNTIME_LYNX_RUNTIME_OBSERVER_H_
