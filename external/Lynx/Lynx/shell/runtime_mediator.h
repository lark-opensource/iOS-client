// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RUNTIME_MEDIATOR_H_
#define LYNX_SHELL_RUNTIME_MEDIATOR_H_

#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/closure.h"
#include "jsbridge/runtime/template_delegate.h"
#include "jsbridge/runtime/update_data_type.h"
#include "shell/common/vsync_monitor.h"
#include "shell/external_source_loader.h"
#include "shell/lynx_actor.h"
#include "shell/lynx_card_cache_data_manager.h"
#include "shell/lynx_data_dispatcher.h"
#include "shell/lynx_engine.h"
#include "shell/native_facade.h"
#include "tasm/radon/node_select_options.h"

namespace lynx {
namespace shell {

// ensure run on js thread, lifecycle manage by LynxRuntime
class RuntimeMediator : public runtime::TemplateDelegate,
                        public LynxDataDispatcher {
 public:
  RuntimeMediator(
      const std::shared_ptr<LynxActor<NativeFacade>>& facade_actor,
      const std::shared_ptr<LynxActor<LynxEngine>>& engine_actor,
      const std::shared_ptr<LynxCardCacheDataManager>& card_cached_data_mgr,
      const fml::RefPtr<fml::TaskRunner>& js_runner,
      std::unique_ptr<ExternalSourceLoader> external_source_loader,
      std::shared_ptr<lynx::piper::JSSourceLoader> js_source_loader)
      : facade_actor_(facade_actor),
        engine_actor_(engine_actor),
        card_cached_data_mgr_(card_cached_data_mgr),
        js_runner_(js_runner),
        external_source_loader_(std::move(external_source_loader)),
        js_source_loader_(js_source_loader) {}
  ~RuntimeMediator() override = default;
  // inherit from TemplateDelegate
  void UpdateDataByJS(runtime::UpdateDataTask task) override;
  void UpdateBatchedDataByJS(std::vector<runtime::UpdateDataTask> tasks,
                             uint64_t update_task_id) override;
  std::vector<lynx::shell::CacheDataOp> FetchUpdatedCardData() override;
  std::string GetJSSource(const std::string& entry_name,
                          const std::string& name) override;
  std::string GetLynxJSAsset(const std::string& name) override;

  lepus::Value GetTasmEncodedData() override;
  lepus::Value GetNativeInitData() override;
  lepus::Value GetInitGlobalProps() override;
  void GetComponentContextDataAsync(const std::string& component_id,
                                    const std::string& key,
                                    piper::ApiCallBack callback) override;
  bool LoadDynamicComponentFromJS(const std::string& url,
                                  const piper::ApiCallBack& callback) override;
  void LoadScriptAsync(const std::string& url,
                       piper::ApiCallBack callback) override;
  void OnRuntimeReady() override;
  void OnErrorOccurred(int32_t error_code, const std::string& msg) override;
  void OnModuleMethodInvoked(const std::string& module,
                             const std::string& method, int32_t code) override;
  void UpdateComponentData(runtime::UpdateDataTask task) override;
  void SelectComponent(const std::string& component_id,
                       const std::string& id_selector, const bool single,
                       piper::ApiCallBack callBack) override;
  void InvokeUIMethod(tasm::NodeSelectRoot root,
                      tasm::NodeSelectOptions options, std::string method,
                      std::unique_ptr<piper::PlatformValue> params,
                      piper::ApiCallBack callback) override;
  void GetPathInfo(tasm::NodeSelectRoot root, tasm::NodeSelectOptions options,
                   piper::ApiCallBack call_back) override;
  void GetFields(tasm::NodeSelectRoot root, tasm::NodeSelectOptions options,
                 std::vector<std::string> fields,
                 piper::ApiCallBack call_back) override;
  void ElementAnimate(const std::string& component_id,
                      const std::string& id_selector,
                      const lepus::Value& args) override;
  void TriggerComponentEvent(const std::string& event_name,
                             const lepus::Value& msg) override;
  void TriggerLepusGlobalEvent(const std::string& event_name,
                               const lepus::Value& msg) override;
  void InvokeLepusComponentCallback(const int64_t callback_id,
                                    const std::string& entry_name,
                                    const lepus::Value& data) override;

  void TriggerWorkletFunction(std::string component_id,
                              std::string worklet_module_name,
                              std::string method_name, lepus::Value args,
                              piper::ApiCallBack callback) override;

  bool NeedGlobalConsole() override;
  bool SupportComponentJS() override;
  void OnCoreJSUpdated(std::string core_js) override;

  void RunOnJSThread(base::closure closure) override;

  void AfterNotifyJSUpdatePageData(
      std::vector<base::closure> callbacks) override;
  // inherit from LynxDataDispatcher
  void OnCardDecoded(tasm::TemplateBundle bundle,
                     const lepus::Value& global_props) override;
  void OnComponentDecoded(tasm::TemplateBundle bundle) override;
  void OnCardConfigDataChanged(const lepus::Value& data) override;

  void set_vsync_monitor(std::shared_ptr<VSyncMonitor> vsync_monitor) {
    vsync_monitor_ = vsync_monitor;
  }

  void AsyncRequestVSync(uintptr_t id,
                         base::MoveOnlyClosure<void, int64_t, int64_t> callback,
                         bool for_flush) override;

  void SetCSSVariables(const std::string& component_id,
                       const std::string& id_selector,
                       const lepus::Value& properties) override;

  void SetNativeProps(tasm::NodeSelectRoot root,
                      const tasm::NodeSelectOptions& options,
                      const lepus::Value& native_props) override;

  void ReloadFromJS(runtime::UpdateDataTask task) override;

  lepus::Value GetNativeCardConfigData() override;
  bool GetEnableAttributeTimingFlag() const override;
  const std::string& GetTargetSDKVersion() override;
  void SetTiming(tasm::Timing timing) override;
  // report all tracker events to native facade.
  void Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack) override;
  void FlushJSBTiming(piper::NativeModuleInfo timing) override;

  // For fiber
  void CallLepusMethod(const std::string& method_name, lepus::Value args,
                       const piper::ApiCallBack& callback,
                       uint64_t trace_flow_id) override;

  RuntimeMediator(const RuntimeMediator&) = delete;
  RuntimeMediator& operator=(const RuntimeMediator&) = delete;
  RuntimeMediator(RuntimeMediator&&) = delete;
  RuntimeMediator& operator=(RuntimeMediator&&) = delete;

 private:
  // vsync
  using VSyncCallback = base::MoveOnlyClosure<void, int64_t, int64_t>;
  using VSyncCallbackMap = std::unordered_map<uintptr_t, VSyncCallback>;
  VSyncCallbackMap& vsync_callbacks() { return vsync_callbacks_; }
  void SwapVSyncCallbacks(std::vector<VSyncCallback>& swap_callbacks);
  void RequestVSync();
  void DoFrame(int64_t frame_start_time, int64_t frame_end_time);

  std::shared_ptr<LynxActor<NativeFacade>> facade_actor_;

  std::shared_ptr<LynxActor<LynxEngine>> engine_actor_;

  std::shared_ptr<LynxCardCacheDataManager> card_cached_data_mgr_;

  fml::RefPtr<fml::TaskRunner> js_runner_;

  tasm::TemplateBundle card_bundle_;
  std::unordered_map<std::string, tasm::TemplateBundle> component_bundles_;

  lepus::Value init_global_props_;

  lepus::Value native_config_;
  // for vsync
  std::shared_ptr<VSyncMonitor> vsync_monitor_{nullptr};
  bool has_pending_vsync_request_{false};
  VSyncCallbackMap vsync_callbacks_;
  // used for canvas flush draw calls
  VSyncCallbackMap flush_vsync_callbacks_;

  std::unique_ptr<ExternalSourceLoader> external_source_loader_;
  std::shared_ptr<lynx::piper::JSSourceLoader> js_source_loader_;

  lepus::Value card_config_;  // cache the init card config data
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_RUNTIME_MEDIATOR_H_
