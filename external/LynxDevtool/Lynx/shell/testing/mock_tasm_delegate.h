// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_TESTING_MOCK_TASM_DELEGATE_H_
#define LYNX_SHELL_TESTING_MOCK_TASM_DELEGATE_H_

#include <memory>
#include <string>
#include <unordered_map>

#include "base/closure.h"
#include "base/perf_collector.h"
#include "jsbridge/bindings/api_call_back.h"
#include "tasm/lynx_get_ui_result.h"
#include "tasm/react/element_manager.h"
#include "tasm/template_assembler.h"

namespace lynx {
namespace tasm {
namespace test {

class MockTasmDelegate : public TemplateAssembler::Delegate,
                         public ElementManager::Delegate {
 public:
  MockTasmDelegate() {}
  virtual ~MockTasmDelegate() {}
  virtual void OnDataUpdated() override;
  virtual void OnTasmFinishByNative() override;
  virtual void OnTemplateLoaded(const std::string& url) override;
  virtual void OnSSRHydrateFinished(const std::string& url) override;
  virtual void OnErrorOccurred(int32_t error_code,
                               const std::string& msg) override;
  virtual void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override;
  virtual void OnUpdatePerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override;
  virtual void OnDynamicComponentPerfReady(
      const std::unordered_map<std::string,
                               base::PerfCollector::DynamicComponentPerfInfo>&
          dynamic_component_perf) override;
  virtual void OnConfigUpdated(const lepus::Value& data) override;
  virtual void OnPageConfigDecoded(
      const std::shared_ptr<tasm::PageConfig>& config) override;
  virtual void HmrEvalJsCode(const std::string& source_code) override;

  // synchronous
  virtual std::string TranslateResourceForTheme(
      const std::string& res_id, const std::string& theme_key) override;

  virtual void GetI18nResource(const std::string& channel,
                               const std::string& fallback_url) override;

  virtual void OnI18nResourceChanged(const std::string& res) override;

  virtual void OnNativeAppReady() override;
  virtual void OnJSSourcePrepared(
      const std::string& page_name, tasm::PackageInstanceDSL dsl,
      tasm::PackageInstanceBundleModuleMode bundle_module_mode,
      const std::string& url) override;
  virtual void CallJSApiCallback(piper::ApiCallBack callback) override;
  virtual void CallJSApiCallbackWithValue(piper::ApiCallBack callback,
                                          const lepus::Value& value) override;
  virtual void CallJSFunction(const std::string& module_id,
                              const std::string& method_id,
                              const lepus::Value& arguments) override;
  virtual void OnDataUpdatedByNative(const lepus::Value& data,
                                     const bool read_only,
                                     const bool reset = false,
                                     base::closure callback = nullptr) override;
  virtual void OnJSAppReload(const lepus::Value& init_data) override;
  virtual void OnLifecycleEvent(const lepus::Value& args) override;
  virtual void OnDynamicJSSourcePrepared(const std::string& source) override;
  virtual void PrintMsgToJS(const std::string& level,
                            const std::string& msg) override;

  virtual void SendAnimationEvent(const char* type, int tag,
                                  const lepus::Value& dict) override {}

  // LynxEngine::Delegate
  void OnComponentActivity(const std::string& action,
                           const std::string& component_id,
                           const std::string& parent_component_id,
                           const std::string& path,
                           const std::string& entry_name,
                           const lepus::Value& data) override;
  // LynxEngine::Delegate
  void OnComponentPropertiesChanged(const std::string& component_id,
                                    const lepus::Value& properties) override;

  // LynxEngine::Delegate
  void OnComponentDataSetChanged(const std::string& component_id,
                                 const lepus::Value& data_set) override;

  // LynxEngine::Delegate
  void OnComponentSelectorChanged(const std::string& component_id,
                                  const lepus::Value& instance) override;

  // LynxEngine::Delegate
  void OnReactComponentRender(const std::string& id, const lepus::Value& props,
                              const lepus::Value& data,
                              bool should_component_update) override;

  // LynxEngine::Delegate
  void OnReactComponentDidUpdate(const std::string& id) override;

  // LynxEngine::Delegate
  void OnReactComponentDidCatch(const std::string& id,
                                const lepus::Value& error) override;

  // LynxEngine::Delegate
  void OnReactComponentCreated(const std::string& entry_name,
                               const std::string& path, const std::string& id,
                               const lepus::Value& props,
                               const lepus::Value& data,
                               const std::string& parent_id, bool) override;

  // LynxEngine::Delegate
  void OnReactComponentUnmount(const std::string& id) override;

  // LynxEngine::Delegate
  void OnReactCardRender(const lepus::Value& data, bool should_component_update,
                         bool) override;

  // LynxEngine::Delegate
  void OnReactCardDidUpdate() override;

  // LynxEngine::Delegate
  void SendPageEvent(const std::string& page_name, const std::string& handler,
                     const lepus::Value& info) override;

  // LynxEngine::Delegate
  void PublicComponentEvent(const std::string& component_id,
                            const std::string& handler,
                            const lepus::Value& info) override;

  // LynxEngine::Delegate
  void CallJSFunctionInLepusEvent(const int64_t component_id,
                                  const std::string& name,
                                  const lepus::Value& params) override;

  // LynxEngine::Delegate
  void SendGlobalEvent(const std::string& name,
                       const lepus::Value& info) override;

  // LynxEngine::Delegate
  void OnCardDecoded(tasm::TemplateBundle bundle,
                     const lepus::Value& global_props) override;

  // LynxEngine::Delegate
  void OnComponentDecoded(tasm::TemplateBundle bundle) override;

  void OnCardConfigDataChanged(const lepus::Value& data) override;

  void NotifyGlobalPropsUpdated(const lepus::Value& props) override;

  void RequestVsync(
      uintptr_t id,
      base::MoveOnlyClosure<void, int64_t, int64_t> callback) override;

  lepus::Value TriggerLepusMethod(const std::string& method_id,
                                  const lepus::Value& arguments) override;

  void TriggerLepusMethodAsync(const std::string& method_id,
                               const lepus::Value& arguments) override;

  std::string DumpDelegate() { return ss_.str(); }
  void ResetThemeConfig();

  void DispatchLayoutUpdates(const PipelineOptions& options) override {
    dispatch_layout_updates_called_ = true;
  }
  void DispatchLayoutHasBaseline() override {}

  void SetEnableLayout() override { set_enable_layout_called_ = true; }

  void UpdateLayoutNodeFontSize(LayoutContext::SPLayoutNode node,
                                double cur_node_font_size,
                                double root_node_font_size,
                                double font_scale) override {}
  void InsertLayoutNode(LayoutContext::SPLayoutNode parent,
                        LayoutContext::SPLayoutNode child, int index) override {
    parent->InsertNode(child, index);
  }
  void RemoveLayoutNode(LayoutContext::SPLayoutNode parent,
                        LayoutContext::SPLayoutNode child, int index,
                        bool destroy = true) override {
    parent->RemoveNode(child, index);
  }
  void InsertLayoutNodeBefore(LayoutContext::SPLayoutNode parent,
                              LayoutContext::SPLayoutNode child,
                              LayoutContext::SPLayoutNode ref) override {
    int index = 0;
    if (ref == nullptr) {
      // null ref node indicates to append the child to the end
      index = static_cast<int>(parent->children().size());
    } else {
      for (const auto& node : parent->children()) {
        if (node == ref) {
          break;
        }
        ++index;
      }
    }
    parent->InsertNode(child, index);
  }

  void RemoveLayoutNode(LayoutContext::SPLayoutNode parent,
                        LayoutContext::SPLayoutNode child) override {
    int index = 0;
    for (const auto& node : parent->children()) {
      if (node == child) {
        break;
      }
      ++index;
    }
    parent->RemoveNode(child, index);
  }
  void DestroyLayoutNode(LayoutContext::SPLayoutNode node) override {
    // do nothing for mock
  }

  void MoveLayoutNode(LayoutContext::SPLayoutNode parent,
                      LayoutContext::SPLayoutNode child, int from_index,
                      int to_index) override {
    parent->MoveNode(child, from_index, to_index);
  }
  void UpdateLayoutNodeStyle(LayoutContext::SPLayoutNode node,
                             CSSPropertyID css_id,
                             const tasm::CSSValue& value) override {
    node->ConsumeStyle(css_id, value);
  }
  void ResetLayoutNodeStyle(LayoutContext::SPLayoutNode node,
                            CSSPropertyID css_id) override {}
  void UpdateLayoutNodeAttribute(LayoutContext::SPLayoutNode node,
                                 starlight::LayoutAttribute key,
                                 const lepus::Value& value) override {
    node->ConsumeAttribute(key, value);
  }
  void SetFontFaces(const CSSFontFaceTokenMap& fontfaces) override {}
  void MarkNodeAnimated(LayoutContext::SPLayoutNode node,
                        bool animated) override {}
  void UpdateLayoutNodeProps(
      LayoutContext::SPLayoutNode node,
      const std::shared_ptr<PropBundle>& props) override {}
  void MarkLayoutDirty(tasm::LayoutContext::SPLayoutNode node) override {}
  void UpdateLynxEnvForLayoutThread(LynxEnvConfig env) override {
    if (root_) {
      root_->slnode()->UpdateLynxEnv(env);
    }
  }
  void OnUpdateViewport(float width, int width_mode, float height,
                        int height_mode, bool need_layout) override {}
  void SetRootOnLayout(const std::shared_ptr<LayoutNode>& root) override {
    root_ = root;
  }
  void OnUpdateDataWithoutChange() override {}
  void SetHierarchyObserverOnLayout(
      const std::weak_ptr<HierarchyObserver>& hierarchy_observer) override {}
  void RegisterPlatformAttachedLayoutNode(
      LayoutContext::SPLayoutNode node) override {}
#if ENABLE_ARK_RECORDER
  void SetRecordId(int64_t record_id) override {}
#endif
  void SetTiming(tasm::Timing timing) override {}
  void InvokeUIMethod(tasm::LynxGetUIResult ui_result,
                      const std::string& method,
                      std::unique_ptr<piper::PlatformValue> params,
                      piper::ApiCallBack callback) override {}
  void OnSsrScriptReady(std::string script) override;
  lepus::Value TriggerBridgeSync(const std::string& method_name,
                                 const lynx::lepus::Value& arguments) override {
    return lepus::Value(0);
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

 private:
  std::stringstream ss_;
  std::unique_ptr<std::unordered_map<std::string, std::string>>
      light_color_map_;
  std::unique_ptr<std::unordered_map<std::string, std::string>> dark_color_map_;
  std::unique_ptr<std::unordered_map<std::string, std::string>> theme_config_;
  void UpdateMockDelegateThemeConfig(const lepus::Value& data);

  std::shared_ptr<LayoutNode> root_;

  bool set_enable_layout_called_{false};
  bool dispatch_layout_updates_called_{false};

  std::string lepus_method_id_{};
  lepus::Value lepus_method_arguments_{};
};

}  // namespace test

}  // namespace tasm

}  // namespace lynx

#endif  // LYNX_SHELL_TESTING_MOCK_TASM_DELEGATE_H_
