// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_TEMPLATE_ASSEMBLER_H_
#define LYNX_TASM_TEMPLATE_ASSEMBLER_H_

#include <chrono>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/closure.h"
#include "base/debug/lynx_assert.h"
#include "base/log/logging.h"
#include "base/perf_collector.h"
#include "base/threading/thread_local.h"
#include "config/config.h"
#include "jsbridge/lepus_context_observer.h"
#include "jsbridge/runtime/template_delegate.h"
#include "jsbridge/runtime/update_data_type.h"
#include "lepus/lepus_global.h"
#include "lepus/vm_context.h"
#include "shell/lynx_data_dispatcher.h"
#include "tasm/binary_decoder/lynx_template_bundle.h"
#include "tasm/i18n.h"
#include "tasm/moulds.h"
#include "tasm/page_config.h"
#include "tasm/page_delegate.h"
#include "tasm/page_proxy.h"
#include "tasm/react/list_node.h"
#include "tasm/template_binary_reader.h"
#include "tasm/template_data.h"
#include "tasm/template_entry.h"
#include "tasm/template_themed.h"
#include "tasm/timing.h"
#include "tasm/touch_event_handler.h"
#include "third_party/fml/task_runner.h"
#include "third_party/rapidjson/document.h"

namespace lynx {

namespace piper {
class ApiCallBack;
}  // namespace piper

namespace lepus {
class Context;
}

namespace ssr {
class ServerDomConstructor;
}

namespace tasm {
class CSSStyleSheetManager;
class ComponentMould;
class DynamicComponentLoader;
class DevtoolAgent;
class ElementManager;
class I18n;
struct CalculatedViewport;
class LynxGetUIResult;
static constexpr const char* DEFAULT_ENTRY_NAME = "__Card__";
// define scene for HMR
enum class ComponentUpdateType : uint32_t {
  Update = 0,
  Rerender,
};

#define CARD_CONFIG_STR "__card_config_"
#define CARD_CONFIG_THEME "theme"

struct BASE_EXPORT_FOR_DEVTOOL HmrData {
  HmrData(const std::string& template_url_,
          const std::string& url_download_template_,
          std::vector<uint8_t>& tem_data)
      : template_url(std::move(template_url_)),
        url_download_template(std::move(url_download_template_)),
        template_bin_data(std::move(tem_data)) {}
  // the url of "template.js" for full reload card or dynamic-component
  std::string template_url;
  // the url of "update.template.js" using for part-decode about card or
  // dynamic-component
  std::string url_download_template;
  std::vector<uint8_t> template_bin_data;  // binary of "template.js"
};
using LightComponentInfo =
    std::unordered_map<std::string, std::tuple<std::vector<int>, int32_t>>;

// base class released after derived class,
// ensure vm context released after lepus value
class TemplateEntryHolder {
 public:
  TemplateEntryHolder() = default;
  virtual ~TemplateEntryHolder() = default;

 protected:
  std::unordered_map<std::string, std::shared_ptr<TemplateEntry>>
      template_entries_;

  // template bundles for preloading dynamic component
  std::unordered_map<std::string, LynxTemplateBundle> preload_template_bundles_;
};

// AirTouchEventHandler can't be included directly in template_assembler.h
// because of rock release
// TODO(renpengcheng): when AirTouchEventHandler was deleted, delete the base
// class
class AirTouchEventHandlerBase {
 public:
  AirTouchEventHandlerBase() = default;
  virtual ~AirTouchEventHandlerBase() = default;
  // HandleTouchEvent handle touch event
  virtual void HandleTouchEvent(TemplateAssembler* tasm,
                                const std::string& page_name,
                                const std::string& name, int tag, float x,
                                float y, float client_x, float client_y,
                                float page_x, float page_y){};

  // HandleCustomEvent customEvent for example: x-element's custom event
  virtual void HandleCustomEvent(TemplateAssembler* tasm,
                                 const std::string& name, int tag,
                                 const lepus::Value& params,
                                 const std::string& pname){};

  // SendPageEvent air life function and global event
  virtual void SendPageEvent(TemplateAssembler* tasm,
                             const std::string& handler,
                             const lepus::Value& info) const {};

  // SendComponentEvent send Component related lifecycle event
  virtual void SendComponentEvent(TemplateAssembler* tasm,
                                  const std::string& event_name,
                                  const int component_id,
                                  const lepus::Value& params,
                                  const std::string& param_name){};
  // Only for the situation when child component needs to send message to parent
  virtual size_t TriggerComponentEvent(TemplateAssembler* tasm,
                                       const std::string& event_name,
                                       const lepus::Value& data) = 0;
};

class TemplateAssembler final
    : public std::enable_shared_from_this<TemplateAssembler>,
      public TemplateEntryHolder,
      public TemplateBinaryReader::PageConfigger {
 public:
  class Delegate : public PageDelegate,
                   public TouchEventHandler::Delegate,
                   public shell::LynxDataDispatcher {
   public:
    Delegate() = default;
    ~Delegate() override = default;

    virtual void OnDataUpdated() = 0;
    virtual void OnTasmFinishByNative() = 0;
    virtual void OnTemplateLoaded(const std::string& url) = 0;
    virtual void OnSSRHydrateFinished(const std::string& url) = 0;
    virtual void OnErrorOccurred(int32_t error_code,
                                 const std::string& msg) = 0;
    virtual void OnFirstLoadPerfReady(
        const std::unordered_map<int32_t, double>& perf,
        const std::unordered_map<int32_t, std::string>& perf_timing) = 0;
    virtual void OnUpdatePerfReady(
        const std::unordered_map<int32_t, double>& perf,
        const std::unordered_map<int32_t, std::string>& perf_timing) = 0;
    virtual void OnDynamicComponentPerfReady(
        const std::unordered_map<std::string,
                                 base::PerfCollector::DynamicComponentPerfInfo>&
            dynamic_component_perf) = 0;
    virtual void OnConfigUpdated(const lepus::Value& data) = 0;
    virtual void OnPageConfigDecoded(
        const std::shared_ptr<tasm::PageConfig>& config) = 0;

    // synchronous
    virtual std::string TranslateResourceForTheme(
        const std::string& res_id, const std::string& theme_key) = 0;

    virtual void GetI18nResource(const std::string& key,
                                 const std::string& fallback_url) = 0;
    virtual void SetTiming(tasm::Timing timing) = 0;

    virtual void OnNativeAppReady() = 0;
    virtual void OnJSSourcePrepared(
        const std::string& page_name, tasm::PackageInstanceDSL dsl,
        tasm::PackageInstanceBundleModuleMode bundle_module_mode,
        const std::string& url) = 0;
    virtual void CallJSApiCallback(piper::ApiCallBack callback) = 0;
    virtual void CallJSApiCallbackWithValue(piper::ApiCallBack callback,
                                            const lepus::Value& value) = 0;
    virtual void CallJSFunction(const std::string& module_id,
                                const std::string& method_id,
                                const lepus::Value& arguments) = 0;
    virtual void OnDataUpdatedByNative(const lepus::Value& data,
                                       const bool read_only, const bool reset,
                                       base::closure callback) = 0;
    virtual void OnJSAppReload(const lepus::Value& data) = 0;
    virtual void OnLifecycleEvent(const lepus::Value& args) = 0;
    virtual void NotifyGlobalPropsUpdated(const lepus::Value& value) = 0;
    virtual void OnDynamicJSSourcePrepared(
        const std::string& component_url) = 0;
    virtual void PrintMsgToJS(const std::string& level,
                              const std::string& msg) = 0;
    virtual void OnI18nResourceChanged(const std::string& res) = 0;
    virtual void RequestVsync(
        uintptr_t id,
        base::MoveOnlyClosure<void, int64_t, int64_t> callback) = 0;
    virtual lepus::Value TriggerLepusMethod(const std::string& method_name,
                                            const lepus::Value& arguments) = 0;
    virtual void TriggerLepusMethodAsync(const std::string& method_name,
                                         const lepus::Value& arguments) = 0;
    virtual void HmrEvalJsCode(const std::string& source_code) = 0;
    virtual void InvokeUIMethod(LynxGetUIResult ui_result,
                                const std::string& method,
                                std::unique_ptr<piper::PlatformValue> params,
                                piper::ApiCallBack callback) = 0;

    virtual void OnSsrScriptReady(std::string script) = 0;
    // air-runtime methods
    // TODO(zhangqun.29):air-runtime will refactor to lepus-runtime
    virtual lepus::Value TriggerBridgeSync(
        const std::string& method_name,
        const lynx::lepus::Value& arguments) = 0;
    virtual void TriggerBridgeAsync(
        lepus::Context* context, const std::string& method_name,
        const lynx::lepus::Value& arguments,
        std::unique_ptr<lepus::Value> callback_closure) = 0;
    virtual uint32_t SetTimeOut(lepus::Context* context,
                                std::unique_ptr<lepus::Value> closure,
                                int64_t delay_time) = 0;
    virtual uint32_t SetTimeInterval(lepus::Context* context,
                                     std::unique_ptr<lepus::Value> closure,
                                     int64_t interval_time) = 0;
    virtual void RemoveTimeTask(uint32_t task_id) = 0;
    virtual void InvokeAirCallback(int64_t id, const std::string& entry_name,
                                   const lepus::Value& data) = 0;
  };

  class PerfHandler : public base::PerfCollector::PerfReadyDelegate {
   public:
    PerfHandler(std::weak_ptr<TemplateAssembler> tasm,
                fml::RefPtr<fml::TaskRunner> tasm_runner);
    virtual ~PerfHandler() {}
    virtual void OnFirstLoadPerfReady(
        const std::unordered_map<int32_t, double>& perf,
        const std::unordered_map<int32_t, std::string>& perf_timing);
    virtual void OnUpdatePerfReady(
        const std::unordered_map<int32_t, double>& perf,
        const std::unordered_map<int32_t, std::string>& perf_timing);
    virtual void OnDynamicComponentPerfReady(
        const std::unordered_map<std::string,
                                 base::PerfCollector::DynamicComponentPerfInfo>&
            dynamic_component_perf);

   private:
    std::weak_ptr<TemplateAssembler> tasm_;

    // FIXME(heshan):hack, ensure tasm releases on tasm thread
    // need refactor to invoke LynxActor
    fml::RefPtr<fml::TaskRunner> tasm_runner_;
  };

  class Scope {
   public:
    explicit Scope(TemplateAssembler* tasm);
    ~Scope();

    Scope(const Scope&) = delete;
    Scope& operator=(const Scope&) = delete;
    Scope(Scope&&) = delete;
    Scope& operator=(Scope&&) = delete;

   private:
    bool scoped_ = false;
  };

  TemplateAssembler(Delegate& delegate, std::unique_ptr<ElementManager> client,
                    int32_t trace_id);
  ~TemplateAssembler() override;

  void Init(fml::RefPtr<fml::TaskRunner> tasm_runner);

  void LoadTemplate(const std::string& url, std::vector<uint8_t> source,
                    const std::shared_ptr<TemplateData>& template_data);

  void LoadTemplateBundle(const std::string& url,
                          LynxTemplateBundle template_bundle,
                          const std::shared_ptr<TemplateData>& template_data);

  // Diff the entire tree using the new template_data.
  // Refresh the card and component's lifecycle like a new loaded template.
  // No need to decode and set page config.
  void ReloadTemplate(const std::shared_ptr<TemplateData>& template_data,
                      UpdatePageOption& update_page_option);

  void ReloadTemplate(const std::shared_ptr<TemplateData>& template_data,
                      const lepus::Value& global_props,
                      UpdatePageOption& update_page_option);

  // used in lynx.reload() api for FE.
  void ReloadFromJS(const runtime::UpdateDataTask& task);

  // Render page with page data that rendered on server side.
  void RenderPageWithSSRData(
      std::vector<uint8_t> data,
      const std::shared_ptr<TemplateData>& template_data);

  void LoadComponentWithCallback(const std::string& url,
                                 std::vector<uint8_t> source, bool sync,
                                 int32_t callback_id);

  void InvokeLoadComponentCallback(int32_t callback_id,
                                   const lepus::Value& value);

  void ReportRuntimeReady();
  void ReportError(int32_t error_code, const std::string& msg);
  void ReportLepusNGError(int32_t error_code, const std::string& msg);
  void SetSourceMapRelease(const lepus::Value& source_map_release);

  lepus::Value ProcessorDataWithName(const lepus::Value& input,
                                     const std::string& functionName);

  void UpdateGlobalProps(const lepus::Value& data, bool need_render = true);

  void SendTouchEvent(std::string name, int tag, float x, float y,
                      float client_x, float client_y, float page_x,
                      float page_y);
  void SendCustomEvent(std::string name, int tag, const lepus::Value& params,
                       std::string pname);
  void OnPseudoStatusChanged(int32_t id, uint32_t pre_status,
                             uint32_t current_status);

  // input: single element id
  // packaged by vector,
  // and then invoke SendDynamicComponentEvent(const std::vector<int>&
  // impl_id_list)
  // TODO(zhoupeng): This overloaded method is of limited use and leads to a
  // decrease in code readability, consider deleting it later
  void SendDynamicComponentEvent(const std::string& url,
                                 const lepus::Value& err, int tag);

  // input: uid
  // find dynamic component element id by uid,
  // and then invoke SendDynamicComponentEvent(const std::vector<int>&
  // impl_id_list)
  void SendDynamicComponentEvent(const std::string& url,
                                 const lepus::Value& err,
                                 const std::vector<uint32_t>& uid_list);

  // final entry, sent several DynamicComponentEvent via element ids
  void SendDynamicComponentEvent(const std::string& url,
                                 const lepus::Value& err,
                                 const std::vector<int>& impl_id_list);

  // Handle different logic for sending dynamic component event in synchronous
  // and asynchronous scenarios.
  // If sync, need to set dynamic component state by *component and then event
  // will be sent when this component is adopted.
  // If async, send event by async_event_handler, *component will be used.
  static void TriggerDynamicComponentEvent(
      const lepus::Value& msg, bool sync, RadonDynamicComponent* component,
      base::MoveOnlyClosure<void, const lepus::Value&> async_event_handler);

  void SendBubbleEvent(const std::string& name, int tag,
                       lepus::DictionaryPtr dict);

  void SendInternalEvent(int tag, int eventId);
  void OnNodeFailedToRender(int tag);

  void SetLepusContextObserver(
      const std::shared_ptr<LepusContextObserver>& observer) {
    lepus_context_observer_ = observer;
  }
  void InitLepusDebugger() override;

  bool destroyed() { return destroyed_; }

#if ENABLE_ARK_RECORDER
  void SetRecordID(int64_t record_id);
  int64_t GetRecordID() const;
#endif

  // Non-threadsafe
  void UpdateDataByPreParsedData(
      const std::shared_ptr<TemplateData>& template_data,
      const UpdatePageOption& update_page_option,
      base::closure finished_callback = nullptr);
  // Threadsafe

  void UpdateDataByJS(const runtime::UpdateDataTask& task);

  const lepus::Value GetGlobalProps() const {
    return lepus::Value::ShallowCopy(global_props_);
  }

  PageProxy* page_proxy() { return &page_proxy_; }
  lepus::Context* context(const std::string entry_name) {
    return FindEntry(entry_name)->GetVm().get();
  }

  std::shared_ptr<lepus::Context> getLepusContext(
      const std::string& entry_name) {
    auto entry = FindEntry(entry_name);
    return entry->GetVm();
  }

  std::unordered_map<int, std::shared_ptr<ComponentMould>>& component_moulds(
      const std::string& entry_name) {
    return FindEntry(entry_name)->component_moulds();
  }
  std::unordered_map<int, std::shared_ptr<DynamicComponentMould>>&
  dynamic_component_moulds(const std::string& entry_name) {
    return FindEntry(entry_name)->dynamic_component_moulds();
  }
  std::unordered_map<int, std::shared_ptr<ComponentMould>>& component_moulds(
      lepus::Context* context) {
    return FindEntry(context)->component_moulds();
  }
  std::unordered_map<int, std::shared_ptr<DynamicComponentMould>>&
  dynamic_component_moulds(lepus::Context* context) {
    return FindEntry(context)->dynamic_component_moulds();
  }

  const std::unordered_map<std::string, int>& component_name_to_id(
      lepus::Context* context) {
    return FindEntry(context)->component_name_to_id();
  }

  std::shared_ptr<CSSStyleSheetManager> style_sheet_manager(
      const std::string& entry_name) {
    return FindEntry(entry_name)->GetStyleSheetManager();
  }

  std::shared_ptr<CSSStyleSheetManager> style_sheet_manager(
      lepus::Context* context) {
    return FindEntry(context)->GetStyleSheetManager();
  }

  const std::unordered_map<int, std::shared_ptr<PageMould>>& page_moulds();
  void Destroy();

  Delegate& GetDelegate() { return delegate_; }

  std::unique_ptr<lepus::Value> GetCurrentData();
  lepus::Value GetPageDataByKey(const std::vector<std::string>& keys);

  void UpdateComponentData(const runtime::UpdateDataTask& task);

  void SelectComponent(const std::string& component_id, const std::string&,
                       const bool single, piper::ApiCallBack callback);

  void ElementAnimate(const std::string& component_id,
                      const std::string& id_selector, const lepus::Value& args);

  void GetComponentContextDataAsync(const std::string& component_id,
                                    const std::string& key,
                                    piper::ApiCallBack callback);
  void TriggerComponentEvent(const std::string& event_name,
                             const lepus::Value& msg);

  void CallJSFunctionInLepusEvent(const int64_t component_id,
                                  const std::string& name,
                                  const lepus::Value& params);

  void TriggerLepusGlobalEvent(const std::string& event_name,
                               const lepus::Value& msg);
  void TriggerWorkletFunction(std::string component_id,
                              std::string worklet_module_name,
                              std::string method_name, lepus::Value args,
                              piper::ApiCallBack callback);
  lepus::Value TriggerLepusBridge(const std::string& event_name,
                                  const lepus::Value& msg);
  void TriggerLepusBridgeAsync(const std::string& method_name,
                               const lepus::Value& arguments);
  void InvokeLepusCallback(const int32_t callback_id,
                           const std::string& entry_name,
                           const lepus::Value& data);

  void InvokeLepusComponentCallback(const int64_t callback_id,
                                    const std::string& entry_name,
                                    const lepus::Value& data);

  void GetDecodedJSSource(
      std::unordered_map<std::string, std::string>& js_source);

  std::shared_ptr<TemplateEntry> QueryComponent(const std::string& url);

  void SendAirPageEvent(const std::string& event, const lepus::Value& value);
  void RenderTemplateForAir(const std::shared_ptr<TemplateEntry>& card,
                            const lepus::Value& data);
  void SendAirComponentEvent(const std::string& event_name,
                             const int component_id, const lepus::Value& params,
                             const std::string& param_name);
  // air-runtime methods
  lepus::Value TriggerBridgeSync(const std::string& method_name,
                                 const lynx::lepus::Value& arguments);
  void TriggerBridgeAsync(lepus::Context* context,
                          const std::string& method_name,
                          const lynx::lepus::Value& arguments,
                          std::unique_ptr<lepus::Value> callback_closure);
  uint32_t SetTimeOut(lepus::Context* context,
                      std::unique_ptr<lepus::Value> closure,
                      int64_t delay_time);
  uint32_t SetTimeInterval(lepus::Context* context,
                           std::unique_ptr<lepus::Value> closure,
                           int64_t interval_time);
  void RemoveTimeTask(uint32_t task_id);
  void InvokeAirCallback(int64_t id, const std::string& entry_name,
                         const lepus::Value& data);

  static TemplateAssembler* GetCurrTasm() { return curr_; }

  // TODO: make this protected
 public:
  void SetPageConfig(const std::shared_ptr<PageConfig>& config) override;
  void SetEnableLayoutOnly(bool enable_layout_only) {
    LOGI("Lynx Set Enable Layout Only: " << std::boolalpha << enable_layout_only
                                         << " from LynxView, "
                                         << " this:" << this);
    page_proxy_.SetTasmEnableLayoutOnly(enable_layout_only);
  }

  void OnPageConfigDecoded(const std::shared_ptr<PageConfig>& config);

  PackageInstanceDSL GetPageDSL() {
    return page_config_ ? page_config_->GetDSL() : PackageInstanceDSL::TT;
  }

  PackageInstanceBundleModuleMode GetBundleModuleMode() {
    return page_config_ ? page_config_->GetBundleModuleMode()
                        : PackageInstanceBundleModuleMode::EVAL_REQUIRE_MODE;
  }

  std::shared_ptr<PageConfig> GetPageConfig() override { return page_config_; }

  void SetPageConfigClient() {
    // add for global config
    if (page_proxy_.element_manager()) {
      page_proxy_.element_manager()->SetConfig(GetPageConfig());
    }
  }

  inline bool EnableLynxAir() {
    return page_config_ && page_config_->GetLynxAirMode() ==
                               CompileOptionAirMode::AIR_MODE_STRICT;
  }

  const lepus::Value& GetDefaultProcessor() { return default_processor_; }
  const std::unordered_map<std::string, lepus::Value>& GetProcessorMap() const {
    return processor_with_name_;
  }
  const lepus::Value& GetProcessorWithName(const std::string& name) {
    return processor_with_name_[name];
  }
  const lepus::Value& GetComponentProcessorWithName(
      const std::string& component_path, const std::string& name,
      const std::string& entry_name) {
    return component_processor_with_name_[entry_name.empty()
                                              ? DEFAULT_ENTRY_NAME
                                              : entry_name][component_path]
                                         [name];
  }

  void SetDefaultProcessor(const lepus::Value& processor) {
    default_processor_ = processor;
  }
  void SetProcessorWithName(const lepus::Value& processor,
                            const std::string& name) {
    processor_with_name_[name] = processor;
  }
  void SetComponentProcessorWithName(const lepus::Value& processor,
                                     const std::string& name,
                                     const std::string& component_path,
                                     const std::string& entry_name) {
    component_processor_with_name_[entry_name.empty() ? DEFAULT_ENTRY_NAME
                                                      : entry_name]
                                  [component_path][name] = processor;
  }

  void SetDynamicComponentLoader(
      std::shared_ptr<DynamicComponentLoader> loader) {
    component_loader_ = loader;
  }

  void SetLocale(const std::string& locale) { locale_ = locale; }

  bool UpdateConfig(const lepus::Value& config, bool noticeDelegate);

  std::string TranslateResourceForTheme(const std::string& res_id,
                                        const std::string& theme_key) {
    std::string result;
    if (res_id.empty()) {
      return result;
    }

    if (page_proxy_.themed().hasAnyCurRes &&
        page_proxy_.themed().currentTransMap) {
      if (InnerTranslateResourceForTheme(result, res_id, theme_key, false)) {
        return result;
      }
    }

    result = delegate_.TranslateResourceForTheme(res_id, theme_key);
    if (!result.empty()) {
      return result;
    }

    if (page_proxy_.themed().hasAnyFallback &&
        page_proxy_.themed().currentTransMap) {
      if (InnerTranslateResourceForTheme(result, res_id, theme_key, true)) {
        return result;
      }
    }

    return "";
  }

  lepus::Value GetI18nResources(const lepus::Value& locale,
                                const lepus::Value& channel,
                                const lepus::Value& fallback_url);

  void UpdateI18nResource(const std::string& key, const std::string& new_data);

  void updateLocale(const lepus::Value& locale, const lepus::Value& channel);

  void ReFlushPage();

  void FilterI18nResource(const lepus::Value& channel,
                          const lepus::Value& locale,
                          const lepus::Value& reserve_keys);

  void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing);

  void OnFontScaleChanged(float scale);

  void OnI18nResourceChanged(const std::string& new_data);

  void OnI18nResourceFailed();

  void SetFontScale(float scale);

  void SendFontScaleChanged(float scale);

  void SendGlobalEvent(const std::string& event, const lepus::Value& value);

  void UpdateViewport(float width, int32_t width_mode, float height,
                      int32_t height_mode);
  void OnUpdatePerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing);

  virtual void OnDynamicComponentPerfReady(
      const std::unordered_map<std::string,
                               base::PerfCollector::DynamicComponentPerfInfo>&
          dynamic_component_perf);

  const std::unordered_map<std::string, std::shared_ptr<TemplateEntry>>&
  template_entries() const {
    return template_entries_;
  }

  std::string GetTargetUrl(const std::string& current,
                           const std::string& target);
  std::shared_ptr<TemplateEntry> RequireTemplateEntry(
      RadonDynamicComponent* dynamic_component, const std::string& url);
  std::shared_ptr<TemplateEntry> FindTemplateEntry(const std::string& url);

  void OnDynamicJSSourcePrepared(const std::string& component_url);

  std::string TargetSdkVersion() { return target_sdk_version_; }

  // print js console log
  // level: log, warn, error, info, debug
  void PrintMsgToJS(const std::string& level, const std::string& msg);

  bool UseLepusNG();

  void HotModuleReplace(const lepus::Value& data, const std::string& message);
  void HotModuleReplaceInternal(const std::vector<HmrData>& component_data,
                                const std::string& message);

  void SetCSSVariables(const std::string& component_id,
                       const std::string& id_selector,
                       const lepus::Value& properties);

  void SetNativeProps(const NodeSelectRoot& root,
                      const tasm::NodeSelectOptions& options,
                      const lepus::Value& native_props);

  void SetLepusEventListener(const std::string& name,
                             const lepus::Value& listener);
  void RemoveLepusEventListener(const std::string& name);

  void SendGlobalEventToLepus(const std::string& name,
                              const lepus_value& params);

  const std::shared_ptr<TemplateEntry>& FindEntry(
      const std::string& entry_name);

  void TriggerEventBus(const std::string& name, const lepus_value& params);

  void RenderToBinary(
      base::MoveOnlyClosure<void, RadonNode*, tasm::TemplateAssembler*>);

  struct Themed& Themed() override;

  void SetThemed(const Themed::PageTransMaps& page_trans_maps);

  // For fiber
  void CallLepusMethod(const std::string& method_name, lepus::Value args,
                       const piper::ApiCallBack& callback,
                       uint64_t trace_flow_id);

  void PreloadDynamicComponents(const std::vector<std::string>& urls);

  // insert bundle for preloading dynamic component
  void InsertLynxTemplateBundle(const std::string& url,
                                LynxTemplateBundle&& bundle);

  // invoke lepus closure
  lepus::Value TriggerLepusClosure(const lepus::Value& closure,
                                   const lepus::Value& param);

  inline void EnablePreUpdateData(bool enable) {
    enable_pre_update_data_ = enable;
  }

 private:
  friend class TemplateBinaryReader;
  friend class TemplateBinaryReaderSSR;
  friend class ssr::ServerDomConstructor;
  friend class TemplateEntry;

  TemplateEntry* FindEntry(lepus::Context* context);

  void DidComponentLoaded(const std::shared_ptr<TemplateEntry>& component_entry,
                          const std::string& url, bool need_render);

  // Build TemplateEntry for dynamic component
  std::shared_ptr<TemplateEntry> BuildComponentEntryInternal(
      const std::string& url,
      const base::MoveOnlyClosure<bool, const std::shared_ptr<TemplateEntry>&>&
          entry_initializer);

  // try to construct a entry with preloaded resources
  std::shared_ptr<TemplateEntry> BuildTemplateEntryFromPreload(
      const std::string& url);

  // internal method to send a dynamic component request by loader
  std::shared_ptr<TemplateEntry> RequestTemplateEntryInternal(
      const std::string& url, RadonDynamicComponent* dynamic_component);

  void SetGlobalDataToContext(lepus::Context* context,
                              const lepus::Value& data);

  void LoadTemplateInternal(
      const std::string& url,
      const std::shared_ptr<TemplateData>& template_data,
      base::MoveOnlyClosure<bool, const std::shared_ptr<TemplateEntry>&>
          entry_initializer);

  bool OnLoadTemplate(const std::shared_ptr<TemplateData>& template_data);
  void DidLoadTemplate();

  void OnDecodeTemplate();
  void DidDecodeTemplate(bool post_js);

  void OnVMExecute(lepus::Context* context);
  void DidVMExecute();

  lepus::Value OnRenderTemplate(
      const std::shared_ptr<TemplateData>& template_data,
      const std::shared_ptr<TemplateEntry>& card, bool post_js);
  void RenderTemplate(const std::shared_ptr<TemplateEntry>& card,
                      lepus::Value& data);
  void UpdateTemplate(const lepus::Value& data,
                      const UpdatePageOption& update_page_option);
  void DidRenderTemplate();
  void RenderTemplateForFiber(const std::shared_ptr<TemplateEntry>& card,
                              const lepus::Value& data);

  void OnDataUpdatedByNative(const lepus_value& value, const bool read_only,
                             const bool reset = false,
                             base::closure callback = nullptr);

  void OnJSPrepared(const std::string& url);
  void NotifyGlobalPropsChanged(const lepus::Value& value);

  bool InnerTranslateResourceForTheme(std::string& ret,
                                      const std::string& res_id,
                                      const std::string& theme_key,
                                      bool isFinalFallback);
  bool FromBinary(const std::shared_ptr<TemplateEntry>& entry,
                  std::vector<uint8_t> source, bool is_card = true,
                  bool is_hmr = false);
  void SetSupportComponentJS(bool support) override {
    support_component_js_ = support;
  }
  void SetTargetSdkVersion(const std::string& targetSdkVersion) override {
    target_sdk_version_ = targetSdkVersion;
  }

  bool UpdateGlobalDataInternal(const lepus_value& value,
                                const UpdatePageOption& update_page_option);
  void EnsureTouchEventHandler();

  void EnsureAirTouchEventHandler();

  void SetPageConfigRadonMode() const;
  void HmrUpdatePageStyle(const std::shared_ptr<TemplateEntry>& entry);
  LightComponentInfo HmrExtractComponentInfo();
  void HmrUpdateLepusAndJSSource(const rapidjson::Value& component_param,
                                 const std::shared_ptr<TemplateEntry>& entry);
  void HmrExecuteUpdate(const rapidjson::Value& component_param,
                        const bool& is_card, const std::string& url);

  // Insert data inplace to parameter, return if the page data should be read
  // only.
  bool ProcessTemplateData(const std::shared_ptr<TemplateData>& template_data,
                           lepus::Value& dict, bool first_screen);
  bool ProcessTemplateDataForFiber(
      const std::shared_ptr<TemplateData>& template_data, lepus::Value& dict,
      bool first_screen);
  bool ProcessTemplateDataForRadon(
      const std::shared_ptr<TemplateData>& template_data, lepus::Value& dict,
      bool first_screen);

  // SSR and Hydration related methods.
  void UpdateGlobalPropsWithDefaultProps();

  // Reset page status by ssr data.ssr related methods.
  void ResetPageConfigWithSSRData(lepus::Value value);

  // merge with preserved data if needed
  bool ProcessInitData(const std::shared_ptr<TemplateData>& init_template_data,
                       lepus::Value& result);

  void ClearCacheData() { cache_data_.clear(); }

  bool default_use_lepus_ng_ = false;

  PageProxy page_proxy_;

  static lynx_thread_local(TemplateAssembler*) curr_;

  std::unordered_map<lepus::Context*, TemplateEntry*> vm_to_template_entry_;

  bool support_component_js_;
  std::string target_sdk_version_;
  bool can_use_snapshot_;
  bool template_loaded_;

  using PerfTime = long long;
  PerfTime actual_fmp_start_;
  PerfTime actual_fmp_end_;

  Delegate& delegate_;
  I18n i18n;

  std::unique_ptr<TouchEventHandler> touch_event_handler_;

  std::unique_ptr<AirTouchEventHandlerBase> air_touch_event_handler_;

  std::atomic<bool> has_load_page_;
  //  std::string page_name_;
  std::shared_ptr<PageConfig> page_config_;

  const int32_t trace_id_;
  bool destroyed_;
  std::shared_ptr<PerfHandler> perf_handler_;
  lepus::Value default_processor_;
  std::unordered_map<std::string, lepus::Value> processor_with_name_;
  // key: [0]entry_name -> [1]component_path -> [3]processor_name
  // value: processor
  typedef std::unordered_map<
      std::string,
      std::unordered_map<std::string,
                         std::unordered_map<std::string, lepus::Value>>>
      ComponentProcessorMap;
  ComponentProcessorMap component_processor_with_name_;

  lepus::Value global_props_;  // cache globalProps
  std::string url_;
  size_t source_size_;
  bool is_loading_template_;
  float font_scale_;
  std::unordered_map<std::string, lepus::Value> lepus_event_listeners_;

  std::shared_ptr<LepusContextObserver> lepus_context_observer_;

  std::shared_ptr<DynamicComponentLoader> component_loader_;
  std::string locale_;
  TemplateAssembler(const TemplateAssembler&) = delete;
  TemplateAssembler& operator=(const TemplateAssembler&) = delete;

  ALLOW_UNUSED_TYPE int64_t record_id_ = 0;

  // enable updateData before loadTemplate
  bool enable_pre_update_data_{false};
  // data updated before loadTemplate
  std::vector<std::shared_ptr<TemplateData>> cache_data_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_TEMPLATE_ASSEMBLER_H_
