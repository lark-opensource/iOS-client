#include "js_worker.h"

#include <chrono>
#include <memory>
#include <thread>

#include "basic/log/logging.h"
#include "jsb/runtime/js_runtime.h"
#include "jsb/runtime/napi_runtime_wraper.h"
#include "napi_env.h"
#ifndef LARK_MINIAPP
#include "worker/net/js_headers.h"
#include "worker/net/js_request.h"
#endif

#define VLOG_TIME_START() \
  auto _t_start_ = std::chrono::high_resolution_clock::now()

#define VLOG_TIME_END(...)                                           \
  auto _t_end_ = std::chrono::high_resolution_clock::now();          \
  std::chrono::duration<double, std::milli> interval_time =          \
      _t_end_ - _t_start_;                                           \
  VLOGD("CodeCache time consumption: %f ms", interval_time.count()); \
  VLOGD(__VA_ARGS__)

namespace vmsdk {
namespace worker {
using namespace vmsdk::general::logging;
Worker::Worker(std::shared_ptr<runtime::TaskRunner> task_runner,
               std::shared_ptr<runtime::JSRuntime> js_runtime,
               std::shared_ptr<runtime::JSRuntimeDelegate> worker_delegate,
               const std::string biz_name)
    : running_(false),
      worker_env_(nullptr),
      timer_id_generator(0),
      task_runner_(task_runner),
      js_runtime_(js_runtime),
      worker_delegate_(worker_delegate),
      biz_name_(biz_name) {}

void Worker::Init() {
  WorkerTaskFunction task([](Worker *worker, std::string p1, std::string p2) {
    worker->InitAsync();
  });
  if (task_runner_) {
    task_runner_->PostTask(new WorkerClosure(this, std::move(task), "", ""));
  } else {
    VLOGD("--- task_runner is null when Worker::Init ------");
  }
}

// can be only called in worker thread
void Worker::InitAsync() {
  if (!running_ || js_runtime_ == nullptr) return;
  // 确保js_runtime_在js线程已经提前初始化

  auto napi_runtime = js_runtime_->getRuntime();
  if (napi_runtime.get() == nullptr) return;

  worker_env_ = napi_runtime->Env();
#ifdef ENABLE_CODECACHE
  if (!cache_path_.empty()) {
    worker_env_.InitCodeCache(
        DEFAULT_CACHE_SIZE, cache_path_, [this](bool loaded) {
          this->use_cache_ = true;
          VLOGD("----- cache %s file loaded : %s ----- ", cache_path_.c_str(),
                loaded ? "true" : "false");
        });
  }
#endif  // ENABLE_CODECACHE

  Napi::HandleScope hscp(worker_env_);
  Napi::ContextScope contextScope(worker_env_);
  VLOGD("Worker::InitAsync biz_name_ %s ", biz_name_.c_str());

#ifndef LARK_MINIAPP
  if (biz_name_ != "lark_miniapp") {
    worker_env_.Global().Set(
        "postMessage", Napi::Function::New(worker_env_, Worker::PostMessageOut,
                                           "postMessage", (void *)this));
    if (this->workerDelegateExists()) {
      worker_env_.Global().Set(
          "importScripts",
          Napi::Function::New(worker_env_, Worker::ImportScripts,
                              "importScripts", (void *)this));
      worker_env_.Global().Set(
          "fetch", Napi::Function::New(worker_env_, Worker::Fetch, "fetch",
                                       (void *)this));
    } else {
      worker_env_.Global().Set("fetch", worker_env_.Undefined());
      worker_env_.Global().Set("importScripts", worker_env_.Undefined());
    }

    worker_env_.Global()["Headers"] =
        net::HeadersWrap::Create(worker_env_).Get(worker_env_);
    worker_env_.Global()["Request"] =
        net::RequestWrap::Create(worker_env_).Get(worker_env_);
  }
#endif

  worker_env_.Global().Set("setTimeout",
                           Napi::Function::New(worker_env_, Worker::SetTimeout,
                                               "setTimeout", (void *)this));

  worker_env_.Global().Set(
      "clearTimeout", Napi::Function::New(worker_env_, Worker::ClearTimeout,
                                          "clearTimeout", (void *)this));

  worker_env_.Global().Set("setInterval",
                           Napi::Function::New(worker_env_, Worker::SetInterval,
                                               "setInterval", (void *)this));

  worker_env_.Global().Set(
      "clearInterval", Napi::Function::New(worker_env_, Worker::ClearTimeout,
                                           "clearInterval", (void *)this));
}

void Worker::Terminate() {
  VLOGD("Worker::Terminate");

  WorkerTaskFunction terminate_task = [](Worker *worker, std::string p1,
                                         std::string p2) {
    worker->TerminateAsync();
  };
  if (task_runner_) {
    task_runner_->PostTask(
        new WorkerClosure(this, std::move(terminate_task), "", ""));
  } else {
    VLOGD("task_runner is null when Worker::terminate");
  }
}

void Worker::TerminateAsync() {
  VLOGD("Worker::TerminateAsync");
  ExecutePendingJob();
  running_ = false;
#ifndef LARK_MINIAPP
  response_delgates_.clear();
#endif
#ifdef ENABLE_CODECACHE
  if (use_cache_ && napi_env(worker_env_) != nullptr) {
    VLOGD("codecache: trying to output codecache");
    worker_env_.OutputCodeCache();
  }
#ifdef PROFILE_CODECACHE
  DumpCacheStatus();
#endif  // PROFILE_CODECACHE
#endif  // ENABLE_CODECACHE

  task_runner_->SetRunning(false);
  RemoveAsyncTasks();
}

int Worker::evaluateJavaScript(const std::string &script,
                               const std::string &filename) {
  VLOGD("evaluateJavaScript running_: %d", running_);
  WorkerTaskFunction task = [](Worker *worker, std::string js_script,
                               std::string file_name) {
    worker->evaluateJavaScriptAsync(js_script, file_name);
  };
  if (task_runner_) {
    task_runner_->RunNowOrPostTask(
        new WorkerClosure(this, std::move(task), script, filename));
  } else {
    VLOGD("task_runner is null when Worker::evaluateJavaScript");
  }
  return 0;
}

// can be only called in worker thread
int Worker::evaluateJavaScriptAsync(const std::string &data,
                                    const std::string &filename) {
  if (!running_ || worker_env_ == nullptr) return 0;
  VLOGD("evaluateJavaScriptAsync wait running_: %d", running_);
  {
    VLOGD("running in evaluating Javascript Async");
    Napi::HandleScope hscope(worker_env_);
    Napi::ContextScope contextScope(worker_env_);

    Napi::Value res;
    VLOG_TIME_START();
#ifdef ENABLE_CODECACHE
    if (use_cache_ && filename.size() != 0) {
      res = worker_env_.RunScriptCache(data.c_str(), filename.c_str());
      VLOG_TIME_END("evaluateJavaScript %s with CodeCache ---",
                    filename.c_str());
    } else
#endif  // ENABLE_CODECACHE
    {
      res = worker_env_.RunScript(data.c_str(), filename.c_str());
      VLOG_TIME_END("evaluateJavaScript script %s no CodeCache ---",
                    filename.c_str());
    }

    if (res.IsString()) {
      VLOGD("%s\n", res.ToString().Utf8Value().c_str());
    } else {
      VLOGD("%s\n", "get something(not string) after runscript");
    }
    std::string msg;
#if defined(OS_ANDROID) && defined(DEBUG)
    if (runtime::JSRuntimeUtils::CheckAndGetException2(worker_env_, msg)) {
#else
    if (runtime::JSRuntimeUtils::CheckAndGetExceptionMsg(worker_env_, msg)) {
#endif
      CallOnErrorCallback("Worker Run script exception: " + msg);
    }

    VLOGD("before execute pending job in evaluateJavaScriptAsync");
    ExecutePendingJob();
    VLOGD("after execute pending job in evaluateJavaScriptAsync");
  }

  return 0;
}

void Worker::PostMessage(const std::string &data) {
  VLOGD("PostMessage in main thread start.");
  WorkerTaskFunction task(
      [data](Worker *worker, std::string p_data, std::string p2) {
        worker->PostMessageAsync(p_data);
      });
  if (task_runner_) {
    task_runner_->PostTask(new WorkerClosure(this, std::move(task), data, ""));
  } else {
    VLOGD("task_runner_ is null when Worker::PostMessage");
  }
}

// can be only called in worker thread
void Worker::PostMessageAsync(const std::string &data) {
  VLOGD("PostMessageAsync in worker thread start.");
  if (!running_ || worker_env_ == nullptr) return;

  Napi::HandleScope hscope(worker_env_);
  Napi::ContextScope contextScope(worker_env_);

  Napi::Value on_message = worker_env_.Global().Get("onMessage");
  if (on_message.IsFunction()) {
    VLOGD("%s\n", "before call to onmessage.");
    on_message.As<Napi::Function>().Call(
        {Napi::String::New(worker_env_, data.c_str())});
  }
  VLOGD("PostMessageAsync in worker thread success.");
  ExecutePendingJob();
}

#ifndef LARK_MINIAPP
Napi::Value Worker::PostMessageOut(const Napi::CallbackInfo &info) {
  Napi::Value msg = info[0];
  Worker *worker = reinterpret_cast<Worker *>(info.Data());
  VLOGD("postingmessageOut start.");

  if (!worker->running_) return info.Env().Undefined();

  if (!msg.IsString() && msg.IsObject()) {
    Napi::Value json = info.Env().Global()["JSON"];
    Napi::Function stringify =
        json.As<Napi::Object>().Get("stringify").As<Napi::Function>();
    msg = stringify.Call({msg});
    std::string exception;
    if (runtime::JSRuntimeUtils::CheckAndGetExceptionMsg(info.Env(),
                                                         exception)) {
      exception = "Post Message ToString failed: " + exception;
      VLOGE("%s", exception.c_str());
      worker->CallOnErrorCallback(exception);
      return info.Env().Undefined();
    }
  }
  worker->CallOnMessageCallback(msg.ToString().Utf8Value());

  return info.Env().Undefined();
}
#endif

#if defined(OS_ANDROID) && defined(ENABLE_DEBUGGER)
void Worker::InitInspector(jobject inspector_client) {
  auto task_runner = task_runner_;
  WorkerTaskFunction task([inspector_client, task_runner](
                              Worker *worker, std::string p1, std::string p2) {
    VLOGE("inner Native init inspector");
    worker->js_runtime_->getRuntime()->InitInspector(inspector_client,
                                                     task_runner);
  });
  if (task_runner_) {
    task_runner_->PostTask(new WorkerClosure(this, std::move(task), "", ""));
  } else {
    VLOGD("task_runner_ is null when Worker::InitInspector");
  }
}
#endif
#if defined(OS_IOS) && defined(ENABLE_DEBUGGER)
void Worker::InitInspector(
    std::shared_ptr<vmsdk::devtool::iOS::VMSDKDebugICBase> inspector_client) {
  auto task_runner = task_runner_;
  WorkerTaskFunction task([inspector_client, task_runner](
                              Worker *worker, std::string p1, std::string p2) {
    VLOGE("inner Native init inspector");
    worker->js_runtime_->getRuntime()->InitInspector(inspector_client,
                                                     task_runner);
  });
  if (task_runner_) {
    task_runner_->PostTask(new WorkerClosure(this, std::move(task), "", ""));
  } else {
    VLOGD("task_runner_ is null when Worker::InitInspector");
  }
}
#endif

Napi::Value Worker::SetTimeout(const Napi::CallbackInfo &info) {
  Napi::Value callback = info[0];
  if (!callback.IsFunction()) {
    VLOGE("SetTimeout param0 callback is not a function");
    return info.Env().Undefined();
  }

  int32_t delay_time = 0;
  if (info.Length() > 1) {
    delay_time = info[1].ToNumber().Int32Value();
  }

  Worker *worker = reinterpret_cast<Worker *>(info.Data());
  if (!worker->running_) return info.Env().Undefined();
  TimeoutClosure *closure =
      new TimeoutClosure(worker, callback.As<Napi::Function>());
  worker->timer_node_map_[closure->closure_id_] =
      worker->task_runner_->PostDelayedTask(closure, delay_time);
  return Napi::Number::New(info.Env(), closure->closure_id_);
}

Napi::Value Worker::ClearTimeout(const Napi::CallbackInfo &info) {
  Napi::Value callback = info[0];
  if (!callback.IsNumber()) {
    VLOGE("CancelTimeout param0 callback is not a timer number!");
    return info.Env().Undefined();
  }

  uint32_t closure_id = callback.As<Napi::Number>().Uint32Value();
  Worker *worker = reinterpret_cast<Worker *>(info.Data());

  if (!worker->running_) return info.Env().Undefined();

  auto found = worker->timer_node_map_.find(closure_id);
  if (found != worker->timer_node_map_.end()) {
    std::shared_ptr<general::TimerNode> time_node = found->second.lock();
    worker->task_runner_->RemoveTask(std::move(time_node));
    worker->timer_node_map_.erase(found);
  }

  return info.Env().Undefined();
}

Napi::Value Worker::SetInterval(const Napi::CallbackInfo &info) {
  Napi::Value callback = info[0];
  if (!callback.IsFunction()) {
    VLOGE("SetInterval param0 callback is not a function");
    return info.Env().Undefined();
  }

  int32_t delay_time = 0;
  if (info.Length() > 1) {
    delay_time = info[1].ToNumber().Int32Value();
  }

  Worker *worker = reinterpret_cast<Worker *>(info.Data());
  if (!worker->running_) return info.Env().Undefined();

  TimeoutClosure *closure =
      new TimeoutClosure(worker, callback.As<Napi::Function>(), true);

  worker->timer_node_map_[closure->closure_id_] =
      worker->task_runner_->PostIntervalTask(closure, delay_time);

  return Napi::Number::New(info.Env(), closure->closure_id_);
}

#ifndef LARK_MINIAPP
Napi::Value Worker::ImportScripts(const Napi::CallbackInfo &info) {
  Worker *worker = reinterpret_cast<Worker *>(info.Data());
  if (!worker->running_ || !worker->workerDelegateExists()) {
    return info.Env().Undefined();
  }
  std::vector<std::string> scripts_vec;
  for (int i = 0; i < info.Length(); ++i) {
    Napi::Value msg = info[i];
    if (msg.IsString()) {
      std::string url = msg.ToString().Utf8Value();
      VLOGE("vmsdk importScripts url: %s", url.c_str());
      std::string script = worker->FetchJsWithUrlSync(url);
      VLOGE("vmsdk importScripts FetchJsWithUrlSync: %s", script.c_str());
      scripts_vec.push_back(script);
    }
  }

  Napi::HandleScope scp(info.Env());
  Napi::ContextScope contextScope(info.Env());

  for (int i = 0; i < scripts_vec.size(); ++i) {
    std::string script = scripts_vec[i];
    info.Env().RunScript(script.c_str());
    // process exception
    std::string exception;
    if (runtime::JSRuntimeUtils::CheckAndGetExceptionMsg(info.Env(),
                                                         exception)) {
      VLOGE("vmsdk Run script exception: %s\n", exception.c_str());
    }
  }
  return info.Env().Undefined();
}

Napi::Value Worker::Fetch(const Napi::CallbackInfo &info) {
  Worker *worker = reinterpret_cast<Worker *>(info.Data());
  if (!worker->running_ || info.Length() == 0) {
    return info.Env().Undefined();
  }

  Napi::EscapableHandleScope scp(info.Env());
  Napi::ContextScope contextScope(info.Env());

  Napi::Value param0 = info[0];
  Napi::Value params, resolve, reject;
  std::string urlStr, paramStr;
  void *bodyData = nullptr;
  int bodyLength = 0;

  // fetch param0 is a url string or a Request object
  if (param0.IsString()) {
    urlStr = param0.ToString().Utf8Value();
    VLOGD("fetch param0 is a url: %s\n", urlStr.c_str());

    if (info.Length() > 1) {
      params = info[1];
      if (!params.IsObject()) {
        VLOGE("Fetch param1 is not a object\n");
        return info.Env().Undefined();
      }
      net::HeadersWrap::UnWrapToNativeNapiValue(params.As<Napi::Object>(),
                                                "headers");
    }
  } else if (param0.IsObject()) {
    net::RequestWrap *wrap =
        Napi::ObjectWrap<net::RequestWrap>::Unwrap(param0.As<Napi::Object>());
    if (!wrap) {
      VLOGE("fetch param0 is not a Request Object\n");
      return info.Env().Undefined();
    } else {
      params = net::RequestWrap::ToNapiValue(info.Env(), wrap);
      urlStr =
          params.As<Napi::Object>().Get("url").As<Napi::String>().Utf8Value();
    }
  } else {
    VLOGE("fetch param0 is not string or object\n");
    return info.Env().Undefined();
  }

  if (!params.IsEmpty()) {
    // process binary request body
    auto request = params.As<Napi::Object>();
    if (request.Has("body") && request.Get("body").IsArrayBuffer()) {
      Napi::ArrayBuffer requestBody =
          request.Get("body").As<Napi::ArrayBuffer>();
      bodyData = requestBody.Data();
      bodyLength = requestBody.ByteLength();
    }

    Napi::Value json = info.Env().Global()["JSON"];
    Napi::Function stringify =
        json.As<Napi::Object>().Get("stringify").As<Napi::Function>();
    params = stringify.Call({params});
    std::string exception;
    if (runtime::JSRuntimeUtils::CheckAndGetExceptionMsg(info.Env(),
                                                         exception)) {
      VLOGE("stringify failed: %s", exception.c_str());
      worker->CallOnErrorCallback(exception);
    }
    paramStr = params.ToString().Utf8Value();
  }

  auto deferred = Napi::Promise::Deferred::New(info.Env());
  auto promise = deferred.Promise();

  auto responseDel = std::make_unique<net::ResponseDelegate>(
      std::move(deferred), info.Env(), worker);
  auto responseDelPtr = responseDel.get();
  worker->response_delgates_.insert(
      std::make_pair(responseDelPtr, std::move(responseDel)));
  worker->worker_delegate_->Fetch(urlStr, paramStr, bodyData, bodyLength,
                                  responseDelPtr);

  return scp.Escape(promise);
}

std::string Worker::FetchJsWithUrlSync(std::string url) {
  if (running_) {
    return worker_delegate_->FetchJsWithUrlSync(url);
  }
  return "";
}

bool Worker::workerDelegateExists() {
  return running_ && worker_delegate_->workerDelegateExists();
}

void Worker::registerDelegateFunction() {
  WorkerTaskFunction task = [](Worker *worker, std::string p1, std::string p2) {
    worker->registerDelegateFunctionAsync();
  };

  if (task_runner_) {
    task_runner_->PostTask(new WorkerClosure(this, std::move(task), "", ""));
  }
}

void Worker::registerDelegateFunctionAsync() {
  if (!running_ || worker_env_ == nullptr) {
    return;
  }

  Napi::HandleScope hscp(worker_env_);
  Napi::ContextScope contextScope(worker_env_);
  auto global = worker_env_.Global();
  if (global.Get("fetch").IsUndefined()) {
    global.Set("fetch", Napi::Function::New(worker_env_, Worker::Fetch, "fetch",
                                            (void *)this));
  }
  if (global.Get("importScripts").IsUndefined()) {
    global.Set("importScripts",
               Napi::Function::New(worker_env_, Worker::ImportScripts,
                                   "importScripts", (void *)this));
  }
}

#endif

void Worker::CallOnMessageCallback(std::string msg) {
  if (running_) {
    worker_delegate_->CallOnMessageCallback(msg);
  }
}

void Worker::CallOnErrorCallback(std::string msg) {
  if (running_) {
    worker_delegate_->CallOnErrorCallback(msg);
  }
}

void Worker::ExecutePendingJob() {
  if (js_runtime_ && js_runtime_->getRuntime()) {
    js_runtime_->getRuntime()->ExecutePendingJob();
  }
}

#ifdef ENABLE_CODECACHE
void Worker::OutputCodeCache() {
  if (use_cache_) {
    worker_env_.OutputCodeCache();
  }
}

#ifdef PROFILE_CODECACHE
void Worker::DumpCacheStatus() {
  if (use_cache_) {
    std::vector<std::pair<std::string, int>> *dump_vec =
        new std::vector<std::pair<std::string, int>>();
    worker_env_.DumpCacheStatus(dump_vec);
    if (!dump_vec->empty()) {
      for (size_t i = 0; i < Napi::Env::CACHE_META_NUMS; ++i) {
        std::pair<std::string, int> &it = dump_vec->at(i);
        VLOGD(" %s : %d ", it.first.c_str(), it.second);
      }
      for (size_t i = Napi::Env::CACHE_META_NUMS; i < dump_vec->size(); ++i) {
        std::pair<std::string, int> &it = dump_vec->at(i);
        VLOGD(" %d:[ name : %s, times: %d ]",
              (int)(i - Napi::Env::CACHE_META_NUMS), it.first.c_str(),
              it.second);
      }
    } else {
      VLOGD("[JsWorker] meet an empty cache vec");
    }
  }
}
#endif  // PROFILE_CODECACHE
#endif  // ENABLE_CODECACHE

void Worker::PostDelayedTask(general::Closure *task, int32_t delay_time) {
  if (task_runner_) {
    task_runner_->RunNowOrPostTaskAtFront(
        vmsdk::general::Bind([task, delay_time, this] {
          this->timer_node_map_[this->timer_id_generator++] =
              this->task_runner_->PostDelayedTask(task, delay_time);
        }));
  }
}

void Worker::RemoveTimerNode(uint32_t closure_id) {
  auto found = timer_node_map_.find(closure_id);
  if (found != timer_node_map_.end()) {
    timer_node_map_.erase(found);
  }
}

void Worker::RemoveAsyncTasks() {
  for (auto &it : timer_node_map_) {
    if (!it.second.expired()) {
      std::shared_ptr<general::TimerNode> time_node = it.second.lock();
      task_runner_->RemoveTask(std::move(time_node));
    }
  }
  timer_node_map_.clear();
}

void Worker::TimeoutClosure::Run() {
  if (!worker_->running_) return;

  Napi::Env env = worker_->Env();
  Napi::HandleScope scp(env);
  Napi::ContextScope contextScope(env);

  callback_.Value().Call({});
  std::string msg;
  if (runtime::JSRuntimeUtils::CheckAndGetExceptionMsg(env, msg)) {
    worker_->CallOnErrorCallback(msg);
  }
  if (!is_interval_) {
    worker_->RemoveTimerNode(this->closure_id_);
  }
  worker_->ExecutePendingJob();
}

}  // namespace worker
}  // namespace vmsdk
