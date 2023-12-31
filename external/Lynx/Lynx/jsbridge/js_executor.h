#ifndef LYNX_JSBRIDGE_JS_EXECUTOR_H_
#define LYNX_JSBRIDGE_JS_EXECUTOR_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "jsbridge/bindings/timed_task_adapter.h"
#include "jsbridge/jsi/jsi.h"
#include "third_party/rapidjson/document.h"

namespace lynx {

namespace runtime {
class RuntimeManager;
class LynxRuntimeObserver;
class TemplateDelegate;
class LynxApiHandler;
}  // namespace runtime

namespace piper {

class ConsoleMessagePostMan;
class ModuleCallback;
class LynxModuleManager;
class App;
class ModuleCallbackFunctionHolder;

class JSExecutor : public std::enable_shared_from_this<JSExecutor> {
 public:
  JSExecutor(const std::shared_ptr<JSIExceptionHandler>& handler,
             const std::string& group_id,
             const std::shared_ptr<runtime::LynxRuntimeObserver>& observer,
             bool forceUseLightweightJSEngine = false)
      : exception_handler(handler),
        group_id_(group_id),
        forceUseLightweightJSEngine_(forceUseLightweightJSEngine),
        runtime_observer_(observer) {}
  virtual ~JSExecutor() = default;
  virtual void Init() = 0;
  virtual void Destroy() = 0;
  virtual runtime::RuntimeManager* createInspectorRuntimeManager() = 0;

  virtual void loadPreJSBundle(
      bool use_provider_js_env,
      std::vector<std::pair<std::string, std::string>>& js_pre_sources,
      bool ensure_console, int64_t rt_id, bool enable_user_code_cache,
      const std::string& code_cache_source_url) = 0;
  virtual void invokeCallback(std::shared_ptr<piper::ModuleCallback> callback,
                              piper::ModuleCallbackFunctionHolder* holder) = 0;

  virtual void initJavaScriptDebugger(
      const std::shared_ptr<piper::Runtime>& runtime,
      const std::string& group_id) = 0;

  std::shared_ptr<runtime::LynxRuntimeObserver> getRuntimeObserver() {
    return runtime_observer_;
  }

  virtual std::shared_ptr<piper::App> createNativeAppInstance(
      int64_t rt_id, runtime::TemplateDelegate*,
      std::unique_ptr<lynx::runtime::LynxApiHandler> api_handler,
      piper::TimedTaskAdapter timed_task_adapter) = 0;

  virtual piper::JSRuntimeCreatedType getJSRuntimeType() = 0;

  virtual std::shared_ptr<piper::Runtime> GetJSRuntime() = 0;

  virtual void SetUrl(const std::string& url) = 0;

  virtual std::shared_ptr<piper::ConsoleMessagePostMan>
  CreateConsoleMessagePostMan() = 0;

 protected:
  std::shared_ptr<JSIExceptionHandler> exception_handler;
  std::string group_id_;
  bool forceUseLightweightJSEngine_;
  std::shared_ptr<runtime::LynxRuntimeObserver> runtime_observer_;
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JS_EXECUTOR_H_
