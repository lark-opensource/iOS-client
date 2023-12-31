// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_SERVER_SHELL_SERVER_TASM_MEDIATOR_H_
#define LYNX_SSR_SERVER_SHELL_SERVER_TASM_MEDIATOR_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "base/closure.h"
#include "shell/lynx_engine.h"
#include "shell/native_facade.h"

namespace lynx {
namespace ssr {

class VSyncMonitor;

// ensure run on tasm thread, lifecycle manage by LynxEngine
class ServerTasmMediator : public shell::LynxEngine::Delegate {
 public:
  ServerTasmMediator() {}

  ~ServerTasmMediator() override = default;

  void OnDataUpdated() override{};

  void OnTasmFinishByNative() override {}

  void OnTemplateLoaded(const std::string& url) override {}

  void OnSSRHydrateFinished(const std::string& url) override {}

  void OnErrorOccurred(int32_t error_code, const std::string& msg) override {}

  void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override {}

  void OnUpdatePerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override {}

  void OnDynamicComponentPerfReady(
      const std::unordered_map<std::string,
                               base::PerfCollector::DynamicComponentPerfInfo>&
          dynamic_component_perf) override {}

  void OnConfigUpdated(const lepus::Value& data) override {}

  void OnPageConfigDecoded(
      const std::shared_ptr<tasm::PageConfig>& config) override {}

  void NotifyJSUpdatePageData(base::closure callback) override {}

  // TODO: bridge Node js
  std::string TranslateResourceForTheme(const std::string& res_id,
                                        const std::string& theme_key) override {
    return "";
  }

  void GetI18nResource(const std::string& channel,
                       const std::string& fallback_url) override {}

  void OnNativeAppReady() override {}

  void OnJSSourcePrepared(
      const std::string& page_name, tasm::PackageInstanceDSL dsl,
      tasm::PackageInstanceBundleModuleMode bundle_module_mode,
      const std::string& url) override {}

  void CallJSApiCallback(piper::ApiCallBack callback) override {}

  void CallJSApiCallbackWithValue(piper::ApiCallBack callback,
                                  const lepus::Value& value) override {}

  void CallJSFunction(const std::string& module_id,
                      const std::string& method_id,
                      const lepus::Value& arguments) override {}

  // Lepus bridge, won't support;
  lepus::Value TriggerLepusMethod(const std::string& method_id,
                                  const lepus::Value& arguments) override {
    return lepus::Value();
  }

  void TriggerLepusMethodAsync(const std::string& method_name,
                               const lepus::Value& arguments) override {}

  void CallJSFunctionInLepusEvent(const int64_t component_id,
                                  const std::string& name,
                                  const lepus::Value& params) override {}

  void SendPageEvent(const std::string& page_name, const std::string& handler,
                     const lepus::Value& info) override {}

  void PublicComponentEvent(const std::string& component_id,
                            const std::string& handler,
                            const lepus::Value& info) override {}

  void SendGlobalEvent(const std::string& name,
                       const lepus::Value& info) override {}
  void OnDataUpdatedByNative(const lepus::Value& data, const bool read_only,
                             const bool reset,
                             base::closure callback) override {}

  void OnJSAppReload(const lepus::Value& data) override {}

  void OnLifecycleEvent(const lepus::Value& args) override {}

  void NotifyGlobalPropsUpdated(const lepus::Value& props) override {}

  void OnDynamicJSSourcePrepared(const std::string& source) override {}

  void OnComponentActivity(const std::string& action,
                           const std::string& component_id,
                           const std::string& parent_component_id,
                           const std::string& path,
                           const std::string& entry_name,
                           const lepus::Value& data) override {}

  void OnComponentPropertiesChanged(const std::string& component_id,
                                    const lepus::Value& properties) override {}

  void OnReactComponentRender(const std::string& id, const lepus::Value& props,
                              const lepus::Value& data,
                              bool should_component_update) override {}

  void OnComponentDataSetChanged(const std::string& component_id,
                                 const lepus::Value& data_set) override {}
  void OnComponentSelectorChanged(const std::string& component_id,
                                  const lepus::Value& instance) override {}

  void OnReactComponentDidUpdate(const std::string& id) override {}
  void OnReactComponentDidCatch(const std::string& id,
                                const lepus::Value& error) override {}

  void OnReactComponentCreated(const std::string& entry_name,
                               const std::string& path, const std::string& id,
                               const lepus::Value& props,
                               const lepus::Value& data,
                               const std::string& parent_id,
                               bool force_flush) override {}

  void OnReactComponentUnmount(const std::string& id) override {}

  void OnReactCardRender(const lepus::Value& data, bool should_component_update,
                         bool force_flush) override {}

  void OnReactCardDidUpdate() override {}

  void PrintMsgToJS(const std::string& level, const std::string& msg) override {
  }

  void OnI18nResourceChanged(const std::string& res) override {}

  void OnCardDecoded(tasm::TemplateBundle bundle,
                     const lepus::Value& global_props) override {}

  void OnComponentDecoded(tasm::TemplateBundle bundle) override {}

  void OnCardConfigDataChanged(const lepus::Value& data) override {}

  void SetTiming(tasm::Timing timing) override {}

  void Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack) override {}

  void RequestVsync(
      uintptr_t id,
      base::MoveOnlyClosure<void, int64_t, int64_t> callback) override {}
  // delegate for class element manager
  void DispatchLayoutUpdates(const tasm::PipelineOptions& options) override {}
  void DispatchLayoutHasBaseline() override {}
  void SetRootOnLayout(const std::shared_ptr<tasm::LayoutNode>& root) override {
  }
  void OnUpdateDataWithoutChange() override {}
  void OnUpdateViewport(float width, int width_mode, float height,
                        int height_mode, bool need_layout) override {}
  void UpdateLynxEnvForLayoutThread(tasm::LynxEnvConfig env) override {}
  void SetHierarchyObserverOnLayout(
      const std::weak_ptr<tasm::HierarchyObserver>& hierarchy_observer)
      override {}

  // delegate for class element

  virtual void SendAnimationEvent(const char* type, int tag,
                                  const lepus::Value& dict) override {}
  void UpdateLayoutNodeFontSize(tasm::LayoutContext::SPLayoutNode node,
                                double cur_node_font_size,
                                double root_node_font_size,
                                double font_scale) override {}
  void InsertLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                        tasm::LayoutContext::SPLayoutNode child,
                        int index) override {}
  void RemoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                        tasm::LayoutContext::SPLayoutNode child, int index,
                        bool destroy) override {}
  void InsertLayoutNodeBefore(
      tasm::LayoutContext::SPLayoutNode parent,
      tasm::LayoutContext::SPLayoutNode child,
      tasm::LayoutContext::SPLayoutNode ref_node) override {}
  void RemoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                        tasm::LayoutContext::SPLayoutNode child) override {}
  void DestroyLayoutNode(tasm::LayoutContext::SPLayoutNode node) override {}
  void MoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                      tasm::LayoutContext::SPLayoutNode child, int from_index,
                      int to_index) override {}
  void UpdateLayoutNodeStyle(tasm::LayoutContext::SPLayoutNode node,
                             tasm::CSSPropertyID css_id,
                             const tasm::CSSValue& value) override {}
  void ResetLayoutNodeStyle(tasm::LayoutContext::SPLayoutNode node,
                            tasm::CSSPropertyID css_id) override {}
  void UpdateLayoutNodeAttribute(tasm::LayoutContext::SPLayoutNode node,
                                 starlight::LayoutAttribute key,
                                 const lepus::Value& value) override {}
  void SetFontFaces(const tasm::CSSFontFaceTokenMap& fontfaces) override {}
  void MarkNodeAnimated(tasm::LayoutContext::SPLayoutNode node,
                        bool animated) override {}
  void UpdateLayoutNodeProps(
      tasm::LayoutContext::SPLayoutNode node,
      const std::shared_ptr<tasm::PropBundle>& props) override {}
  void MarkLayoutDirty(tasm::LayoutContext::SPLayoutNode node) override {}

  void HmrEvalJsCode(const std::string& sourceCode) override {}

  void SetEnableLayout() override {}

  void InvokeUIMethod(tasm::LynxGetUIResult ui_result,
                      const std::string& method,
                      std::unique_ptr<piper::PlatformValue> params,
                      piper::ApiCallBack callback) override {}
  void RegisterPlatformAttachedLayoutNode(
      tasm::LayoutContext::SPLayoutNode node) override {}

  void OnSsrScriptReady(std::string script) override{};
  lepus::Value TriggerBridgeSync(const std::string& method_name,
                                 const lynx::lepus::Value& arguments) override {
    return lepus::Value();
  };
  void TriggerBridgeAsync(
      lepus::Context* context, const std::string& method_name,
      const lynx::lepus::Value& arguments,
      std::unique_ptr<lepus::Value> callback_closure) override{};
  uint32_t SetTimeOut(lepus::Context* context,
                      std::unique_ptr<lepus::Value> closure,
                      int64_t delay_time) override {
    return 0;
  };
  uint32_t SetTimeInterval(lepus::Context* context,
                           std::unique_ptr<lepus::Value> closure,
                           int64_t interval_time) override {
    return 0;
  };
  void RemoveTimeTask(uint32_t task_id) override{};
  void InvokeAirCallback(int64_t id, const std::string& entry_name,
                         const lepus::Value& data) override{};

  ServerTasmMediator(const ServerTasmMediator&) = delete;
  ServerTasmMediator& operator=(const ServerTasmMediator&) = delete;
  ServerTasmMediator(ServerTasmMediator&&) = delete;
  ServerTasmMediator& operator=(ServerTasmMediator&&) = delete;
};

}  // namespace ssr
}  // namespace lynx

#endif  // LYNX_SSR_SERVER_SHELL_SERVER_TASM_MEDIATOR_H_
