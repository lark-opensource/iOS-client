// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RUNTIME_LYNX_RUNTIME_H_
#define LYNX_JSBRIDGE_RUNTIME_LYNX_RUNTIME_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/closure.h"
#include "base/debug/lynx_assert.h"
#include "base/threading/task_runner_manufactor.h"
#include "base/threading/thread_local.h"
#include "config/config.h"
#include "jsbridge/bindings/api_call_back.h"
#include "jsbridge/bindings/js_app.h"
#include "jsbridge/javascript_source_loader.h"
#include "jsbridge/js_executor.h"
#include "jsbridge/module/lynx_module_callback.h"
#include "jsbridge/module/lynx_module_timing.h"
#include "jsbridge/runtime/lynx_api_handler.h"
#include "jsbridge/runtime/lynx_runtime_observer.h"
#include "jsbridge/runtime/template_delegate.h"
#include "lepus/lepus_global.h"
#include "tasm/generator/ttml_constant.h"
#include "third_party/krypton/glue/canvas_runtime_observer.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace piper {
class NapiEnvironment;
}

namespace runtime {

/*
 * now only run on js thread
 */
class LynxRuntime final {
 public:
  LynxRuntime(const std::string& group_id, bool use_provider_js_env,
              int32_t trace_id, std::unique_ptr<TemplateDelegate> delegate,
              bool enable_user_code_cache,
              const std::string& code_cache_source_url,
              bool enable_canvas_optimization);
  ~LynxRuntime();

  // now can ensure Init the first task for LynxRuntime
  void Init(
      const std::shared_ptr<lynx::piper::JSSourceLoader>& loader,
      const std::shared_ptr<lynx::piper::LynxModuleManager>& module_manager,
      const std::shared_ptr<runtime::LynxRuntimeObserver>& observer,
      std::shared_ptr<CanvasRuntimeObserver> canvas_runtime_observer,
      std::vector<std::string> preload_js_paths, bool force_reload_js_core,
      bool force_use_light_weight_js_engine);

  void CallJSCallback(const std::shared_ptr<piper::ModuleCallback>& callback,
                      int64_t id_to_delete);
  void CallJSApiCallback(piper::ApiCallBack callback);
  void CallJSApiCallbackWithValue(piper::ApiCallBack callback,
                                  const lepus::Value& value);
  void CallJSApiCallbackWithValue(piper::ApiCallBack callback,
                                  piper::Value value);
  int64_t RegisterJSCallbackFunction(piper::Function func);

  void CallJSFunction(const std::string& module_id,
                      const std::string& method_id,
                      const lepus::Value& arguments);

  void CallJSFunctionInLepusEvent(const int64_t component_id,
                                  const std::string& name,
                                  const lepus::Value& params);

  void CallIntersectionObserver(int32_t observer_id, int32_t callback_id,
                                piper::Value data);

  void CallFunction(const std::string& module_id, const std::string& method_id,
                    const piper::Array& arguments);
  void FlushJSBTiming(piper::NativeModuleInfo timing);
  void SendGlobalEvent(const std::string& name, const lepus::Value& info);
  void SendSsrGlobalEvent(const std::string& name, const lepus::Value& info);
  void OnSsrScriptReady(std::string script);
  void OnJSSourcePrepared(
      const std::string& page_name, tasm::PackageInstanceDSL dsl,
      tasm::PackageInstanceBundleModuleMode bundle_module_mode,
      const std::string& url);

  void call(base::closure func);
  void OnDynamicJSSourcePrepared(const std::string& component_url);
  void OnNativeAppReady();
  void OnAppEnterForeground();
  void OnAppEnterBackground();
  void OnAppFirstScreen();
  void OnAppReload(const lepus::Value& data);
  void OnLifecycleEvent(const lepus::Value& args);
  void SendPageEvent(const std::string& page_name, const std::string& handler,
                     const lepus::Value& info);

  void EvaluateScript(const std::string& url, std::string script,
                      piper::ApiCallBack callback);

  // component
  void OnComponentActivity(const std::string& action,
                           const std::string& component_id,
                           const std::string& parent_component_id,
                           const std::string& path,
                           const std::string& entry_name,
                           const lepus::Value& data = lepus::Value());

  void PublicComponentEvent(const std::string& component_id,
                            const std::string& handler,
                            const lepus::Value& info);

  void OnComponentPropertiesChanged(const std::string& component_id,
                                    const lepus::Value& properties);

  void OnComponentDataSetChanged(const std::string& component_id,
                                 const lepus::Value& data_set);

  void OnComponentSelectorChanged(const std::string& component_id,
                                  const lepus::Value& instance);

  void NotifyJSUpdatePageData();
  void NotifyJSUpdateCardConfigData();
  void InsertCallbackForDataUpdateFinishedOnRuntime(base::closure callback);

  void NotifyGlobalPropsUpdated(const lepus::Value& props);
  void OnHMRUpdate(const std::string& script);

  // for react
  void OnReactComponentRender(const std::string& id, const lepus::Value& props,
                              const lepus::Value& data,
                              bool should_component_update);
  void OnReactComponentDidUpdate(const std::string& id);
  void OnReactComponentDidCatch(const std::string& id,
                                const lepus::Value& error);
  void OnReactComponentCreated(const std::string& entry_name,
                               const std::string& path, const std::string& id,
                               const lepus::Value& props,
                               const lepus::Value& data,
                               const std::string& parent_id, bool force_flush);
  void OnReactComponentUnmount(const std::string& id);
  void OnReactCardRender(const lepus::Value& data, bool should_component_update,
                         bool force_flush);
  void OnReactCardDidUpdate();

  void OnJSIException(const piper::JSIException& exception);

  void OnErrorOccurred(int32_t error_code, const std::string& message);
  void OnModuleMethodInvoked(const std::string& module,
                             const std::string& method, int32_t error_code);
  bool EnableCanvasOptimization() { return enable_canvas_optimization_; }

  std::shared_ptr<piper::Runtime> GetJSRuntime();
  int64_t GetRuntimeId() const { return runtime_id_; }

  void SetCircularDataCheck(bool enable_check) {
    enable_circular_data_check_ = enable_check;
  }

  // report all tracker events to native facade.
  void Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack);

#if ENABLE_NAPI_BINDING
  piper::NapiEnvironment* GetNapiEnvironment() const {
    return napi_environment_.get();
  }
#endif

  // print js console log
  // level: log, warn, error, info, debug
  void ConsoleLogWithLevel(const std::string& level, const std::string& msg);

  void I18nResourceChanged(const std::string& msg);

  bool TryToDestroy();

  void AsyncRequestVSync(uintptr_t id,
                         base::MoveOnlyClosure<void, int64_t, int64_t> callback,
                         bool for_flush = false);

 private:
  enum class State {
    kNotStarted,       // only LynxRuntime created
    kStarted,          // LynxRuntime started init
    kJsCoreLoaded,     // js core is loaded
    kRuntimeReady,     // js runtime is ready
    kDestroying,       // js runtime is destroying
    KPending,          // js instance changed
    kSsrRuntimeReady,  // SSR scripts is evaluated, this state will not exist
                       // when CSR.
  };

  // use for record app state
  enum class AppState { kUnknown, kForeground, kBackground };

  void Destroy();
  void LoadPreloadJSSource(
      const std::shared_ptr<lynx::piper::JSSourceLoader>& loader,
      std::vector<std::string> preload_js_paths, bool force_reload_js_core);
  void UpdateState(State state);
  void OnRuntimeReady();
  void OnSsrRuntimeReady();
  void TryToLoadSsrScript();
  void ProcessGlobalEventForSsr(const std::string& name,
                                const lepus::Value& info);

  void LoadApp();
  void TryNotifyJSNativeAppIsReady();

#if ENABLE_NAPI_BINDING
  void PrepareNapiEnvironment();
  void RegisterNapiModules();
#endif

  static int64_t GenerateRuntimeId();

  const std::string group_id_;
  const int64_t runtime_id_;
  const int32_t trace_id_;
  const std::unique_ptr<runtime::TemplateDelegate> delegate_;
  std::shared_ptr<lynx::piper::JSExecutor> js_executor_;
  std::shared_ptr<piper::App> app_;
#if ENABLE_NAPI_BINDING
  std::unique_ptr<piper::NapiEnvironment> napi_environment_;
#else
  std::unique_ptr<bool> napi_environment_placeholder_;
#endif

  ALLOW_UNUSED_TYPE bool is_helium_canvas_used_ = false;

  // TODO(zhangmin): 动态下发core.js完成后移除下面两个成员的static。
  //  static int js_core_size_;
  static lynx_thread_local(std::string*) js_core_source_;

  std::vector<std::pair<std::string, std::string>> js_preload_sources_;

  State state_ = State::kNotStarted;
  AppState app_state_ = AppState::kUnknown;

  // Flag to determine if app-service.js is ready.
  bool app_loaded_{false};
  // Useless now. Use app_loaded_ to check if app-service.js is ready. Do not
  // use page_name_ to check.
  std::string page_name_;

  tasm::PackageInstanceDSL tasm_dsl_ = tasm::PackageInstanceDSL::TT;
  tasm::PackageInstanceBundleModuleMode tasm_bundle_module_mode_ =
      tasm::PackageInstanceBundleModuleMode::EVAL_REQUIRE_MODE;
  bool native_app_ready_ = false;  // TemplateAssembler is loaded.

  // store tasks will run after runtime ready
  std::vector<base::closure> cached_tasks_;

  std::vector<base::closure> ssr_global_event_cached_tasks_;

  // store callbacks that the data has been updated for runtime.
  std::vector<base::closure> native_update_finished_callbacks_;
  std::string ssr_script_;

  std::unordered_map<int64_t, piper::ModuleCallbackFunctionHolder> callbacks_;
  int64_t callback_id_index_ = 0;
  bool use_provider_js_env_ = false;
  bool enable_canvas_optimization_ = false;
  bool enable_user_code_cache_ = false;
  bool enable_circular_data_check_{false};
  std::string code_cache_source_url_;

  std::shared_ptr<CanvasRuntimeObserver> canvas_runtime_observer_{nullptr};

  LynxRuntime(const LynxRuntime&) = delete;
  LynxRuntime& operator=(const LynxRuntime&) = delete;

  std::string url_;
};

}  // namespace runtime
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RUNTIME_LYNX_RUNTIME_H_
