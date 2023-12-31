#ifndef LYNX_JSBRIDGE_JSI_EXECUTOR_H_
#define LYNX_JSBRIDGE_JSI_EXECUTOR_H_

#include <jsbridge/module/lynx_module_manager.h>

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "base/base_export.h"
#include "base/threading/thread_local.h"
#include "config/config.h"
#include "jsbridge/bindings/global.h"
#include "jsbridge/bindings/js_app.h"
#include "jsbridge/java_script_debugger.h"
#include "jsbridge/js_executor.h"
#include "jsbridge/module/lynx_module_binding.h"
#include "jsbridge/module/lynx_module_callback.h"
#include "runtime/lynx_runtime_observer.h"
#if ENABLE_ARK_REPLAY
#include "tasm/replay/lynx_module_manager_testbench.h"
#endif

namespace lynx {

namespace piper {

class BASE_EXPORT_FOR_DEVTOOL JSIExecutor : public JSExecutor {
 public:
  JSIExecutor(const std::shared_ptr<JSIExceptionHandler>& handler,
              const std::string& group_id,
              const std::shared_ptr<LynxModuleManager>& module_manager,
              const std::shared_ptr<runtime::LynxRuntimeObserver>& observer,
              bool forceUseLightweightJSEngine = false);
  virtual ~JSIExecutor();

  virtual void Init() override{};
  virtual void Destroy() override;
  virtual runtime::RuntimeManager* createInspectorRuntimeManager() override;

  void loadPreJSBundle(
      bool use_provider_js_env,
      std::vector<std::pair<std::string, std::string>>& js_pre_sources,
      bool ensure_console, int64_t rt_id, bool enable_user_code_cache,
      const std::string& code_cache_source_url) override;

  void invokeCallback(std::shared_ptr<piper::ModuleCallback> callback,
                      piper::ModuleCallbackFunctionHolder* holder) override;

  virtual void initJavaScriptDebugger(
      const std::shared_ptr<piper::Runtime>& runtime,
      const std::string& group_id) override;

  runtime::RuntimeManager* runtimeManagerInstance();

  std::shared_ptr<piper::App> createNativeAppInstance(
      int64_t rt_id, runtime::TemplateDelegate*,
      std::unique_ptr<lynx::runtime::LynxApiHandler> api_handler,
      piper::TimedTaskAdapter timed_task_adapter) override;

  piper::JSRuntimeCreatedType getJSRuntimeType() override;

  std::shared_ptr<piper::Runtime> GetJSRuntime() override;

  void SetUrl(const std::string& url) override;

  std::shared_ptr<piper::ConsoleMessagePostMan> CreateConsoleMessagePostMan()
      override;

  static BASE_EXPORT_FOR_DEVTOOL runtime::RuntimeManager*
  GetCurrentRuntimeManagerInstance(bool allow_inspector);

 protected:
  std::shared_ptr<piper::LynxModuleManager> module_manager_;
#if ENABLE_ARK_REPLAY
  std::shared_ptr<piper::ModuleManagerTestBench> module_manager_testBench_;
#endif

  // set by  the child class
  std::shared_ptr<piper::Runtime> js_runtime_;

  std::unique_ptr<piper::JavaScriptDebuggerWrapper> js_debugger_;

  JSIExecutor(const JSIExecutor&) = delete;
  JSIExecutor& operator=(const JSIExecutor&) = delete;

 private:
  static lynx_thread_local(runtime::RuntimeManager*)
      inspector_runtime_manager_instance_;
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JSI_EXECUTOR_H_
