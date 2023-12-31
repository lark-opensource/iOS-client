#ifndef JS_WORKER_HEADER_H
#define JS_WORKER_HEADER_H

#include <pthread.h>
#include <semaphore.h>

#include <atomic>
#include <cassert>
#include <cstdlib>
#include <future>
#include <mutex>
#include <queue>
#include <unordered_map>
#include <unordered_set>

#if defined(OS_ANDROID) && defined(ENABLE_DEBUGGER)
#include <jni.h>
#endif

#include "jsb/runtime/js_runtime.h"
#include "jsb/runtime/napi_runtime_wraper.h"
#include "jsb/runtime/runtime_delegate.h"
#include "jsb/runtime/task_runner_manufacture.h"
#include "napi.h"
#include "napi_runtime.h"
#include "worker/net/response_delegate.h"
#if defined(OS_IOS) && defined(ENABLE_DEBUGGER)
#include "devtool/iOS/VMSDKDebugICBase.h"  // for use vmsdk::devtool::VMSDKDebugICBase
#endif

namespace vmsdk {
namespace worker {

class Worker;
using WorkerTaskFunction =
    std::function<void(Worker *, std::string, std::string)>;
using TimerNodeMap =
    std::unordered_map<void *, std::shared_ptr<general::TimerNode>>;
// worker to handle interaction against Java layer
class Worker {
 public:
  Worker(std::shared_ptr<runtime::TaskRunner> task_runner,
         std::shared_ptr<runtime::JSRuntime> js_runtime,
         std::shared_ptr<runtime::JSRuntimeDelegate> worker_delegate,
         const std::string biz_name = "");
  ~Worker() = default;

  void Init();
  // can be only called in worker thread
  void InitAsync();

  void Terminate();
  void TerminateAsync();

  int evaluateJavaScript(const std::string &data,
                         const std::string &filename = "");
  // can be only called in worker thread
  int evaluateJavaScriptAsync(const std::string &data,
                              const std::string &filename);

  void PostMessage(const std::string &data);
  // can be only called in worker thread
  void PostMessageAsync(const std::string &data);

  void registerDelegateFunction();
  void registerDelegateFunctionAsync();

#if defined(OS_ANDROID) && defined(ENABLE_DEBUGGER)
  void InitInspector(jobject inspector_client);
#endif
#if defined(OS_IOS) && defined(ENABLE_DEBUGGER)
  void InitInspector(
      std::shared_ptr<vmsdk::devtool::iOS::VMSDKDebugICBase> inspector_client);
#endif

  void SetTimeoutTask();

  void setRunning(bool running) { running_ = running; }

  static Napi::Value PostMessageOut(const Napi::CallbackInfo &info);

  static Napi::Value SetTimeout(const Napi::CallbackInfo &info);

  static Napi::Value ClearTimeout(const Napi::CallbackInfo &info);

  static Napi::Value SetInterval(const Napi::CallbackInfo &info);

  static Napi::Value ImportScripts(const Napi::CallbackInfo &info);

  static Napi::Value Fetch(const Napi::CallbackInfo &info);

  void ExecutePendingJob();

#ifdef ENABLE_CODECACHE
  void InitCodeCache(const std::string &filename) { cache_path_ = filename; }
#endif  // ENABLE_CODECACHE

  // DelayedTask will run & cancel at TimerTaskloop
  // Cannot ensure the delayed_milliseconds accurate
  // But can ensure thread safety
  void PostDelayedTask(general::Closure *task, int32_t delayed_milliseconds);

  Napi::Env &Env() { return worker_env_; }

 private:
  class WorkerClosure : public general::Closure {
   public:
    WorkerClosure(Worker *worker, WorkerTaskFunction task, std::string param1,
                  std::string param2)
        : worker_(worker), task_(task), param1_(param1), param2_(param2) {}

    virtual ~WorkerClosure() = default;
    void Run() override {
      if (task_) {
        task_(worker_, param1_, param2_);
      }
    }

   private:
    Worker *worker_;
    WorkerTaskFunction task_;
    std::string param1_;
    std::string param2_;
  };

  class TimeoutClosure : public general::Closure {
   public:
    explicit TimeoutClosure(Worker *worker, Napi::Function callback,
                            bool is_interval = false)
        : worker_(worker),
          callback_(Napi::Persistent(callback)),
          is_interval_(is_interval),
          closure_id_(worker->timer_id_generator++) {}

    virtual ~TimeoutClosure() = default;
    void Run() override;

   private:
    Worker *worker_;
    Napi::Reference<Napi::Function> callback_;
    bool is_interval_;
    uint32_t closure_id_;
    friend class Worker;
  };

  friend class TimeoutClosure;
  friend class net::ResponseDelegate;
  void CallOnMessageCallback(std::string msg);
  void CallOnErrorCallback(std::string msg);
  std::string FetchJsWithUrlSync(std::string url);
  bool workerDelegateExists();
  void RemoveTimerNode(uint32_t closure_id);
  void RemoveAsyncTasks();

  bool running_;
  Napi::Env worker_env_;
  typedef std::unordered_map<uint32_t, std::weak_ptr<general::TimerNode>>
      TimerNodeMap;

  TimerNodeMap timer_node_map_;
  std::atomic_uint32_t timer_id_generator;

  std::shared_ptr<runtime::TaskRunner> task_runner_;
  std::shared_ptr<runtime::JSRuntime> js_runtime_;
  std::shared_ptr<runtime::JSRuntimeDelegate> worker_delegate_;
  std::unordered_map<net::ResponseDelegate *,
                     std::unique_ptr<net::ResponseDelegate>>
      response_delgates_;
  std::string biz_name_;

#ifdef ENABLE_CODECACHE
#ifdef PROFILE_CODECACHE
  void DumpCacheStatus();
#endif  // PROFILE_CODECACHE
  void OutputCodeCache();
  static constexpr int DEFAULT_CACHE_SIZE = 1 << 24;  // 16MB
  bool use_cache_ = false;
  std::string cache_path_;
#endif  // ENABLE_CODECACHE
};

}  // namespace worker
}  // namespace vmsdk

#endif  // JS_WORKER_HEADER_H
