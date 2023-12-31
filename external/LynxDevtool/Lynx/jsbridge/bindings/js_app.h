// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_BINDINGS_JS_APP_H_
#define LYNX_JSBRIDGE_BINDINGS_JS_APP_H_

#include <base/log/logging.h>

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/closure.h"
#include "config/config.h"
#include "jsbridge/bindings/api_call_back.h"
#include "jsbridge/bindings/timed_task_adapter.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/runtime/lynx_api_handler.h"
#include "jsbridge/runtime/template_delegate.h"
#include "jsbridge/utils/jsi_object_wrapper.h"
#include "tasm/generator/ttml_constant.h"
#include "tasm/radon/node_select_options.h"
#include "third_party/rapidjson/document.h"

namespace lynx {

namespace runtime {
class LynxRuntime;
class LynxApiHandler;
class AnimationFrameTaskHandler;
}  // namespace runtime
namespace piper {
class Runtime;
class App;
class LynxProxy;

// now this do nothing!
class AppProxy : public HostObject {
 public:
  AppProxy(std::weak_ptr<Runtime> rt, std::weak_ptr<App> app)
      : rt_(rt), native_app_(app) {}
  ~AppProxy() { LOGI("LYNX ~AppProxy destroy"); }

  virtual Value get(Runtime*, const PropNameID& name) override;
  virtual void set(Runtime*, const PropNameID& name,
                   const Value& value) override;
  virtual std::vector<PropNameID> getPropertyNames(Runtime& rt) override;

 protected:
  std::weak_ptr<Runtime> rt_;
  std::weak_ptr<App> native_app_;
};

class App : public std::enable_shared_from_this<App> {
 public:
  static std::shared_ptr<App> Create(
      int64_t rt_id, std::weak_ptr<Runtime> rt,
      runtime::TemplateDelegate* delegate,
      std::shared_ptr<JSIExceptionHandler> exception_handler,
      piper::Object nativeModuleProxy,
      std::unique_ptr<lynx::runtime::LynxApiHandler> api_handler,
      piper::TimedTaskAdapter timed_task_adapter) {
    auto app = std::shared_ptr<App>(new App(
        rt_id, rt, delegate, exception_handler, std::move(nativeModuleProxy),
        std::move(api_handler), std::move(timed_task_adapter)));
    // app->init();
    return app;
  }

  ~App() {}
  void destroy();
  void CallDestroyLifetimeFun();

  void setJsAppObj(piper::Object&& obj);
  std::string getAppGUID() { return app_guid_; }

  // load the app
  void loadApp(const std::string& appOriginName, tasm::PackageInstanceDSL dsl,
               tasm::PackageInstanceBundleModuleMode bundle_module_mode,
               const std::string& url);

  // component is decoded successfully. load jsSource.
  void OnDynamicJSSourcePrepared(const std::string& component_url);

  void QueryComponent(const std::string& url, ApiCallBack callback);

  // evaluate script from client
  void EvaluateScript(const std::string& url, std::string script,
                      ApiCallBack callback);

  // native call to js
  void onNativeAppReady();
  void onAppEnterBackground();
  void onAppEnterForeground();
  void onAppFirstScreen();
  void onAppReload(const lepus::Value& init_data);
  void OnLifecycleEvent(const lepus::Value& args);
  std::optional<Value> SendPageEvent(const std::string& page_name,
                                     const std::string& handler,
                                     const lepus::Value& info);
  void CallJSFunctionInLepusEvent(const int64_t component_id,
                                  const std::string& name,
                                  const lepus::Value& params);
  void NotifyUpdatePageData();
  void NotifyUpdateCardConfigData();
  void NotifyGlobalPropsUpdated(const lepus::Value& props);
  void CallFunction(const std::string& module_id, const std::string& method_id,
                    const piper::Array& arguments);
  void SendGlobalEvent(const std::string& name, const lepus::Value& arguments);
  void SendSsrGlobalEvent(const std::string& name,
                          const lepus::Value& arguments);
  void LoadSsrScript(const std::string& script);
  void SetupSsrJsEnv();
  void InvokeApiCallBack(ApiCallBack id);
  void InvokeApiCallBackWithValue(ApiCallBack id, const lepus::Value& value);
  void InvokeApiCallBackWithValue(ApiCallBack id, piper::Value value);
  ApiCallBack CreateCallBack(piper::Function func);

  void OnIntersectionObserverEvent(int32_t observer_id, int32_t callback_id,
                                   piper::Value data);

  // component
  void onComponentActivity(const std::string& action,
                           const std::string& component_id,
                           const std::string& parent_component_id,
                           const std::string& path,
                           const std::string& entry_name,
                           const lepus::Value& data);
  std::optional<Value> publicComponentEvent(const std::string& component_id,
                                            const std::string& handler,
                                            const lepus::Value& info);
  void onComponentPropertiesChanged(const std::string& component_id,
                                    const lepus::Value& properties);
  void OnComponentDataSetChanged(const std::string& component_id,
                                 const lepus::Value& data_set);
  void OnComponentSelectorChanged(const std::string& component_id,
                                  const lepus::Value& instance);
  void updateComponentData(const std::string& component_id, lepus_value&& data,
                           ApiCallBack callback,
                           runtime::UpdateDataType update_data_type);
  void selectComponent(const std::string& component_id,
                       const std::string& id_selector, const bool single,
                       ApiCallBack callBack);
  void InvokeUIMethod(tasm::NodeSelectRoot root,
                      tasm::NodeSelectOptions options, std::string method,
                      const piper::Value* params, ApiCallBack callback);
  void GetPathInfo(tasm::NodeSelectRoot root, tasm::NodeSelectOptions options,
                   ApiCallBack callBack);
  void GetFields(tasm::NodeSelectRoot root, tasm::NodeSelectOptions options,
                 std::vector<std::string> fields, ApiCallBack call_back);
  void SetNativeProps(tasm::NodeSelectRoot root,
                      tasm::NodeSelectOptions options,
                      lepus::Value native_props);
  void ElementAnimate(const std::string& component_id,
                      const std::string& id_selector, const lepus::Value& args);
  void triggerComponentEvent(const std::string& event_name, lepus_value&& msg);

  void triggerLepusGlobalEvent(const std::string& event_name,
                               lepus_value&& msg);

  void triggerWorkletFunction(std::string component_id,
                              std::string worklet_module_name,
                              std::string method_name, lepus::Value properties,
                              ApiCallBack callback);

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
  void OnHMRUpdate(const std::string& script);

  // js call to native
  void appDataChange(lepus_value&& data, ApiCallBack callback,
                     runtime::UpdateDataType update_data_type);
  bool batchedUpdateData(const piper::Value& data);

  void OnAppJSError(const piper::JSIException& exception);

  piper::Value loadScript(const std::string entry_name, const std::string& url);
  piper::Value readScript(const std::string entry_name, const std::string& url);
  piper::Value setTimeout(piper::Function func, int time);
  piper::Value setInterval(piper::Function func, int time);
  void clearTimeout(double task);
  piper::Value nativeModuleProxy();

  std::optional<piper::Value> getInitGlobalProps();
  piper::Value getI18nResource();
  void getContextDataAsync(const std::string& component_id,
                           const std::string& key, ApiCallBack callback);

  void AsyncRequestVSync(
      uintptr_t id, base::MoveOnlyClosure<void, int64_t, int64_t> callback);

  void LoadScriptAsync(const std::string& url, ApiCallBack callback);

  void SetCSSVariable(const std::string& component_id,
                      const std::string& id_selector,
                      const lepus::Value& properties);

  void onPiperInvoked(const std::string& module_name,
                      const std::string& method_name);

  void ReloadFromJS(const lepus::Value& value, ApiCallBack callback);

  void reportException(const std::string& msg, const std::string& stack,
                       int32_t error_code);

  std::shared_ptr<Runtime> GetRuntime();
  std::optional<lepus_value> ParseJSValueToLepusValue(
      const piper::Value& data, const std::string& component_id);
  void ConsoleLogWithLevel(const std::string& level, const std::string& msg);

  void I18nResourceChanged(const std::string& msg);

  bool IsDestroying() { return state_ == State::kDestroying; }

  piper::Value EnableCanvasOptimization();

  // For fiber
  void CallLepusMethod(const std::string& method_name, lepus::Value args,
                       const ApiCallBack& callback);

  void MarkTiming(const std::string& timing_flag, const std::string& key);

  static std::string GenerateDynamicComponentSourceUrl(
      const std::string& entry_name, const std::string& source_url);

 private:
  App(int64_t rt_id, std::weak_ptr<Runtime> rt,
      runtime::TemplateDelegate* delegate,
      std::shared_ptr<JSIExceptionHandler> exception_handler,
      piper::Object nativeModuleProxy,
      std::unique_ptr<lynx::runtime::LynxApiHandler> api_handler,
      piper::TimedTaskAdapter timed_task_adapter)
      : rt_(rt),
        js_app_(),
        delegate_(delegate),
        exception_handler_(exception_handler),
        timed_task_adapter_(std::move(timed_task_adapter)),
        nativeModuleProxy_(std::move(nativeModuleProxy)),
        api_handler_(std::move(api_handler)),
        app_dsl_(tasm::PackageInstanceDSL::TT),
        bundle_module_mode_(
            tasm::PackageInstanceBundleModuleMode::EVAL_REQUIRE_MODE) {
    jsi_object_wrapper_manager_ = std::make_shared<JSIObjectWrapperManager>();
    app_guid_ = std::to_string(rt_id);
  }

  enum class State {
    kNotStarted,     // only app created
    kStarted,        // app started loadApp
    kAppLoaded,      // app has been loaded successfully
    kAppLoadFailed,  // app load failed
    kDestroying,     // app is destroying
  };
  State state_ = State::kNotStarted;

  std::string app_origin_name_;
  std::string app_guid_;
  std::weak_ptr<Runtime> rt_;
  std::string i18_resource_;
  piper::Value js_app_;
  runtime::TemplateDelegate* const delegate_;
  std::shared_ptr<JSIExceptionHandler> exception_handler_;
  piper::TimedTaskAdapter timed_task_adapter_;
  piper::Object nativeModuleProxy_;
  ApiCallBackManager api_callback_manager_;
  std::unique_ptr<lynx::runtime::LynxApiHandler> api_handler_;
  std::shared_ptr<JSIObjectWrapperManager> jsi_object_wrapper_manager_;
  tasm::PackageInstanceDSL app_dsl_;
  tasm::PackageInstanceBundleModuleMode bundle_module_mode_;
  std::shared_ptr<LynxProxy> lynx_proxy_;
  std::string url_;
  piper::Value ssr_global_event_emitter_;

  bool IsJsAppStateValid() {
    return (js_app_.isObject() && state_ != State::kAppLoadFailed);
  }

  void handleLoadAppFailed(std::string error_msg);
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_BINDINGS_JS_APP_H_
