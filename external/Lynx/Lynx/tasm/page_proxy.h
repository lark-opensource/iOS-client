// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_PAGE_PROXY_H_
#define LYNX_TASM_PAGE_PROXY_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "tasm/page_config.h"
#include "tasm/radon/base_component.h"
#include "tasm/react/element_manager.h"
#include "tasm/template_themed.h"

namespace lynx {
namespace lepus {
class Value;
}
namespace tasm {
class RadonComponent;
class RadonDynamicComponent;
class RadonPage;
class RadonNode;
class BaseComponent;
class PageDelegate;
class RadonElement;
class ElementManager;
class TouchEventHandler;
class LynxGetUIResult;
struct NodeSelectOptions;
struct NodeSelectRoot;

struct UpdatePageOption {
  lepus::Value ToLepusValue() const;

  // Update data or reset data from native.
  // from_native would be false if the data is updated from JS.
  bool from_native = true;

  // Clear current data and update with the new given data.
  // Used in ResetData and ResetDataAndRefreshLifecycle by now.
  bool reset_page_data = false;

  // Update data first time in loadTemplate.
  bool update_first_time = false;

  // Refresh the card and component's lifecycle like a new loaded template.
  // Used only in ReloadTemplate by now.
  bool reload_template = false;

  // used in UpdateGlobalProps
  bool global_props_changed = false;

  // used in lynx.reload() api
  bool reload_from_js = false;

  // This variable records the order of native update data. Used for syncFlush
  // only.
  uint32_t native_update_data_order_ = 0;
};

class PageProxy {
 public:
  PageProxy(std::unique_ptr<ElementManager> client_ptr, PageDelegate *delegate);

  virtual ~PageProxy();

  bool is_dry_run_ = false;

  PageProxy(const PageProxy &) = delete;
  PageProxy(PageProxy &&) = delete;

  PageProxy &operator=(const PageProxy &) = delete;
  PageProxy &operator=(PageProxy &&) = delete;

  // used in ReloadTemplate, call old components' unmount lifecycle.
  void RemoveOldComponentBeforeReload();

  // Runtime Lifecycle
  void OnComponentAdded(BaseComponent *node);
  void OnComponentRemoved(BaseComponent *node);
  void OnComponentMoved(BaseComponent *node);

  void OnComponentPropertyChanged(BaseComponent *node);
  void OnComponentDataSetChanged(BaseComponent *node,
                                 const lepus::Value &data_set);
  void OnComponentSelectorChanged(BaseComponent *node,
                                  const lepus::Value &instance);
  // for react
  void OnReactComponentCreated(BaseComponent *component,
                               const lepus::Value &props,
                               const lepus::Value &data,
                               const std::string &parent_id);
  void OnReactComponentRender(BaseComponent *component,
                              const lepus::Value &props,
                              const lepus::Value &data,
                              bool should_component_update);
  void OnReactComponentDidUpdate(BaseComponent *component);
  void OnReactComponentDidCatch(BaseComponent *component,
                                const lepus::Value &error);

  void OnReactComponentUnmount(BaseComponent *component);

  void OnReactCardDidUpdate();
  void OnReactCardRender(const lepus::Value &data,
                         bool should_component_update);

#ifdef ENABLE_TEST_DUMP
  std::string DumpTree();
#endif

  bool UpdateGlobalProps(const lepus::Value &table, bool should_render);

  lepus::Value GetGlobalPropsFromTasm() const;

  void SetInvalidated(bool invalidated);

  void UpdateComponentData(const std::string &id, const lepus::Value &table);

  bool UpdateGlobalDataInternal(const lepus_value &value,
                                const UpdatePageOption &update_page_option);

  const lepus::Value GetComponentContextDataByKey(const std::string &id,
                                                  const std::string &key);

  bool UpdateConfig(const lepus::Value &config, lepus::Value &out,
                    bool to_refresh);

  std::unique_ptr<lepus::Value> GetData();

  lepus::Value GetDataByKey(const std::vector<std::string> &keys);

  void ForceUpdateInLoadDynamicComponent(const std::string &url,
                                         TemplateAssembler *tasm,
                                         const std::vector<uint32_t> &uid_list);

  // collect impl ids of failed components and try to render fallback
  void OnFailInLoadDynamicComponent(const std::vector<uint32_t> &uid_list,
                                    std::vector<int> &impl_ids);

  void UpdateInLoadTemplate(lepus::Value &data);
  void ForceUpdate();

  void SetRadonPage(RadonPage *page);
  bool HasRadonPage() const { return radon_page_ != nullptr; }
  bool HasSSRRadonPage() const { return ssr_radon_page_ != nullptr; }
  BaseComponent *ComponentWithId(int component_id);
  Element *ComponentElementWithStrId(const std::string &id);
  RadonPage *Page() { return radon_page_.get(); }
  RadonPage *SSRPage() { return ssr_radon_page_.get(); }
  void ResetSSRPage();

  bool isUpdatingConfig() const { return is_updating_config_; }

  const std::unique_ptr<ElementManager> &element_manager() const {
    return client_;
  }

  void SetCSSVariables(const std::string &component_id,
                       const std::string &id_selector,
                       const lepus::Value &properties);

  std::vector<std::string> SelectComponent(const std::string &comp_id,
                                           const std::string &id_selector,
                                           const bool single) const;

  /**
   * Select elements using given options.
   * @param root root node of the select operation.
   * @param options options of node selecting.
   * @return result of selected elements.
   */
  LynxGetUIResult GetLynxUI(const NodeSelectRoot &root,
                            const NodeSelectOptions &options) const;

  // Returns an Element vector for the given selector.
  //  comp_id is the root component's id.
  //    * If id selector, must begin with '#'.
  //    * If class selector, must begin with '.'.
  //    * Others are considered to be tag selector.
  //  selector is the target elements' selector.
  //  single determines whether to find all elements that contains the selector.
  //  current_component current_component determines whether to search only in
  //  the current component.
  std::vector<Element *> SelectElements(const NodeSelectRoot &root,
                                        const NodeSelectOptions &options) const;

  Themed &themed() { return themed_; }

  lepus::Value GetConfig() { return config_; };

  bool GetEnableSavePageData() { return client_->GetEnableSavePageData(); }

  bool GetEnableComponentNullProp() {
    return client_->GetEnableComponentNullProp();
  }

  bool GetEnableCheckDataWhenUpdatePage() {
    return client_->GetEnableCheckDataWhenUpdatePage();
  }

  bool GetListNewArchitecture() { return client_->GetListNewArchitecture(); }

  bool GetListRemoveComponent() { return client_->GetListRemoveComponent(); }

  bool GetListEnableMoveOperation() {
    return client_->GetListEnableMoveOperation();
  }

  bool GetListEnablePlug() { return client_->GetListEnablePlug(); }

  bool GetStrictPropType() { return client_->GetStrictPropType(); }

  void SetTasmEnableLayoutOnly(bool enable_layout_only);

  bool IsRadonDiff() const { return is_radon_diff_; }
  void SetRadonDiff(bool is_radon_diff) { is_radon_diff_ = is_radon_diff; }
  void UpdateComponentInComponentMap(RadonComponent *component);

  bool GetCSSScopeEnabled() { return css_scope_enabled_; }

  void SetCSSScopeEnabled(bool css_scope_enabled) {
    css_scope_enabled_ = css_scope_enabled;
  }

  bool GetPageElementEnabled() { return page_element_enable_; }

  void SetPageElementEnabled(bool page_element_enable) {
    page_element_enable_ = page_element_enable;
  }

  bool GetEnableReactOnlyPropsId() const {
    return client_->GetEnableReactOnlyPropsId();
  }

  bool GetEnableGlobalComponentMap() const {
    return client_->GetEnableGlobalComponentMap();
  }

  bool GetEnableRemoveComponentExtraData() const {
    return client_->GetEnableRemoveComponentExtraData();
  }

  bool GetEnableAttributeTimingFlag() const {
    return client_->GetEnableAttributeTimingFlag();
  }

  lepus::Value ProcessReactPropsForJS(const lepus::Value &props) const;

  lepus::Value ProcessInitDataForJS(const lepus::Value &data);

  void FireComponentLifecycleEvent(const std::string name,
                                   BaseComponent *component,
                                   const lepus::Value &data = lepus::Value());

  bool GetComponentLifecycleAlignWithWebview() {
    return client_->GetEnableComponentLifecycleAlignWebview();
  }

  lepus::Value GetPathInfo(const NodeSelectRoot &root,
                           const NodeSelectOptions &options);

  lepus::Value GetFields(const NodeSelectRoot &root,
                         const tasm::NodeSelectOptions &options,
                         const std::vector<std::string> &fields);

  void OnScreenMetricsSet(float &width, float &height);

  void ExecuteScreenMetricsOverrideWhenTemplateIsLoaded();

  const std::unordered_map<int, RadonComponent *> &GetComponentMap() {
    return component_map_;
  };

  // SSR and Hydration related methods.
  lepus::Value GetDefaultPageData() const { return default_page_data_; }

  // SSR and Hydration related methods.
  lepus::Value GetDefaultGlobalProps() const { return default_global_props_; }

  // Initialization data for ssr service.
  void UpdateInitDataForSSRServer(const lepus::Value &page_data,
                                  const lepus::Value &system_info);

  // The function will be called when js constructor is called to record the
  // number of js constructor running in react lynx.
  void IncreaseJSRenderCounterForHydrating() {
    if (HasSSRRadonPage() && IsReact()) {
      ++hydrate_info_.components_pending_js_render_;
    }
  }

  // The function will be called when js constructor ends to notify a js
  // construction of a component is done.
  void OnReactComponentJSFirstScreenReady();

  // To mark if the lepus update of first screen is done.
  void OnLepusFirstScreenDone() {
    hydrate_info_.lepus_first_screen_done_ = true;
  }

  // To hydrate a react lynx page, have to wait till all first screen operation
  // (both lepus and js) are done. When lepus first screen is done and no js
  // constructor is running, the react page is ready to be hydrated.
  bool ReadyToHydrate() const {
    return HasSSRRadonPage() &&
           hydrate_info_.components_pending_js_render_ == 0 &&
           hydrate_info_.lepus_first_screen_done_;
  }

  // Hydration may be triggered immediately after lepus rendered the page if no
  // js constructor is triggered. And otherwise hydration will be triggered when
  // all pending js tasks are done.
  void HydrateOnFirstScreenIfPossible();

  // When the data used for server side rendering is the same with the current
  // client side page data. It can be assumed that the page rendered on client
  // side is identical as the one rendered on server. Therefore diff operation
  // can be skipped in this case.
  bool HydrateDataIdenticalAsSSR() const {
    return hydrate_info_.hydrate_data_identical_as_ssr_;
  }

  void RenderToBinary(const base::MoveOnlyClosure<void, RadonNode *,
                                                  tasm::TemplateAssembler *> &,
                      tasm::TemplateAssembler *);
  bool IsServerSideRendering();

  void RenderWithSSRData(const lepus::Value &data,
                         const lepus::Value &injected_data, int32_t trace_id);

  void DiffHydrationData(const lepus::Value &data);

  void ResetHydrateInfo() { hydrate_info_ = HydrateInfo(); }

  const lepus::Value &component_info_map() const { return component_info_map_; }

  const lepus::Value &component_path_map() const { return component_path_map_; }

  lepus::Value &component_info_map() {
    return const_cast<lepus::Value &>(
        static_cast<const PageProxy *>(this)->component_info_map());
  }

  lepus::Value &component_path_map() {
    return const_cast<lepus::Value &>(
        static_cast<const PageProxy *>(this)->component_path_map());
  }

  uint32_t GetNextComponentID();

  void ResetComponentId();

 private:
  bool destroyed_{false};
  PageDelegate *delegate_ = nullptr;

  /* Be CAREFUL when you adjust the order of the declaration of following data
   * members. Make sure that the dtor of `client_` will be called after the
   * dtors of the `radon_page_` and `differentiator_` being called.
   *
   * During the dtor of `RadonNode`, the `element_` (which is an `Element`, a
   * data member of the `RadonNode`) needs to remove itself from the
   * `node_manager_ held by `client_`.
   *
   * Differentiator will use raw pointer of ElementManager, so `differentiator_`
   * should be released before `client_`.
   */
  std::unique_ptr<ElementManager> client_;

  // Hold component's element, use component id as key
  std::unordered_map<int, RadonComponent *> component_map_;
  using EmptyComponentMap = std::unordered_map<int, RadonDynamicComponent *>;
  EmptyComponentMap empty_component_map_;
  std::unique_ptr<RadonPage> radon_page_;
  lepus::Value global_props_;
  friend class RadonPage;
  bool is_updating_config_ = false;
  bool is_radon_diff_{false};
  bool css_scope_enabled_{false};
  bool page_element_enable_{false};

  lepus::Value config_;  // cache the config
  Themed themed_;

  lepus::Value default_page_data_;
  lepus::Value default_global_props_;

  // global maps usually used to create component or dynamic component
  lepus::Value component_info_map_ = lepus::Value(lepus::Dictionary::Create());
  lepus::Value component_path_map_ = lepus::Value(lepus::Dictionary::Create());

  // A page constructed with server side rendering output.
  // It will be destroyed once the page get hydrated.
  std::unique_ptr<RadonPage> ssr_radon_page_;

  // A structure holding the status before ssr page get hydrated.
  struct HydrateInfo {
    uint32_t components_pending_js_render_ = 0;
    bool lepus_first_screen_done_ = false;
    bool hydrate_data_identical_as_ssr_ = false;
  };
  HydrateInfo hydrate_info_;

  void UpdateThemedTransMapsBeforePageUpdated();
  friend class TouchEventHandler;

  bool NeedSendTTComponentLifecycle(BaseComponent *node) const;
  bool IsReact() const;
  bool CheckComponentExists(int component_id) const;
  std::string GetParentComponentId(BaseComponent *component) const;

  void AdoptComponent(BaseComponent *component);
  bool EraseComponent(BaseComponent *component);
  // component id is self-increasing
  uint32_t component_id_generator_{1};

  void TraverseEmptyComponentsInOrder(
      const std::vector<uint32_t> &uid_list,
      base::MoveOnlyClosure<bool, uint32_t, EmptyComponentMap::iterator &>
          func);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_PAGE_PROXY_H_
