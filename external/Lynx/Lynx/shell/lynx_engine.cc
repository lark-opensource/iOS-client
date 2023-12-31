// Copyright 2020 The Lynx Authors. All rights reserved.

#include "shell/lynx_engine.h"

#include "base/string/string_utils.h"
#include "base/trace_event/trace_event.h"
#include "jsbridge/utils/jsi_object_wrapper.h"
#include "shell/common/vsync_monitor.h"
#include "shell/layout_mediator.h"
#include "tasm/event_report_tracker.h"
#include "tasm/lynx_get_ui_result.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/radon/radon_list_node.h"
#include "tasm/radon/radon_node.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"
#include "tasm/value_utils.h"
#include "third_party/rapidjson/document.h"

#if ENABLE_RENDERKIT
#include "jsbridge/renderkit/platform_value_renderkit.h"
#include "tasm/react/renderkit/painting_context_renderkit.h"
#endif

#if ENABLE_AIR
#include "tasm/air/runtime/air_runtime.h"
#endif

namespace lynx {
namespace shell {

namespace {

inline bool MergeCacheDataOp(lepus::Value& target,
                             const std::vector<CacheDataOp>& caches) {
  for (const auto& cache : caches) {
    DCHECK(target.IsTable() && cache.GetValue().IsTable());
    if (cache.GetType() == CacheDataType::RESET) {
      return false;
    }
    for (const auto& cache_pair : *(cache.GetValue().Table())) {
      target.Table()->SetValue(cache_pair.first, cache_pair.second);
    }
  }
  return true;
}

// ensure access on tasm thread
inline std::string& GetCoreJS() {
  static base::NoDestructor<std::string> core_js;
  return *core_js;
}

}  // namespace

void LynxEngine::Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack) {
  delegate_->Report(std::move(stack));
}

LynxEngine::~LynxEngine() {
  // TODO(heshan): now is nullptr when run unittest, in fact cannot be nullptr
  // when runtime, will remove when LynxEngine no longer be a wrapper for tasm
  if (tasm_ != nullptr) {
    tasm_->Destroy();
  }
}

void LynxEngine::Init() {
  delegate_->Init();

  auto& client = tasm_->page_proxy()->element_manager();
  /**
   * Init vsync_monitor here to ensure CADisplayLink on iOS platform
   * can be added to the right runloop when applying MostOnTasm or other
   * non-AllOnUI thread strategies.
   */
  if (client != nullptr && client->vsync_monitor() != nullptr) {
    client->vsync_monitor()->BindToCurrentThread();
    client->vsync_monitor()->Init();
  }
}

void LynxEngine::LoadTemplate(
    const std::string& url, std::vector<uint8_t> source,
    const std::shared_ptr<tasm::TemplateData>& template_data) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxEngine::LoadTemplate");
  tasm::TimingCollector::Scope<Delegate> scope(delegate_.get());
  tasm_->LoadTemplate(url, std::move(source), template_data);
}

void LynxEngine::LoadTemplateBundle(
    const std::string& url, tasm::LynxTemplateBundle template_bundle,
    const std::shared_ptr<tasm::TemplateData>& template_data) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxEngine::LoadTemplateBundle");
  tasm::TimingCollector::Scope<Delegate> scope(delegate_.get());
  tasm_->LoadTemplateBundle(url, std::move(template_bundle), template_data);
}

void LynxEngine::LoadSSRData(
    std::vector<uint8_t> source,
    const std::shared_ptr<tasm::TemplateData>& template_data) {
  tasm::TimingCollector::Scope<Delegate> scope(delegate_.get());
  tasm_->RenderPageWithSSRData(std::move(source), template_data);
}

void LynxEngine::UpdateDataByParsedData(
    const std::shared_ptr<tasm::TemplateData>& data,
    uint32_t native_update_data_order, base::closure finished_callback) {
  tasm::UpdatePageOption update_page_option;
  update_page_option.from_native = true;
  update_page_option.native_update_data_order_ = native_update_data_order;
  tasm_->UpdateDataByPreParsedData(data, update_page_option,
                                   std::move(finished_callback));
}

void LynxEngine::ResetDataByParsedData(
    const std::shared_ptr<tasm::TemplateData>& data,
    uint32_t native_update_data_order) {
  tasm::UpdatePageOption update_page_option;
  update_page_option.from_native = true;
  update_page_option.reset_page_data = true;
  update_page_option.native_update_data_order_ = native_update_data_order;
  tasm_->UpdateDataByPreParsedData(data, update_page_option);
}

void LynxEngine::ReloadTemplate(const std::shared_ptr<tasm::TemplateData>& data,
                                const lepus::Value& global_props,
                                uint32_t native_update_data_order) {
  tasm::UpdatePageOption update_page_option;
  update_page_option.native_update_data_order_ = native_update_data_order;
  tasm_->ReloadTemplate(data, global_props, update_page_option);
}

void LynxEngine::UpdateConfig(const lepus::Value& config) {
  tasm_->UpdateConfig(config, false);
}

void LynxEngine::UpdateGlobalProps(const lepus::Value& global_props) {
  tasm_->UpdateGlobalProps(global_props);
}

void LynxEngine::UpdateFontScale(float scale) {
  auto& client = tasm_->page_proxy()->element_manager();
  if (client != nullptr) {
    client->UpdateFontScale(scale);
    tasm_->OnFontScaleChanged(scale);
  }
}

void LynxEngine::SetFontScale(float scale) {
  auto& client = tasm_->page_proxy()->element_manager();
  if (client != nullptr) {
    tasm_->SetFontScale(scale);
    client->UpdateFontScale(scale);
  }
}

void LynxEngine::UpdateScreenMetrics(float width, float height, float scale) {
  // update element tree and layout tree
  auto& client = tasm_->page_proxy()->element_manager();
  if (client != nullptr) {
    tasm_->page_proxy()->OnScreenMetricsSet(width, height);
    client->UpdateScreenMetrics(width, height);
  }
}

void LynxEngine::UpdateViewport(float width, int32_t width_mode, float height,
                                int32_t height_mode, bool need_layout) {
  tasm_->page_proxy()->element_manager()->UpdateViewport(
      width, static_cast<SLMeasureMode>(width_mode), height,
      static_cast<SLMeasureMode>(height_mode), need_layout);
}

void LynxEngine::SyncFetchLayoutResult() {
  LayoutMediator::HandleLayoutVoluntarily(
      operation_queue_.get(),
      tasm_->page_proxy()->element_manager()->catalyzer());
}

void LynxEngine::SendAirPageEvent(const std::string& name,
                                  const lepus_value& params) {
#if ENABLE_AIR
  tasm_->SendAirPageEvent(name, params);
#endif
}

void LynxEngine::SendCustomEvent(const std::string& name, int32_t tag,
                                 const lepus::Value& params,
                                 const std::string& params_name) {
  tasm_->SendCustomEvent(name, tag, params, params_name.c_str());
}

void LynxEngine::SendTouchEvent(const std::string& name, int32_t tag, float x,
                                float y, float client_x, float client_y,
                                float page_x, float page_y) {
  tasm_->SendTouchEvent(name, tag, x, y, client_x, client_y, page_x, page_y);
}

void LynxEngine::OnPseudoStatusChanged(int32_t id, int32_t pre_status,
                                       int32_t current_status) {
  tasm_->OnPseudoStatusChanged(id, pre_status, current_status);
}

void LynxEngine::SendBubbleEvent(const std::string& name, int32_t tag,
                                 lepus::DictionaryPtr dict) {
  tasm_->SendBubbleEvent(name, tag, dict);
}

void LynxEngine::SendInternalEvent(int32_t tag, int32_t event_id) {
  tasm_->SendInternalEvent(tag, event_id);
}

void LynxEngine::SendGlobalEventToLepus(const std::string& name,
                                        const lepus_value& params) {
  tasm_->SendGlobalEventToLepus(name, params);
}

void LynxEngine::TriggerEventBus(const std::string& name,
                                 const lepus_value& params) {
  tasm_->TriggerEventBus(name, params);
}

void LynxEngine::LoadComponent(const std::string& url,
                               std::vector<uint8_t> binary, bool sync) {
  constexpr const static int32_t kNoCallback = -1;
  LoadComponentWithCallback(url, std::move(binary), sync, kNoCallback);
}

void LynxEngine::LoadComponentWithCallback(const std::string& url,
                                           std::vector<uint8_t> binary,
                                           bool sync, int32_t callback_id) {
  tasm_->LoadComponentWithCallback(url, std::move(binary), sync, callback_id);
}

std::unique_ptr<lepus_value> LynxEngine::GetCurrentData() {
  return tasm_->GetCurrentData();
}

lepus::Value LynxEngine::GetPageDataByKey(
    const std::vector<std::string>& keys) {
  return tasm_->GetPageDataByKey(keys);
}

tasm::ListNode* LynxEngine::GetListNode(int32_t tag) {
  // client maybe nullptr
  if (tasm_ == nullptr) {
    return nullptr;
  }
  auto& client = tasm_->page_proxy()->element_manager();
  if (client == nullptr) {
    return nullptr;
  }
  lynx::tasm::Element* element = client->node_manager()->Get(tag);
  if (element == nullptr) {
    return nullptr;
  }
  return element->GetListNode();
}

std::unordered_map<std::string, std::string> LynxEngine::GetAllJsSource() {
  std::unordered_map<std::string, std::string> source;
  tasm_->GetDecodedJSSource(source);
  source.emplace("core.js", GetCoreJS());
  return source;
}

void LynxEngine::UpdateDataByJS(runtime::UpdateDataTask task) {
  auto cached_page_data = card_cached_data_mgr_->GetCardCacheData();
  if (MergeCacheDataOp(task.data_, cached_page_data)) {
    tasm_->UpdateDataByJS(task);
  }
  card_cached_data_mgr_->DecrementTaskCount();
  if (!cached_page_data.empty()) {
    delegate_->NotifyJSUpdatePageData();
  }
  delegate_->CallJSApiCallback(task.callback_);
}

void LynxEngine::UpdateBatchedDataByJS(
    std::vector<runtime::UpdateDataTask> tasks, uint64_t update_task_id) {
  TRACE_EVENT_FLOW_END0(LYNX_TRACE_CATEGORY,
                        LYNX_TRACE_EVENT_BATCHED_UPDATE_DATA, update_task_id);
  auto cached_page_data = card_cached_data_mgr_->GetCardCacheData();
  for (auto& task : tasks) {
    tasm::TimingCollector::Scope<Delegate> scope(
        delegate_.get(), tasm::GetTimingFlag(task.data_));
    if (task.is_card_) {
      if (MergeCacheDataOp(task.data_, cached_page_data)) {
        tasm_->UpdateDataByJS(task);
      }
      delegate_->CallJSApiCallback(task.callback_);
    } else {
      tasm_->UpdateComponentData(task);
    }

    if (tasm_->page_proxy()->HasSSRRadonPage()) {
      // Here is trying to find a proper timing for the react lynx page to be
      // hydrated. The following function will trigger hydration once the js
      // constructors are all done.
      tasm_->page_proxy()->OnReactComponentJSFirstScreenReady();
    }
  }

  card_cached_data_mgr_->DecrementTaskCount();
  if (!cached_page_data.empty()) {
    delegate_->NotifyJSUpdatePageData();
  }
}

void LynxEngine::TriggerComponentEvent(const std::string& event_name,
                                       const lepus::Value& msg) {
  tasm_->TriggerComponentEvent(event_name, msg);
}

void LynxEngine::TriggerLepusGlobalEvent(const std::string& event_name,
                                         const lepus::Value& msg) {
  tasm_->TriggerLepusGlobalEvent(event_name, msg);
}

void LynxEngine::TriggerWorkletFunction(std::string component_id,
                                        std::string worklet_module_name,
                                        std::string method_name,
                                        lepus::Value args,
                                        piper::ApiCallBack callback) {
  tasm_->TriggerWorkletFunction(
      std::move(component_id), std::move(worklet_module_name),
      std::move(method_name), std::move(args), std::move(callback));
}

void LynxEngine::InvokeLepusCallback(const int32_t callback_id,
                                     const std::string& entry_name,
                                     const lepus::Value& data) {
  if (tasm_->EnableLynxAir()) {
    tasm_->InvokeAirCallback(callback_id, entry_name, data);
    return;
  }
  tasm_->InvokeLepusCallback(callback_id, entry_name, data);
}

void LynxEngine::InvokeLepusComponentCallback(const int64_t callback_id,
                                              const std::string& entry_name,
                                              const lepus::Value& data) {
  tasm_->InvokeLepusComponentCallback(callback_id, entry_name, data);
}

void LynxEngine::UpdateComponentData(runtime::UpdateDataTask task) {
  tasm::TimingCollector::Scope<Delegate> scope(delegate_.get(),
                                               tasm::GetTimingFlag(task.data_));
  tasm_->UpdateComponentData(task);
}

void LynxEngine::SelectComponent(const std::string& component_id,
                                 const std::string& id_selector,
                                 const bool single,
                                 piper::ApiCallBack callBack) {
  tasm_->SelectComponent(component_id, id_selector, single, callBack);
}

void LynxEngine::ElementAnimate(const std::string& component_id,
                                const std::string& id_selector,
                                const lepus::Value& args) {
  tasm_->ElementAnimate(component_id, id_selector, args);
}

void LynxEngine::GetComponentContextDataAsync(const std::string& component_id,
                                              const std::string& key,
                                              piper::ApiCallBack callback) {
  tasm_->GetComponentContextDataAsync(component_id, key, callback);
}

void LynxEngine::UpdateCoreJS(std::string core_js) {
  GetCoreJS().assign(std::move(core_js));
}

void LynxEngine::UpdateI18nResource(const std::string& key,
                                    const std::string& new_data) {
  tasm_->UpdateI18nResource(key, new_data);
}

void LynxEngine::Flush() {
  if (tasm_ != nullptr) {  // for unittest, judge null
    tasm_->page_proxy()->element_manager()->painting_context()->Flush();
  }
}

std::shared_ptr<tasm::TemplateAssembler> LynxEngine::GetTasm() { return tasm_; }

void LynxEngine::HotModuleReplace(const lepus::Value& data,
                                  const std::string& message) {
  tasm_->HotModuleReplace(data, message);
}

void LynxEngine::HotModuleReplaceWithHmrData(
    const std::vector<tasm::HmrData>& data, const std::string& message) {
  tasm_->HotModuleReplaceInternal(data, message);
}

void LynxEngine::SetCSSVariables(const std::string& component_id,
                                 const std::string& id_selector,
                                 const lepus::Value& properties) {
  tasm_->SetCSSVariables(component_id, id_selector, properties);
}

void LynxEngine::SetNativeProps(const tasm::NodeSelectRoot& root,
                                const tasm::NodeSelectOptions& options,
                                const lepus::Value& native_props) {
  tasm_->SetNativeProps(root, options, native_props);
}

void LynxEngine::SendDynamicComponentEvent(
    const std::string& url, const lepus::Value& err,
    const std::vector<uint32_t>& uid_list) {
  tasm_->SendDynamicComponentEvent(url, err, std::move(uid_list));
}

void LynxEngine::ReloadFromJS(runtime::UpdateDataTask task) {
  tasm::TimingCollector::Scope<Delegate> scope(delegate_.get(),
                                               tasm::GetTimingFlag(task.data_));
  tasm_->ReloadFromJS(task);
  delegate_->CallJSApiCallback(task.callback_);
}

void LynxEngine::InvokeUIMethod(const tasm::NodeSelectRoot& root,
                                const tasm::NodeSelectOptions& options,
                                const std::string& method,
                                std::unique_ptr<piper::PlatformValue> params,
                                piper::ApiCallBack callback) {
  auto result = tasm_->page_proxy()->GetLynxUI(root, options);
  if (!result.Success()) {
    delegate_->CallJSApiCallbackWithValue(callback,
                                          result.StatusAsLepusValue());
    return;
  }

#if ENABLE_RENDERKIT
  // In Renderkit, we should execute the UI methods on the TASM thread (rather
  // than the platform thread). So instead of doing this work in NativeFacade,
  // we do it here.
  // TODO(liuguoliang): It'd be better to put this code into
  // NativeFacadeRenderkit. But currently Renderkit uses NativeFacadeAndroid on
  // Android and NativeFacadeRenderkit on other platforms. So we are doing this
  // here for convenience. Once we have a generic NativeFacade for Renderkit, we
  // can move it there.
  auto painting_context_rk = static_cast<tasm::PaintingContextRenderkit*>(
      tasm_->page_proxy()->element_manager()->painting_context()->impl());
  auto args = static_cast<piper::PlatformValueRenderkit*>(params.get())->Get();
  painting_context_rk->InvokeUIMethod(result.UiImplIds()[0], method, args,
                                      callback.id());
#else
  delegate_->InvokeUIMethod(std::move(result), method, std::move(params),
                            callback);
#endif
}

void LynxEngine::GetPathInfo(const tasm::NodeSelectRoot& root,
                             const tasm::NodeSelectOptions& options,
                             piper::ApiCallBack call_back) {
  auto result = tasm_->page_proxy()->GetPathInfo(root, options);
  delegate_->CallJSApiCallbackWithValue(call_back, result);
}

void LynxEngine::GetFields(const tasm::NodeSelectRoot& root,
                           const tasm::NodeSelectOptions& options,
                           const std::vector<std::string>& fields,
                           piper::ApiCallBack call_back) {
  auto result = tasm_->page_proxy()->GetFields(root, options, fields);
  delegate_->CallJSApiCallbackWithValue(call_back, result);
}

tasm::LynxGetUIResult LynxEngine::GetLynxUI(
    const tasm::NodeSelectRoot& root, const tasm::NodeSelectOptions& options) {
  return tasm_->page_proxy()->GetLynxUI(root, options);
}

void LynxEngine::CallLepusMethod(const std::string& method_name,
                                 lepus::Value args,
                                 const piper::ApiCallBack& callback,
                                 uint64_t trace_flow_id) {
  tasm_->CallLepusMethod(method_name, std::move(args), callback, trace_flow_id);
}

#if ENABLE_ARK_RECORDER
void LynxEngine::SetRecordID(int64_t record_id) {
  tasm_->SetRecordID(record_id);
}
#endif

void LynxEngine::PreloadDynamicComponents(
    const std::vector<std::string>& urls) {
  tasm_->PreloadDynamicComponents(urls);
}

void LynxEngine::InsertLynxTemplateBundle(
    const std::string& url, lynx::tasm::LynxTemplateBundle bundle) {
  tasm_->InsertLynxTemplateBundle(url, std::move(bundle));
}
}  // namespace shell
}  // namespace lynx
