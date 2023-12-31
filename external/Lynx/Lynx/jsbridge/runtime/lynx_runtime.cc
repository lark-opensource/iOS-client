// Copyright 2017 The Lynx Authors. All rights reserved.
#include "jsbridge/runtime/lynx_runtime.h"

#include "base/debug/lynx_assert.h"
#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "base/perf_collector.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "jsbridge/jsi_executor.h"
#include "jsbridge/runtime/lynx_api_handler.h"
#include "jsbridge/runtime/runtime_constant.h"
#include "jsbridge/runtime/template_delegate.h"
#include "jsbridge/utils/utils.h"
#include "lepus/json_parser.h"
#include "shell/lynx_runtime_actor_holder.h"
#include "tasm/config.h"
#include "tasm/event_report_tracker.h"
#include "tasm/lynx_trace_event.h"

#if ENABLE_NAPI_BINDING
#include "jsbridge/napi/napi_environment.h"
#include "jsbridge/napi/napi_loader_js.h"
#endif
#include "jsbridge/module/module_delegate.h"

#if defined(MODE_HEADLESS)
#include "headless/headless_event_emitter.h"
#endif

// BINARY_KEEP_SOURCE_FILE
namespace lynx {
namespace runtime {
using base::PerfCollector;

namespace {

class JSIExceptionHandlerImpl : public piper::JSIExceptionHandler {
 public:
  explicit JSIExceptionHandlerImpl(LynxRuntime* runtime) : runtime_(runtime) {}
  ~JSIExceptionHandlerImpl() override = default;

  void onJSIException(const piper::JSIException& exception) override {
    // JSI exception from native should be sent to JSSDK formatting.
    // If there has any JSI exception in this process, those exception will be
    // sent to here too, then sent to JSSDK, then more exception will be
    // thrown... finally you will get endless loop. So we use this flag to avoid
    // endless loop.
    if (is_handling_exception_) {
      return;
    }
    // TODO: Use scoped flag to optimize here to ensure this flag can be reset
    // even if exception thrown during this period.
    is_handling_exception_ = true;
    // avoid call by global runtime and caush dangling pointer...
    if (!destroyed_) {
      runtime_->OnJSIException(exception);
    }
    is_handling_exception_ = false;
  }

  void Destroy() override { destroyed_ = true; }

 private:
  bool destroyed_ = false;
  bool is_handling_exception_ = false;

  LynxRuntime* const runtime_;
};

}  // namespace

lynx_thread_local(std::string*) LynxRuntime::js_core_source_ = nullptr;

LynxRuntime::LynxRuntime(const std::string& group_id, bool use_provider_js_env,
                         int32_t trace_id,
                         std::unique_ptr<TemplateDelegate> delegate,
                         bool enable_user_code_cache,
                         const std::string& code_cache_source_url,
                         bool enable_canvas_optimization)
    : group_id_(group_id),
      runtime_id_(GenerateRuntimeId()),
      trace_id_(trace_id),
      delegate_(std::move(delegate)),
      use_provider_js_env_(use_provider_js_env),
      enable_canvas_optimization_(enable_canvas_optimization),
      enable_user_code_cache_(enable_user_code_cache),
      code_cache_source_url_(code_cache_source_url) {}

LynxRuntime::~LynxRuntime() { Destroy(); }

void LynxRuntime::Init(
    const std::shared_ptr<lynx::piper::JSSourceLoader>& loader,
    const std::shared_ptr<lynx::piper::LynxModuleManager>& module_manager,
    const std::shared_ptr<runtime::LynxRuntimeObserver>& observer,
    std::shared_ptr<CanvasRuntimeObserver> canvas_runtime_observer,
    std::vector<std::string> preload_js_paths, bool force_reload_js_core,
    bool force_use_light_weight_js_engine) {
  LOGI("Init LynxRuntime group_id: " << group_id_ << " runtime_id: "
                                     << runtime_id_ << " this:" << this);

  tasm::TimingCollector::Scope<TemplateDelegate> scope(delegate_.get());

  if (canvas_runtime_observer) {
    canvas_runtime_observer_ = canvas_runtime_observer;
    canvas_runtime_observer_->RuntimeInit(runtime_id_);
  }

  js_executor_ = std::make_shared<lynx::piper::JSIExecutor>(
      std::make_shared<JSIExceptionHandlerImpl>(this), group_id_,
      module_manager, observer, force_use_light_weight_js_engine);

  LoadPreloadJSSource(loader, std::move(preload_js_paths),
                      force_reload_js_core);

  UpdateState(State::kStarted);
}

// TODO(heshan): load source in platform
void LynxRuntime::LoadPreloadJSSource(
    const std::shared_ptr<lynx::piper::JSSourceLoader>& loader,
    std::vector<std::string> preload_js_paths, bool force_reload_js_core) {
  if (!js_core_source_ || js_core_source_->length() <= 0 ||
      force_reload_js_core) {
    delete js_core_source_;
    static constexpr const char* core_js_name = "assets://lynx_core.js";
    js_core_source_ = new std::string(loader->LoadJSSource(core_js_name));
    DCHECK(js_core_source_->length() > 0);
    delegate_->OnCoreJSUpdated(*js_core_source_);
  }

  js_preload_sources_.emplace_back(kLynxCoreJSName, *js_core_source_);
  for (auto&& path : preload_js_paths) {
    std::string res = loader->LoadJSSource(path);
    if (res.length() > 0) {
      js_preload_sources_.emplace_back(std::move(path), std::move(res));
    }
  }
}

void LynxRuntime::UpdateState(State state) {
  state_ = state;
  switch (state_) {
    case State::kStarted: {
      PerfCollector::GetInstance().StartRecord(
          trace_id_, PerfCollector::Perf::JS_AND_TASM_ALL_READY);
      PerfCollector::GetInstance().StartRecord(
          trace_id_, PerfCollector::Perf::JS_FINISH_LOAD_CORE);
      PerfCollector::GetInstance().RecordPerfTime(
          trace_id_, PerfCollector::PerfStamp::LOAD_COREJS_START);
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_LOAD_CORE_START);
      TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY_VITALS, JS_FINISH_LOAD_CORE);
      // FIXME(wangboyong):invoke before decode...in fact in 1.4
      // here NeedGlobalConsole always return true...
      // bool need_console = delegate_->NeedGlobalConsole();
      bool need_console = true;
      js_executor_->loadPreJSBundle(
          use_provider_js_env_, js_preload_sources_, need_console,
          GetRuntimeId(), enable_user_code_cache_, code_cache_source_url_);

      js_preload_sources_.clear();
      TRACE_EVENT_END(LYNX_TRACE_CATEGORY_VITALS);
      PerfCollector::GetInstance().EndRecord(
          trace_id_, PerfCollector::Perf::JS_FINISH_LOAD_CORE);

      int32_t js_runtime_type =
          static_cast<int32_t>(js_executor_->getJSRuntimeType());
      PerfCollector::GetInstance().InsertDouble(
          trace_id_, PerfCollector::Perf::JS_RUNTIME_TYPE, js_runtime_type);
      LOGI("js_runtime_type :" << js_runtime_type << " " << this);

#if ENABLE_NAPI_BINDING
      PrepareNapiEnvironment();
#endif
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_LOAD_CORE_END);
      UpdateState(State::kJsCoreLoaded);
      break;
    }
    case State::kJsCoreLoaded: {
      TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, JS_CREATE_AND_LOAD_APP);
      app_ = js_executor_->createNativeAppInstance(
          GetRuntimeId(), delegate_.get(),
          std::make_unique<LynxApiHandler>(this),
          piper::TimedTaskAdapter(js_executor_->GetJSRuntime(), group_id_,
                                  use_provider_js_env_));
      PerfCollector::GetInstance().RecordPerfTime(
          trace_id_, PerfCollector::PerfStamp::LOAD_COREJS_END);
      LOGI(" lynxRuntime:" << this << " create APP " << app_.get());
      TryToLoadSsrScript();
      LoadApp();
      break;
    }
    case State::kSsrRuntimeReady: {
      OnSsrRuntimeReady();
      break;
    }
    case State::kRuntimeReady: {
      TryNotifyJSNativeAppIsReady();

      PerfCollector::GetInstance().EndRecord(trace_id_,
                                             PerfCollector::Perf::TTI);
      PerfCollector::GetInstance().InsertDouble(
          trace_id_, PerfCollector::Perf::CORE_JS,
          js_core_source_ ? js_core_source_->length() : 0);
      PerfCollector::GetInstance().EndRecord(
          trace_id_, PerfCollector::Perf::JS_AND_TASM_ALL_READY);
      TRACE_EVENT_INSTANT(LYNX_TRACE_CATEGORY_VITALS, ON_RUNTIME_READY, "color",
                          LYNX_TRACE_EVENT_VITALS_COLOR_ON_RUNTIME_READY);
      OnRuntimeReady();
      break;
    }
    default: {
      // TODO
      LOGE("unkown runtime state.");
      break;
    }
  }
}

#if ENABLE_NAPI_BINDING
void LynxRuntime::PrepareNapiEnvironment() {
  napi_environment_ = std::make_unique<piper::NapiEnvironment>(
      std::make_unique<piper::NapiLoaderJS>(std::to_string(runtime_id_)));
  auto proxy = piper::NapiRuntimeProxy::Create(GetJSRuntime(), delegate_.get());
  LOGI("napi attaching with proxy: " << proxy.get() << ", id: " << runtime_id_);
  if (proxy) {
    napi_environment_->SetRuntimeProxy(std::move(proxy));
    napi_environment_->Attach();
  }

  RegisterNapiModules();
}

void LynxRuntime::RegisterNapiModules() {
  if (canvas_runtime_observer_) {
    LOGI("napi registering canvas module");
    canvas_runtime_observer_->RuntimeAttach(napi_environment_.get());
  }
}
#endif

void LynxRuntime::call(base::closure func) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(std::move(func));
    return;
  }
  func();
}

void LynxRuntime::OnSsrScriptReady(std::string script) {
  ssr_script_ = std::move(script);
  TryToLoadSsrScript();
}

void LynxRuntime::TryToLoadSsrScript() {
  if (state_ != State::kJsCoreLoaded) {
    return;
  }
  if (!ssr_script_.empty()) {
    app_->SetupSsrJsEnv();
    app_->LoadSsrScript(ssr_script_);
    UpdateState(State::kSsrRuntimeReady);
    ssr_script_.clear();
  }
}

void LynxRuntime::OnSsrRuntimeReady() {
  if (state_ != State::kSsrRuntimeReady) {
    return;
  }
  LOGI("lynx ssr runtime ready");
  for (const auto& task : ssr_global_event_cached_tasks_) {
    task();
  }
  ssr_global_event_cached_tasks_.clear();
}

void LynxRuntime::CallJSFunction(const std::string& module_id,
                                 const std::string& method_id,
                                 const lepus::Value& arguments) {
  if (state_ == State::kDestroying) {
    return;
  }
  LynxFatal(arguments.IsArrayOrJSArray(), LYNX_ERROR_CODE_JAVASCRIPT,
            "the arguments should be array when CallJSFunction!");
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, module_id, method_id, arguments] {
      this->CallJSFunction(module_id, method_id, arguments);
    });
    return;
  }
  piper::Scope scope(*GetJSRuntime());
  auto array =
      piper::arrayFromLepus(*GetJSRuntime(), *(arguments.Array().Get()));
  if (!array) {
    GetJSRuntime()->reportJSIException(piper::JSINativeException(
        "CallJSFunction fail! Reason: Transfer lepus value to js value fail."));
    return;
  }
  CallFunction(module_id, method_id, *array);
}

void LynxRuntime::CallJSCallback(
    const std::shared_ptr<piper::ModuleCallback>& callback,
    int64_t id_to_delete) {
  uint64_t callback_thread_switch_end = base::CurrentSystemTimeMilliseconds();
  if (id_to_delete != piper::ModuleCallback::kInvalidCallbackId) {
    callbacks_.erase(id_to_delete);
  }

  if (callback == nullptr) {
    return;
  }

  auto iterator = callbacks_.find(callback->callback_id());
  if (iterator == callbacks_.end()) {
    if (callback->timing_collector_ != nullptr) {
      callback->timing_collector_->OnErrorOccurred(
          piper::NativeModuleStatusCode::FAILURE);
    }
    return;
  }
  uint64_t callback_call_start_time = base::CurrentSystemTimeMilliseconds();
  js_executor_->invokeCallback(callback, &iterator->second);
  LOGV(
      "LynxModule, LynxRuntime::CallJSCallback did invoke "
      "callback, id: "
      << callback->callback_id());
  callbacks_.erase(iterator);

  if (callback->timing_collector_ != nullptr) {
    callback->timing_collector_->EndCallCallback(callback_thread_switch_end,
                                                 callback_call_start_time);
  }

  if (state_ == State::kDestroying && callbacks_.empty()) {
    shell::LynxRuntimeActorHolder::GetInstance()->Release(GetRuntimeId());
    return;
  }
}

int64_t LynxRuntime::RegisterJSCallbackFunction(piper::Function func) {
  int64_t index = ++callback_id_index_;
  callbacks_.emplace(index, std::move(func));
  return index;
}

void LynxRuntime::CallJSApiCallback(piper::ApiCallBack callback) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (!callback.IsValid()) {
    return;
  }

  TRACE_EVENT(LYNX_TRACE_CATEGORY, nullptr,
              [&](lynx::perfetto::EventContext ctx) {
                ctx.event()->set_name("CallJSApiCallback:" +
                                      std::to_string(callback.id()));
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("CallbackID");
                debug->set_string_value(std::to_string(callback.id()));
              });
  app_->InvokeApiCallBack(callback);
}

void LynxRuntime::CallJSApiCallbackWithValue(piper::ApiCallBack callback,
                                             const lepus::Value& value) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (!callback.IsValid()) {
    return;
  }

  TRACE_EVENT(LYNX_TRACE_CATEGORY, nullptr,
              [&](lynx::perfetto::EventContext ctx) {
                ctx.event()->set_name("CallJSApiCallbackWithValue:" +
                                      std::to_string(callback.id()));
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("CallbackID");
                debug->set_string_value(std::to_string(callback.id()));
              });
  app_->InvokeApiCallBackWithValue(callback, value);
}

void LynxRuntime::CallJSApiCallbackWithValue(piper::ApiCallBack callback,
                                             piper::Value value) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (!callback.IsValid()) {
    return;
  }

  TRACE_EVENT(LYNX_TRACE_CATEGORY, nullptr,
              [&](lynx::perfetto::EventContext ctx) {
                ctx.event()->set_name("CallJSApiCallbackWithValue:" +
                                      std::to_string(callback.id()));
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("CallbackID");
                debug->set_string_value(std::to_string(callback.id()));
              });
  app_->InvokeApiCallBackWithValue(callback, std::move(value));
}

void LynxRuntime::CallIntersectionObserver(int32_t observer_id,
                                           int32_t callback_id,
                                           piper::Value data) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, observer_id, callback_id, data = std::move(data)]() mutable {
          app_->OnIntersectionObserverEvent(observer_id, callback_id,
                                            std::move(data));
        });
    return;
  }
  app_->OnIntersectionObserverEvent(observer_id, callback_id, std::move(data));
}

void LynxRuntime::CallFunction(const std::string& module_id,
                               const std::string& method_id,
                               const piper::Array& arguments) {
  if (state_ == State::kDestroying) {
    return;
  }
  app_->CallFunction(module_id, method_id, std::move(arguments));
}

void LynxRuntime::FlushJSBTiming(piper::NativeModuleInfo timing) {
  delegate_->FlushJSBTiming(std::move(timing));
}

void LynxRuntime::ProcessGlobalEventForSsr(const std::string& name,
                                           const lepus::Value& info) {
  auto infoArray = lepus::CArray::Create();
  infoArray->push_back(lepus::Value::ShallowCopy(info));
  SendSsrGlobalEvent(name, lepus::Value(infoArray));

  static constexpr const char* cacheIdentify = "from_ssr_cache";
  if (info.IsTable()) {
    info.Table()->SetValue(lepus::String(cacheIdentify), lepus::Value(true));
  }
}

void LynxRuntime::SendGlobalEvent(const std::string& name,
                                  const lepus::Value& info) {
  if (state_ == State::kDestroying) {
    return;
  }

  // There are two ways to trigger global events, the first one is triggered by
  // native, and the other is triggered by LynxContext. Here we process SSR
  // global events for the first way. Global events from LynxContext are
  // processed in LynxTemplateRender.
  if (state_ == State::kSsrRuntimeReady) {
    ProcessGlobalEventForSsr(name, info);
  }

  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, name, info] { app_->SendGlobalEvent(name, info); });
    return;
  }
  app_->SendGlobalEvent(name, info);
}

void LynxRuntime::SendSsrGlobalEvent(const std::string& name,
                                     const lepus::Value& info) {
  if (name.length() <= 0 || state_ == State::kDestroying ||
      state_ == State::kRuntimeReady) {
    return;
  }

  if (state_ == State::kSsrRuntimeReady) {
    app_->SendSsrGlobalEvent(name, info);
  } else {
    ssr_global_event_cached_tasks_.emplace_back(
        [this, name, info] { app_->SendSsrGlobalEvent(name, info); });
  }
}

void LynxRuntime::OnJSSourcePrepared(
    const std::string& page_name, tasm::PackageInstanceDSL dsl,
    tasm::PackageInstanceBundleModuleMode bundle_module_mode,
    const std::string& url) {
  tasm::TimingCollector::Scope<TemplateDelegate> scope(delegate_.get());
  app_loaded_ = true;
  page_name_ = page_name;
  tasm_dsl_ = dsl;
  tasm_bundle_module_mode_ = bundle_module_mode;
  url_ = url;
  LoadApp();
}

void LynxRuntime::OnDynamicJSSourcePrepared(const std::string& component_url) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, component_url] {
      app_->OnDynamicJSSourcePrepared(component_url);
    });
    return;
  }
  app_->OnDynamicJSSourcePrepared(component_url);
}

bool LynxRuntime::TryToDestroy() {
  if (state_ == State::kNotStarted) {
    return true;
  }
  state_ = State::kDestroying;

  // Firstly, clear all JSB callbacks that registered before destroy.
  callbacks_.clear();
  cached_tasks_.clear();
  ssr_global_event_cached_tasks_.clear();

  // Destroy app when js_executor_ exists and its runtime is valid, as well as
  // the app_ object exists. These procedures remains the same for Lynx stand
  // alone mode, as the js_executor_ and its runtime must be valid to destroy
  // the app_ object. But in shared context mode, we must check the validity of
  // the JSRuntime in case it is release by its shell owner or other Lynx
  // instance.
  if (js_executor_->GetJSRuntime() && js_executor_->GetJSRuntime()->Valid()) {
    app_->CallDestroyLifetimeFun();
  }

  if (callbacks_.empty()) {
    return true;
  } else {
    return false;
  }
}

void LynxRuntime::Destroy() {
  LOGI("LynxRuntime::Destroy, runtime_id: " << runtime_id_
                                            << " this: " << this);
  if (state_ == State::kNotStarted) {
    return;
  }
  cached_tasks_.clear();
  ssr_global_event_cached_tasks_.clear();
  callbacks_.clear();
#if ENABLE_NAPI_BINDING
  if (napi_environment_) {
    LOGI("napi detaching runtime, id: " << runtime_id_);
    napi_environment_->Detach();
  }
#endif
  if (canvas_runtime_observer_) {
    canvas_runtime_observer_->RuntimeDetach();
    canvas_runtime_observer_->RuntimeDestroy();
  }
  app_->destroy();
  app_ = nullptr;
  js_executor_->Destroy();
  js_executor_ = nullptr;

  // LynxRuntime now is not delegate-based so if we want to inject custom logic,
  // we need to do it here.
  // TODO(hongzhiyuan.hzy): Consider move this out in future refactor.
#if defined(MODE_HEADLESS)
  headless::EventEmitter<runtime::LynxRuntime*, std::string>::GetInstance()
      ->EmitSync(this, "RuntimeDestroy");
#endif
}

void LynxRuntime::OnNativeAppReady() {
  if (state_ == State::kDestroying) {
    return;
  }
  native_app_ready_ = true;
  TryNotifyJSNativeAppIsReady();

  // LynxRuntime now is not delegate-based so if we want to inject custom logic,
  // we need to do it here.
  // TODO(hongzhiyuan.hzy): Consider move this out in future refactor.
#if defined(MODE_HEADLESS)
  headless::EventEmitter<runtime::LynxRuntime*, std::string>::GetInstance()
      ->EmitSync(this, "OnNativeAppReady");
#endif
}

void LynxRuntime::OnAppEnterForeground() {
  if (state_ == State::kDestroying) {
    return;
  }
  auto task = [this]() {
    if (app_state_ == AppState::kForeground) {
      return;
    }
    app_state_ = AppState::kForeground;
    app_->onAppEnterForeground();
    if (canvas_runtime_observer_) {
      canvas_runtime_observer_->OnAppEnterForeground();
    }
  };
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(std::move(task));
    return;
  }
  task();
}

void LynxRuntime::OnAppEnterBackground() {
  if (state_ == State::kDestroying) {
    return;
  }
  auto task = [this]() {
    if (app_state_ == AppState::kBackground) {
      return;
    }
    app_state_ = AppState::kBackground;
    app_->onAppEnterBackground();
    if (canvas_runtime_observer_) {
      canvas_runtime_observer_->OnAppEnterBackground();
    }
  };
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(std::move(task));
    return;
  }
  task();
}

void LynxRuntime::OnAppFirstScreen() {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this] { app_->onAppFirstScreen(); });
    return;
  }
  app_->onAppFirstScreen();
}

void LynxRuntime::OnAppReload(const lepus::Value& data) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, data] { app_->onAppReload(data); });
    return;
  }
  app_->onAppReload(data);
}

void LynxRuntime::OnLifecycleEvent(const lepus::Value& args) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, args] { app_->OnLifecycleEvent(args); });
    return;
  }
  app_->OnLifecycleEvent(args);
}

void LynxRuntime::SendPageEvent(const std::string& page_name,
                                const std::string& handler,
                                const lepus::Value& info) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, page_name, handler, info] {
      app_->SendPageEvent(page_name, handler, info);
    });
    return;
  }
  app_->SendPageEvent(page_name, handler, info);
}

void LynxRuntime::CallJSFunctionInLepusEvent(const int64_t component_id,
                                             const std::string& name,
                                             const lepus::Value& params) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, component_id, name, params] {
      app_->CallJSFunctionInLepusEvent(component_id, name, params);
    });
    return;
  }
  app_->CallJSFunctionInLepusEvent(component_id, name, params);
}

void LynxRuntime::EvaluateScript(const std::string& url, std::string script,
                                 piper::ApiCallBack callback) {
  if (state_ == State::kDestroying) {
    return;
  }

  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, url, script = std::move(script), callback] {
          app_->EvaluateScript(url, std::move(script), callback);
        });
    return;
  }
  app_->EvaluateScript(url, std::move(script), callback);
}

void LynxRuntime::ConsoleLogWithLevel(const std::string& level,
                                      const std::string& msg) {
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, level, msg] { app_->ConsoleLogWithLevel(level, msg); });
    return;
  }
  app_->ConsoleLogWithLevel(level, msg);
}

void LynxRuntime::I18nResourceChanged(const std::string& msg) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, msg] { app_->I18nResourceChanged(msg); });
    return;
  }
  app_->I18nResourceChanged(msg);
}

void LynxRuntime::NotifyJSUpdatePageData() {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this,
         callbacks = std::move(native_update_finished_callbacks_)]() mutable {
          app_->NotifyUpdatePageData();
          delegate_->AfterNotifyJSUpdatePageData(std::move(callbacks));
        });
    return;
  }
  app_->NotifyUpdatePageData();
  delegate_->AfterNotifyJSUpdatePageData(
      std::move(native_update_finished_callbacks_));
}

void LynxRuntime::InsertCallbackForDataUpdateFinishedOnRuntime(
    base::closure callback) {
  if (state_ == State::kDestroying) {
    return;
  }
  native_update_finished_callbacks_.emplace_back(std::move(callback));
}

void LynxRuntime::NotifyJSUpdateCardConfigData() {
  if (state_ != State::kRuntimeReady) {
    return;
  }

  app_->NotifyUpdateCardConfigData();
}

void LynxRuntime::NotifyGlobalPropsUpdated(const lepus::Value& props) {
  if (state_ == State::kDestroying) {
    return;
  }

  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, props] { app_->NotifyGlobalPropsUpdated(props); });
    return;
  }
  app_->NotifyGlobalPropsUpdated(props);
}

void LynxRuntime::OnRuntimeReady() {
  if (state_ == State::kDestroying) {
    return;
  }

  LOGI("lynx runtime ready");

  delegate_->OnRuntimeReady();

  for (const auto& task : cached_tasks_) {
    task();
  }
  cached_tasks_.clear();
}

void LynxRuntime::OnJSIException(const piper::JSIException& exception) {
  if (state_ == State::kDestroying || !app_) {
    if (delegate_) {
      delegate_->OnErrorOccurred(
          LYNX_ERROR_CODE_JAVASCRIPT,
          std::string("report js exception directly: ") + exception.message());
    }
    return;
  }
  // JSI Exception is from native, we should send it to JSSDK. JSSDK will format
  // the error and send it to native for reporting error.
  if (app_) {
    app_->OnAppJSError(exception);
  }
}

void LynxRuntime::LoadApp() {
  if (!(state_ == State::kJsCoreLoaded || state_ == State::kSsrRuntimeReady) ||
      !app_loaded_) {
    return;
  }
  PerfCollector::GetInstance().StartRecord(
      trace_id_, PerfCollector::Perf::JS_FINISH_LOAD_APP);
  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::LOAD_APPJS_START);
  LOGI("lynx runtime loadApp, napi id:" << runtime_id_);
  // TODO(huzhanbo): This is needed by Lynx Network now, will be removed
  // after we fully switch to it.
  js_executor_->SetUrl(url_);

  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_LOAD_APP_START);
  // We should set enable_circular_data_check flag to js runtime ahead of load
  // app_service.js, so we can check all js data updated if necessary.
  auto js_runtime = js_executor_->GetJSRuntime();
  if (js_runtime) {
    // If devtool is enabled, enable circular data check always.
    bool enable_circular_data_check =
        (enable_circular_data_check_ ||
         base::LynxEnv::GetInstance().IsDevtoolEnabled());
    js_runtime->SetCircularDataCheckFlag(enable_circular_data_check);
    LOGI("[LynxRuntime] circular data check flag: "
         << enable_circular_data_check);
  }
  app_->loadApp(page_name_, tasm_dsl_, tasm_bundle_module_mode_, url_);
  tasm::TimingCollector::Instance()->Mark(tasm::TimingKey::SETUP_LOAD_APP_END);
  PerfCollector::GetInstance().EndRecord(
      trace_id_, PerfCollector::Perf::JS_FINISH_LOAD_APP);
  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::LOAD_APPJS_END);

  UpdateState(State::kRuntimeReady);
  return;
}

void LynxRuntime::TryNotifyJSNativeAppIsReady() {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady || !native_app_ready_) {
    return;
  }
  app_->onNativeAppReady();
}

void LynxRuntime::OnComponentActivity(const std::string& action,
                                      const std::string& component_id,
                                      const std::string& parent_component_id,
                                      const std::string& path,
                                      const std::string& entry_name,
                                      const lepus::Value& data) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, action, component_id, parent_component_id,
                                path, entry_name, data] {
      app_->onComponentActivity(action, component_id, parent_component_id, path,
                                entry_name, data);
    });
    return;
  }
  app_->onComponentActivity(action, component_id, parent_component_id, path,
                            entry_name, data);
}

void LynxRuntime::PublicComponentEvent(const std::string& component_id,
                                       const std::string& handler,
                                       const lepus::Value& info) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, component_id, handler, info] {
      app_->publicComponentEvent(component_id, handler, info);
    });
    return;
  }
  app_->publicComponentEvent(component_id, handler, info);
}

void LynxRuntime::OnComponentPropertiesChanged(const std::string& component_id,
                                               const lepus::Value& properties) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, component_id, properties] {
      app_->onComponentPropertiesChanged(component_id, properties);
    });
    return;
  }
  app_->onComponentPropertiesChanged(component_id, properties);
}

void LynxRuntime::OnComponentDataSetChanged(const std::string& component_id,
                                            const lepus::Value& data_set) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, component_id, data_set] {
      app_->OnComponentDataSetChanged(component_id, data_set);
    });
    return;
  }
  app_->OnComponentDataSetChanged(component_id, data_set);
}

void LynxRuntime::OnComponentSelectorChanged(const std::string& component_id,
                                             const lepus::Value& instance) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, component_id, instance] {
      app_->OnComponentSelectorChanged(component_id, instance);
    });
    return;
  }
  app_->OnComponentSelectorChanged(component_id, instance);
}

// for react
void LynxRuntime::OnReactComponentRender(const std::string& id,
                                         const lepus::Value& props,
                                         const lepus::Value& data,
                                         bool should_component_update) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, id, props, data,
                                should_component_update] {
      app_->OnReactComponentRender(id, props, data, should_component_update);
    });
    return;
  }
  app_->OnReactComponentRender(id, props, data, should_component_update);
}

void LynxRuntime::OnReactComponentDidUpdate(const std::string& id) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, id] { app_->OnReactComponentDidUpdate(id); });
    return;
  }
  app_->OnReactComponentDidUpdate(id);
}

void LynxRuntime::OnReactComponentDidCatch(const std::string& id,
                                           const lepus::Value& error) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, id, error] { app_->OnReactComponentDidCatch(id, error); });
    return;
  }
  app_->OnReactComponentDidCatch(id, error);
}

void LynxRuntime::OnReactComponentCreated(
    const std::string& entry_name, const std::string& path,
    const std::string& id, const lepus::Value& props, const lepus::Value& data,
    const std::string& parent_id, bool force_flush) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, entry_name, path, id, props, data, parent_id, force_flush] {
          app_->OnReactComponentCreated(entry_name, path, id, props, data,
                                        parent_id, force_flush);
        });
    return;
  }
  app_->OnReactComponentCreated(entry_name, path, id, props, data, parent_id,
                                force_flush);
}

void LynxRuntime::OnReactComponentUnmount(const std::string& id) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, id] { app_->OnReactComponentUnmount(id); });
    return;
  }
  app_->OnReactComponentUnmount(id);
}

void LynxRuntime::OnReactCardRender(const lepus::Value& data,
                                    bool should_component_update,
                                    bool force_flush) {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back(
        [this, data, should_component_update, force_flush] {
          app_->OnReactCardRender(data, should_component_update, force_flush);
        });
    return;
  }
  app_->OnReactCardRender(data, should_component_update, force_flush);
}

void LynxRuntime::OnReactCardDidUpdate() {
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this] { app_->OnReactCardDidUpdate(); });
    return;
  }
  app_->OnReactCardDidUpdate();
}

void LynxRuntime::OnHMRUpdate(const std::string& script) {
#if ENABLE_HMR
  if (state_ == State::kDestroying) {
    return;
  }
  if (state_ != State::kRuntimeReady) {
    cached_tasks_.emplace_back([this, script] {
      UpdateState(State::KPending);
      app_->OnHMRUpdate(script);
      UpdateState(State::kRuntimeReady);
    });
    return;
  }
  UpdateState(State::KPending);
  app_->OnHMRUpdate(script);
  UpdateState(State::kRuntimeReady);
#endif
}

void LynxRuntime::OnErrorOccurred(int32_t error_code,
                                  const std::string& message) {
  delegate_->OnErrorOccurred(error_code, message);
}

// issue: #1510
void LynxRuntime::OnModuleMethodInvoked(const std::string& module,
                                        const std::string& method,
                                        int32_t code) {
  delegate_->OnModuleMethodInvoked(module, method, code);
}

std::shared_ptr<piper::Runtime> LynxRuntime::GetJSRuntime() {
  return js_executor_->GetJSRuntime();
}

int64_t LynxRuntime::GenerateRuntimeId() {
  static std::atomic<int64_t> current_id_;
  return ++current_id_;
}

void LynxRuntime::AsyncRequestVSync(
    uintptr_t id, base::MoveOnlyClosure<void, int64_t, int64_t> callback,
    bool for_flush) {
  delegate_->AsyncRequestVSync(id, std::move(callback), for_flush);
}

void LynxRuntime::Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack) {
  delegate_->Report(std::move(stack));
}

}  // namespace runtime
}  // namespace lynx
