#ifndef JS_RUNTIME_RUNTIME_H_
#define JS_RUNTIME_RUNTIME_H_

#include <memory>
#include <string>

#include "basic/log/logging.h"
#include "basic/task/callback.h"
#include "jsb/module/vmsdk_module_manager.h"
#include "jsb/runtime/js_executor_wraper.h"
#include "jsb/runtime/napi_runtime_wraper.h"
#include "jsb/runtime/task_runner.h"

namespace vmsdk {

namespace runtime {
class JSRuntimeUtils {
 public:
  // return true, if env has exception pending
  static bool CheckAndGetExceptionMsg(Napi::Env env, std::string &msg);

  // include js unhandled rejection exception
  static bool CheckAndGetException2(Napi::Env env, std::string &msg);
};

class ExceptionCheckScope {
 public:
  ExceptionCheckScope();
  ~ExceptionCheckScope();
};

class JSRuntime final {
 public:
  explicit JSRuntime(std::shared_ptr<TaskRunner> js_runner);
  ~JSRuntime();
  JSRuntime(const JSRuntime &) = delete;
  JSRuntime &operator=(const JSRuntime &) = delete;

  void Init(
      const std::shared_ptr<vmsdk::piper::VmsdkModuleManager> &module_manager,
      JS_ENGINE_TYPE jsengine_type, bool is_multi_thread);

  // std::shared_ptr<TaskRunner> getJSTaskRunner() { return js_runner_; }

  std::shared_ptr<vmsdk::runtime::NAPIRuntime> getRuntime() {
    return napi_runtime_;
  }

  std::shared_ptr<vmsdk::runtime::JSExecutor> getJSExecutor() {
    return js_executor_;
  }

  void RunNowOrPostTask(general::Closure *task);
  void PostTask(general::Closure *task);
  void PostTaskAtFront(general::Closure *task);
  void RemoveTaskByGroupId(uintptr_t group_Id);

  std::shared_ptr<general::TimerNode> PostDelayedTask(general::Closure *task,
                                                      int32_t delayed_time);
  void RemoveTask(const std::shared_ptr<general::TimerNode> &task);

  void OnModuleMethodInvoked(const std::string &module,
                             const std::string &method, int32_t error_code);
  void EvaluateScript(const std::string &script);
  void RegisterNativeModuleProxy();
  void TurnOff() { running_ = false; }

 private:
  bool running_ = true;
  std::shared_ptr<TaskRunner> js_runner_;
  std::shared_ptr<vmsdk::runtime::NAPIRuntime> napi_runtime_;
  std::shared_ptr<vmsdk::runtime::JSExecutor> js_executor_;
};

}  // namespace runtime
}  // namespace vmsdk

#endif  // JS_RUNTIME_RUNTIME_H_
