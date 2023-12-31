// Copyright 2020 The Lynx Authors. All rights reserved.

#include "shell/tasm_mediator.h"

#include <utility>

#include "base/trace_event/trace_event.h"
#include "shell/common/vsync_monitor.h"
#include "tasm/lynx_get_ui_result.h"

#if ENABLE_AIR
#include "tasm/air/runtime/air_runtime.h"
#endif

namespace lynx {
namespace shell {

TasmMediator::TasmMediator(
    const std::shared_ptr<LynxActor<NativeFacade>>& facade_actor,
    const std::shared_ptr<LynxCardCacheDataManager>& card_cached_data_mgr,
    const std::shared_ptr<VSyncMonitor>& vsync_monitor,
    const std::shared_ptr<LynxActor<tasm::LayoutContext>>& layout_actor)
    : facade_actor_(facade_actor),
      layout_actor_(layout_actor),
      card_cached_data_mgr_(card_cached_data_mgr),
      sync_native_facade_(facade_actor != nullptr ? facade_actor->Impl()->Copy()
                                                  : nullptr),
      vsync_monitor_(vsync_monitor) {}

TasmMediator::~TasmMediator() = default;

void TasmMediator::Init() {
  vsync_monitor_->BindToCurrentThread();
  vsync_monitor_->Init();
}

void TasmMediator::OnDataUpdated() {
  facade_actor_->Act([](auto& facade) { facade->OnDataUpdated(); });
}

void TasmMediator::OnTasmFinishByNative() {
  facade_actor_->Act([](auto& facade) { facade->OnTasmFinishByNative(); });
}

void TasmMediator::OnTemplateLoaded(const std::string& url) {
  facade_actor_->Act([url](auto& facade) { facade->OnTemplateLoaded(url); });
}

void TasmMediator::OnSSRHydrateFinished(const std::string& url) {
  facade_actor_->Act(
      [url](auto& facade) { facade->OnSSRHydrateFinished(url); });
}

void TasmMediator::OnErrorOccurred(int32_t error_code, const std::string& msg) {
  facade_actor_->ActAsync([error_code, msg](auto& facade) {
    facade->ReportError(error_code, msg);
  });
}

void TasmMediator::OnFirstLoadPerfReady(
    const std::unordered_map<int32_t, double>& perf,
    const std::unordered_map<int32_t, std::string>& perf_timing) {
  facade_actor_->Act([perf, perf_timing](auto& facade) {
    facade->OnFirstLoadPerfReady(perf, perf_timing);
  });
}

void TasmMediator::OnUpdatePerfReady(
    const std::unordered_map<int32_t, double>& perf,
    const std::unordered_map<int32_t, std::string>& perf_timing) {
  facade_actor_->Act([perf, perf_timing](auto& facade) {
    facade->OnUpdatePerfReady(perf, perf_timing);
  });
}

void TasmMediator::OnDynamicComponentPerfReady(
    const std::unordered_map<std::string,
                             base::PerfCollector::DynamicComponentPerfInfo>&
        dynamic_component_perf) {
  facade_actor_->Act([dynamic_component_perf](auto& facade) {
    facade->OnDynamicComponentPerfReady(dynamic_component_perf);
  });
}

void TasmMediator::OnConfigUpdated(const lepus::Value& data) {
  facade_actor_->Act([data](auto& facade) { facade->OnConfigUpdated(data); });
}

void TasmMediator::OnPageConfigDecoded(
    const std::shared_ptr<tasm::PageConfig>& config) {
  sync_native_facade_->OnPageConfigDecoded(config);
}

void TasmMediator::SetTiming(tasm::Timing timing) {
  facade_actor_->Act([timing = std::move(timing)](auto& facade) mutable {
    facade->SetTiming(std::move(timing));
  });
}

void TasmMediator::Report(
    std::vector<std::unique_ptr<tasm::PropBundle>> stack) {
  facade_actor_->ActAsync([stack = std::move(stack)](auto& facade) mutable {
    facade->Report(std::move(stack));
  });
}

lepus::Value TasmMediator::TriggerLepusMethod(const std::string& method_name,
                                              const lepus::Value& arguments) {
  return sync_native_facade_->TriggerLepusMethod(method_name, arguments);
}

void TasmMediator::TriggerLepusMethodAsync(const std::string& method_name,
                                           const lepus::Value& arguments) {
  facade_actor_->Act([method_name, arguments](auto& facade) {
    facade->TriggerLepusMethodAsync(method_name, arguments);
  });
}

void TasmMediator::NotifyJSUpdatePageData(base::closure callback) {
  // if there also has a "UpdateDataByJS" task pending in tasm thread, do
  // nothing,  "UpdateNativeData" will call "NotifyJSUpdatePageData" again
  runtime_actor_->ActAsync(
      [card_cached_data_mgr = card_cached_data_mgr_,
       callback = std::move(callback)](auto& runtime) mutable {
        if (callback) {
          // Store the callback to cache, it will flush on JSUpdatePageData.
          runtime->InsertCallbackForDataUpdateFinishedOnRuntime(
              std::move(callback));
        }
        if (card_cached_data_mgr->GetTaskCount() <= 0) {
          runtime->NotifyJSUpdatePageData();
        }
      });
}

void TasmMediator::OnCardConfigDataChanged(const lepus::Value& data) {
  runtime_actor_->ActAsync(
      [js_data_receiver = js_data_receiver_,
       safe_data = lepus_value::ShallowCopy(data)](auto& runtime) {
        js_data_receiver->OnCardConfigDataChanged(safe_data);
        runtime->NotifyJSUpdateCardConfigData();
      });
}

void TasmMediator::RequestVsync(
    uintptr_t id, base::MoveOnlyClosure<void, int64_t, int64_t> callback) {
  if (!vsync_monitor_) {
    return;
  }
  vsync_monitor_->AsyncRequestVSync(id, std::move(callback));
}

std::string TasmMediator::TranslateResourceForTheme(
    const std::string& res_id, const std::string& theme_key) {
  return sync_native_facade_->TranslateResourceForTheme(res_id, theme_key);
}

void TasmMediator::GetI18nResource(const std::string& channel,
                                   const std::string& fallback_url) {
  sync_native_facade_->GetI18nResources(channel, fallback_url);
}

void TasmMediator::OnNativeAppReady() {
  runtime_actor_->ActAsync([](auto& runtime) { runtime->OnNativeAppReady(); });
}

void TasmMediator::OnJSSourcePrepared(
    const std::string& page_name, tasm::PackageInstanceDSL dsl,
    tasm::PackageInstanceBundleModuleMode bundle_module_mode,
    const std::string& url) {
  runtime_actor_->ActAsync(
      [page_name, dsl, bundle_module_mode, url](auto& runtime) {
        runtime->OnJSSourcePrepared(page_name, dsl, bundle_module_mode, url);
      });
}

void TasmMediator::OnSsrScriptReady(std::string script) {
  runtime_actor_->ActAsync([script = std::move(script)](auto& runtime) mutable {
    runtime->OnSsrScriptReady(std::move(script));
  });
}

void TasmMediator::CallJSApiCallback(piper::ApiCallBack callback) {
  // We should use TRACE_EVENT_FLOW_BEGIN0 instead of TRACE_EVENT here, because
  // we want to trace the whole flow of the ApiCallBack, not just the begin and
  // end of the ApiCallBack.
  TRACE_EVENT_FLOW_BEGIN0(LYNX_TRACE_CATEGORY, "CallJSApiCallback",
                          callback.trace_flow_id());

  runtime_actor_->ActAsync(
      [callback](auto& runtime) { runtime->CallJSApiCallback(callback); });
}

void TasmMediator::CallJSApiCallbackWithValue(piper::ApiCallBack callback,
                                              const lepus::Value& value) {
  TRACE_EVENT_FLOW_BEGIN0(LYNX_TRACE_CATEGORY, "CallJSApiCallbackWithValue",
                          callback.trace_flow_id());

  runtime_actor_->ActAsync(
      [callback, safe_value = lepus_value::ShallowCopy(value)](auto& runtime) {
        runtime->CallJSApiCallbackWithValue(callback, safe_value);
      });
}

void TasmMediator::CallJSFunction(const std::string& module_id,
                                  const std::string& method_id,
                                  const lepus::Value& arguments) {
  runtime_actor_->ActAsync(
      [module_id, method_id,
       safe_value = lepus_value::ShallowCopy(arguments)](auto& runtime) {
        runtime->CallJSFunction(module_id, method_id, safe_value);
      });
}

void TasmMediator::SendPageEvent(const std::string& page_name,
                                 const std::string& handler,
                                 const lepus::Value& info) {
  runtime_actor_->ActAsync(
      [page_name, handler,
       safe_value = lepus_value::ShallowCopy(info)](auto& runtime) {
        runtime->SendPageEvent(page_name, handler, safe_value);
      });
}

void TasmMediator::OnJSAppReload(const lepus::Value& data) {
  runtime_actor_->ActAsync(
      [data](auto& runtime) { runtime->OnAppReload(data); });
}

void TasmMediator::OnLifecycleEvent(const lepus::Value& args) {
  runtime_actor_->ActAsync(
      [args = lepus_value::ShallowCopy(args)](auto& runtime) {
        runtime->OnLifecycleEvent(args);
      });
}

void TasmMediator::OnDataUpdatedByNative(const lepus::Value& data,
                                         const bool read_only, const bool reset,
                                         base::closure callback) {
  // if the incoming value is read_only, it's unnecessary to clone.
  card_cached_data_mgr_->AddCardCacheData(
      read_only ? data : lepus_value::ShallowCopy(data),
      reset ? CacheDataType::RESET : CacheDataType::UPDATE);
  NotifyJSUpdatePageData(std::move(callback));
}

void TasmMediator::NotifyGlobalPropsUpdated(const lepus::Value& props) {
  runtime_actor_->ActAsync(
      [safe_value = lepus_value::ShallowCopy(props)](auto& runtime) {
        runtime->NotifyGlobalPropsUpdated(safe_value);
      });
}

void TasmMediator::OnDynamicJSSourcePrepared(const std::string& source) {
  runtime_actor_->ActAsync(
      [source](auto& runtime) { runtime->OnDynamicJSSourcePrepared(source); });
}

void TasmMediator::PublicComponentEvent(const std::string& component_id,
                                        const std::string& handler,
                                        const lepus::Value& info) {
  runtime_actor_->ActAsync(
      [component_id, handler,
       safe_value = lepus_value::ShallowCopy(info)](auto& runtime) {
        runtime->PublicComponentEvent(component_id, handler, safe_value);
      });
}

void TasmMediator::CallJSFunctionInLepusEvent(const int64_t component_id,
                                              const std::string& name,
                                              const lepus::Value& params) {
  runtime_actor_->ActAsync(
      [name, component_id,
       safe_value = lepus_value::ShallowCopy(params)](auto& runtime) {
        runtime->CallJSFunctionInLepusEvent(component_id, name, safe_value);
      });
}

void TasmMediator::SendGlobalEvent(const std::string& name,
                                   const lepus::Value& info) {
  runtime_actor_->ActAsync(
      [name, safe_value = lepus_value::ShallowCopy(info)](auto& runtime) {
        runtime->SendGlobalEvent(name, safe_value);
      });
}

void TasmMediator::OnComponentActivity(const std::string& action,
                                       const std::string& component_id,
                                       const std::string& parent_component_id,
                                       const std::string& path,
                                       const std::string& entry_name,
                                       const lepus::Value& data) {
  runtime_actor_->ActAsync(
      [action, component_id, parent_component_id, path, entry_name,
       safe_value = lepus_value::ShallowCopy(data)](auto& runtime) {
        runtime->OnComponentActivity(action, component_id, parent_component_id,
                                     path, entry_name, safe_value);
      });
}

void TasmMediator::OnComponentPropertiesChanged(
    const std::string& component_id, const lepus::Value& properties) {
  runtime_actor_->ActAsync([component_id, safe_value = lepus_value::ShallowCopy(
                                              properties)](auto& runtime) {
    runtime->OnComponentPropertiesChanged(component_id, safe_value);
  });
}

void TasmMediator::OnComponentDataSetChanged(const std::string& component_id,
                                             const lepus::Value& data_set) {
  runtime_actor_->ActAsync([component_id, safe_value = lepus_value::ShallowCopy(
                                              data_set)](auto& runtime) {
    runtime->OnComponentDataSetChanged(component_id, safe_value);
  });
}

void TasmMediator::OnComponentSelectorChanged(const std::string& component_id,
                                              const lepus::Value& instance) {
  runtime_actor_->ActAsync([component_id, safe_value = lepus_value::ShallowCopy(
                                              instance)](auto& runtime) {
    runtime->OnComponentSelectorChanged(component_id, safe_value);
  });
}

void TasmMediator::OnReactComponentRender(const std::string& id,
                                          const lepus::Value& props,
                                          const lepus::Value& data,
                                          bool should_component_update) {
  runtime_actor_->ActAsync([id, safe_props = lepus_value::ShallowCopy(props),
                            safe_data = lepus_value::ShallowCopy(data),
                            should_component_update](auto& runtime) {
    runtime->OnReactComponentRender(id, safe_props, safe_data,
                                    should_component_update);
  });
}

void TasmMediator::OnReactComponentDidUpdate(const std::string& id) {
  runtime_actor_->ActAsync(
      [id](auto& runtime) { runtime->OnReactComponentDidUpdate(id); });
}

void TasmMediator::OnReactComponentDidCatch(const std::string& id,
                                            const lepus::Value& error) {
  runtime_actor_->ActAsync(
      [id, safe_value = lepus_value::ShallowCopy(error)](auto& runtime) {
        runtime->OnReactComponentDidCatch(id, safe_value);
      });
}

void TasmMediator::OnReactComponentCreated(
    const std::string& entry_name, const std::string& path,
    const std::string& id, const lepus::Value& props, const lepus::Value& data,
    const std::string& parent_id, bool force_flush) {
  runtime_actor_->ActAsync([entry_name, path, id,
                            safe_props = lepus_value::ShallowCopy(props),
                            safe_data = lepus_value::ShallowCopy(data),
                            parent_id, force_flush](auto& runtime) {
    runtime->OnReactComponentCreated(entry_name, path, id, safe_props,
                                     safe_data, parent_id, force_flush);
  });
}

void TasmMediator::OnReactComponentUnmount(const std::string& id) {
  runtime_actor_->ActAsync(
      [id](auto& runtime) { runtime->OnReactComponentUnmount(id); });
}

void TasmMediator::OnReactCardRender(const lepus::Value& data,
                                     bool should_component_update,
                                     bool force_flush) {
  runtime_actor_->ActAsync([safe_value = lepus_value::ShallowCopy(data),
                            should_component_update,
                            force_flush](auto& runtime) {
    runtime->OnReactCardRender(safe_value, should_component_update,
                               force_flush);
  });
}

void TasmMediator::OnReactCardDidUpdate() {
  runtime_actor_->ActAsync(
      [](auto& runtime) { runtime->OnReactCardDidUpdate(); });
}

void TasmMediator::PrintMsgToJS(const std::string& level,
                                const std::string& msg) {
  runtime_actor_->ActAsync([level, msg](auto& runtime) {
    runtime->ConsoleLogWithLevel(level, msg);
  });
}

void TasmMediator::OnI18nResourceChanged(const std::string& msg) {
  runtime_actor_->ActAsync(
      [msg](auto& runtime) { runtime->I18nResourceChanged(msg); });
}

void TasmMediator::OnCardDecoded(tasm::TemplateBundle bundle,
                                 const lepus::Value& global_props) {
  runtime_actor_->ActAsync([js_data_receiver = js_data_receiver_,
                            bundle = std::move(bundle),
                            global_props](auto& runtime) mutable {
    js_data_receiver->OnCardDecoded(std::move(bundle), global_props);
    runtime->SetCircularDataCheck(bundle.enable_circular_data_check);
  });
}

void TasmMediator::OnComponentDecoded(tasm::TemplateBundle bundle) {
  runtime_actor_->ActAsync([js_data_receiver = js_data_receiver_,
                            bundle = std::move(bundle)](auto& runtime) mutable {
    js_data_receiver->OnComponentDecoded(std::move(bundle));
  });
}

// delegate for class element manager
void TasmMediator::DispatchLayoutUpdates(const tasm::PipelineOptions& options) {
  layout_actor_->Act(
      [options](auto& layout) { layout->DispatchLayoutUpdates(options); });
}

void TasmMediator::DispatchLayoutHasBaseline() {
  layout_actor_->Act([](auto& layout) { layout->DispatchLayoutHasBaseline(); });
}

void TasmMediator::SetEnableLayout() {
  layout_actor_->Act([](auto& layout) { layout->SetEnableLayout(); });
}

void TasmMediator::SetRootOnLayout(
    const std::shared_ptr<tasm::LayoutNode>& root) {
  layout_actor_->Act([root](auto& layout) { layout->SetRoot(root); });
}

void TasmMediator::OnUpdateDataWithoutChange() {
  layout_actor_->Act([](auto& layout) { layout->OnUpdateDataWithoutChange(); });
}

void TasmMediator::OnUpdateViewport(float width, int width_mode, float height,
                                    int height_mode, bool need_layout) {
  layout_actor_->Act([width, width_mode, height, height_mode,
                      need_layout](auto& layout) {
    layout->UpdateViewport(width, width_mode, height, height_mode, need_layout);
  });
}

void TasmMediator::UpdateLynxEnvForLayoutThread(tasm::LynxEnvConfig env) {
  layout_actor_->Act(
      [env](auto& layout) { layout->UpdateLynxEnvForLayoutThread(env); });
}

void TasmMediator::SetHierarchyObserverOnLayout(
    const std::weak_ptr<tasm::HierarchyObserver>& hierarchy_observer) {
  layout_actor_->Act([hierarchy_observer](auto& layout) {
    layout->SetHierarchyObserver(hierarchy_observer);
  });
}

// delegate for class element
void TasmMediator::UpdateLayoutNodeFontSize(
    tasm::LayoutContext::SPLayoutNode node, double cur_node_font_size,
    double root_node_font_size, double font_scale) {
  layout_actor_->Act([node, cur_node_font_size, root_node_font_size,
                      font_scale](auto& layout) {
    layout->UpdateLayoutNodeFontSize(node, cur_node_font_size,
                                     root_node_font_size, font_scale);
  });
}

void TasmMediator::InsertLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                                    tasm::LayoutContext::SPLayoutNode child,
                                    int index) {
  layout_actor_->Act([parent, child, index](auto& layout) {
    layout->InsertLayoutNode(parent, child, index);
  });
}

void TasmMediator::SendAnimationEvent(const char* type, int tag,
                                      const lepus::Value& dict) {
  engine_actor_->Act([arguments = dict, tag, type](auto& engine) {
    engine->SendCustomEvent(type, tag, arguments, "params");
  });
}

void TasmMediator::RemoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                                    tasm::LayoutContext::SPLayoutNode child,
                                    int index, bool destroy) {
  layout_actor_->Act([parent, child, index, destroy](auto& layout) {
    layout->RemoveLayoutNode(parent, child, index, destroy);
  });
}

void TasmMediator::MoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                                  tasm::LayoutContext::SPLayoutNode child,
                                  int from_index, int to_index) {
  layout_actor_->Act([parent, child, from_index, to_index](auto& layout) {
    layout->MoveLayoutNode(parent, child, from_index, to_index);
  });
}

void TasmMediator::InsertLayoutNodeBefore(
    tasm::LayoutContext::SPLayoutNode parent,
    tasm::LayoutContext::SPLayoutNode child,
    tasm::LayoutContext::SPLayoutNode ref_node) {
  layout_actor_->Act([parent, child, ref_node](auto& layout) {
    layout->InsertLayoutNodeBefore(parent, child, ref_node);
  });
}

void TasmMediator::RemoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                                    tasm::LayoutContext::SPLayoutNode child) {
  layout_actor_->Act([parent, child](auto& layout) {
    layout->RemoveLayoutNode(parent, child);
  });
}
void TasmMediator::DestroyLayoutNode(tasm::LayoutContext::SPLayoutNode node) {
  layout_actor_->Act([node](auto& layout) { layout->DestroyLayoutNode(node); });
}

void TasmMediator::UpdateLayoutNodeStyle(tasm::LayoutContext::SPLayoutNode node,
                                         tasm::CSSPropertyID css_id,
                                         const tasm::CSSValue& value) {
  layout_actor_->Act([node, css_id, value](auto& layout) {
    layout->UpdateLayoutNodeStyle(node, css_id, value);
  });
}

void TasmMediator::ResetLayoutNodeStyle(tasm::LayoutContext::SPLayoutNode node,
                                        tasm::CSSPropertyID css_id) {
  layout_actor_->Act([node, css_id](auto& layout) {
    layout->ResetLayoutNodeStyle(node, css_id);
  });
}

void TasmMediator::UpdateLayoutNodeAttribute(
    tasm::LayoutContext::SPLayoutNode node, starlight::LayoutAttribute key,
    const lepus::Value& value) {
  layout_actor_->Act([node, key, value](auto& layout) {
    layout->UpdateLayoutNodeAttribute(node, key, value);
  });
}

void TasmMediator::SetFontFaces(const tasm::CSSFontFaceTokenMap& fontfaces) {
  layout_actor_->Act(
      [fontfaces](auto& layout) { layout->SetFontFaces(fontfaces); });
}

void TasmMediator::MarkNodeAnimated(tasm::LayoutContext::SPLayoutNode node,
                                    bool animated) {
  layout_actor_->Act([node, animated](auto& layout) {
    layout->MarkNodeAnimated(node, animated);
  });
}

void TasmMediator::UpdateLayoutNodeProps(
    tasm::LayoutContext::SPLayoutNode node,
    const std::shared_ptr<tasm::PropBundle>& props) {
  layout_actor_->Act([node, props](auto& layout) {
    layout->UpdateLayoutNodeProps(node, props);
  });
}

void TasmMediator::MarkLayoutDirty(tasm::LayoutContext::SPLayoutNode node) {
  layout_actor_->Act([node](auto& layout) {
    auto layout_node = node->FindNonVirtualNode();
    if (layout_node) {
      layout_node->MarkDirty();
    }
  });
}

void TasmMediator::RegisterPlatformAttachedLayoutNode(
    tasm::LayoutContext::SPLayoutNode node) {
  layout_actor_->Act([node](auto& layout) {
    layout->RegisterPlatformAttachedLayoutNode(node);
  });
}

void TasmMediator::HmrEvalJsCode(const std::string& source_code) {
#if ENABLE_HMR
  runtime_actor_->ActAsync(
      [source_code](auto& runtime) { runtime->OnHMRUpdate(source_code); });
#endif
}

void TasmMediator::InvokeUIMethod(tasm::LynxGetUIResult ui_result,
                                  const std::string& method,
                                  std::unique_ptr<piper::PlatformValue> params,
                                  piper::ApiCallBack callback) {
  facade_actor_->Act([ui_result = std::move(ui_result), method,
                      params = std::move(params),
                      callback](auto& facade) mutable {
    facade->InvokeUIMethod(ui_result, method, std::move(params), callback);
  });
}

void TasmMediator::InitAirRuntime(
    std::unique_ptr<air::AirModuleHandler>& module_handler) {
#if ENABLE_AIR
  air_runtime_ = std::make_unique<air::AirRuntime>(std::move(module_handler));
#endif
}

lepus::Value TasmMediator::TriggerBridgeSync(
    const std::string& method_name, const lynx::lepus::Value& arguments) {
#if ENABLE_AIR
  return air_runtime_->TriggerBridgeSync(method_name, arguments);
#else
  return lepus::Value();
#endif
}

void TasmMediator::TriggerBridgeAsync(
    lepus::Context* context, const std::string& method_name,
    const lynx::lepus::Value& arguments,
    std::unique_ptr<lepus::Value> callback_closure) {
#if ENABLE_AIR
  air_runtime_->TriggerBridgeAsync(context, method_name, arguments,
                                   std::move(callback_closure));
#endif
}

uint32_t TasmMediator::SetTimeOut(lepus::Context* context,
                                  std::unique_ptr<lepus::Value> closure,
                                  int64_t delay_time) {
#if ENABLE_AIR
  return air_runtime_->SetTimeOut(context, std::move(closure), delay_time);
#else
  return 0;
#endif
}

uint32_t TasmMediator::SetTimeInterval(lepus::Context* context,
                                       std::unique_ptr<lepus::Value> closure,
                                       int64_t interval_time) {
#if ENABLE_AIR
  return air_runtime_->SetTimeInterval(context, std::move(closure),
                                       interval_time);
#else
  return 0;
#endif
}

void TasmMediator::RemoveTimeTask(uint32_t task_id) {
#if ENABLE_AIR
  air_runtime_->RemoveTimeTask(task_id);
#endif
}

void TasmMediator::InvokeAirCallback(int64_t id, const std::string& entry_name,
                                     const lepus::Value& data) {
#if ENABLE_AIR
  air_runtime_->InvokeTask(id, entry_name, data);
#endif
}

}  // namespace shell
}  // namespace lynx
