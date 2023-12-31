// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/page_proxy.h"

#include <algorithm>
#include <utility>

#include "base/perf_collector.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/value.h"
#include "ssr/dom_reconstruct_utils.h"
#include "tasm/lynx_get_ui_result.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/radon/node_path_info.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/radon/node_selector.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_dynamic_component.h"
#include "tasm/radon/radon_page.h"
#include "tasm/react/element_manager.h"
#include "tasm/react/fiber/fiber_node_info.h"
#include "tasm/selector/fiber_element_selector.h"
#include "tasm/template_assembler.h"
#include "tasm/value_utils.h"

#if ENABLE_AIR
#include "tasm/air/air_element/air_page_element.h"
#endif

#ifdef ENABLE_TEST_DUMP
#include "third_party/rapidjson/document.h"
#include "third_party/rapidjson/prettywriter.h"
#include "third_party/rapidjson/stringbuffer.h"
#endif

namespace lynx {
namespace tasm {

lepus::Value UpdatePageOption::ToLepusValue() const {
  auto dict = lepus::Dictionary::Create();
  // When performing native data updates, the UpdatePageOption should also be
  // passed as a parameter to the LepusRuntime. Therefore, the ToLepusValue
  // function has been added to the UpdatePageOption. Currently, only
  // resetPageData and reloadTemplate will be used in Fiber, so only these two
  // parameters will be passed. If other parameters are needed in the future,
  // they will be added accordingly.
  constexpr const static char *kResetPageData = "resetPageData";
  constexpr const static char *kReloadFromJS = "reloadFromJS";
  constexpr const static char *kReloadTemplate = "reloadTemplate";

  // Clear current data and update with the new given data.
  // Used in ResetData and ResetDataAndRefreshLifecycle by now.
  dict->SetValue(kResetPageData, lepus::Value(reset_page_data));

  // Indicate that this reloadTemplate operation was initiated by the JS API
  // lynx.reload().
  dict->SetValue(kReloadFromJS, lepus::Value(reload_from_js));

  // Refresh the card and component's lifecycle like a new loaded template.
  // Used only in ReloadTemplate by now.
  dict->SetValue(kReloadTemplate, lepus::Value(reload_template));

  return lepus::Value(dict);
}

using base::PerfCollector;

const lepus::Value PageProxy::GetComponentContextDataByKey(
    const std::string &id, const std::string &key) {
  // TODO: Radon support.
  if (radon_page_) {
    //    return radon_page_->GetComponentContextDataByKey(id, key);
  }
  return lepus::Value();
}

bool PageProxy::UpdateConfig(const lepus::Value &config, lepus::Value &out,
                             bool to_refresh) {
  if (!config.IsObject()) {
    LOGE("config not table");
    return false;
  }
  auto configSrc = config.Table();
  if (configSrc->size() == 0) {
    out = lepus_value(false);
    return true;
  }

  if (!config_.IsObject()) {
    config_ = lynx::lepus::Value(lynx::lepus::Dictionary::Create());
  }

  // Config value should be deep cloned If Config is already const.
  if (config_.IsTable() && config_.Table()->IsConst()) {
    config_ = lynx::lepus::Value::Clone(config_);
  }
  for (const auto &[key, value] : *configSrc) {
    config_.SetProperty(key, value);
  }

  auto cfgToJs = lynx::lepus::Dictionary::Create();
  cfgToJs->SetValue(CARD_CONFIG_STR, lynx::lepus::Value(config_));

  if (radon_page_) {
    if (themed_.hasTransConfig) {
      UpdateThemedTransMapsBeforePageUpdated();
    }
    radon_page_->UpdateConfig(config, to_refresh);
  }
  out = lepus_value(cfgToJs);
  return true;
}

std::unique_ptr<lepus::Value> PageProxy::GetData() {
  if (radon_page_) {
    return radon_page_->GetPageData();
  }
  return nullptr;
}

lepus::Value PageProxy::GetDataByKey(const std::vector<std::string> &keys) {
  if (radon_page_) {
    return radon_page_->GetPageDataByKey(keys);
  }
  return lepus::Value();
}

void PageProxy::UpdateThemedTransMapsBeforePageUpdated() {
  int tid = 0;
  auto &mapRef = themed_.currentTransMap;
  mapRef = nullptr;
  themed_.hasAnyCurRes = themed_.hasAnyFallback = false;

  if (radon_page_) {
    tid = radon_page_->tid();
  }

  auto it = themed_.pageTransMaps.find(tid);
  if (it == themed_.pageTransMaps.end() || it->second == nullptr) {
    return;
  }

  mapRef = it->second;
  auto mapSize = mapRef->size();
  for (unsigned int i = 0; i < mapSize; ++i) {
    auto &transMap = mapRef->at(i);
    transMap.currentRes_ = nullptr;
    transMap.curFallbackRes_ = nullptr;
  }

  for (unsigned int i = 0; i < mapSize; ++i) {
    auto &transMap = mapRef->at(i);

    if (config_.IsTable()) {
      auto theme = config_.Table()->GetValue(CARD_CONFIG_THEME);
      if (theme.IsTable()) {
        for (const auto &item : *theme.Table()) {
          if (transMap.name_ != item.first.c_str()) {
            continue;
          }
          if (item.second.IsString() && item.second.String()) {
            auto it = transMap.resMap_.find(item.second.String()->c_str());
            if (it != transMap.resMap_.end()) {
              transMap.currentRes_ = it->second;
              themed_.hasAnyCurRes = true;
              break;
            }
          }
        }
      }
    }

    if (transMap.currentRes_ == nullptr && !transMap.default_.empty()) {
      auto it = transMap.resMap_.find(transMap.default_);
      if (it != transMap.resMap_.end()) {
        transMap.currentRes_ = it->second;
        themed_.hasAnyCurRes = true;
      }
    }

    if (transMap.curFallbackRes_ == nullptr && !transMap.fallback_.empty()) {
      auto it = transMap.resMap_.find(transMap.fallback_);
      if (it != transMap.resMap_.end()) {
        transMap.curFallbackRes_ = it->second;
        themed_.hasAnyFallback = true;
      }
    }
  }
}

// used in ReloadTemplate, call old components' unmount lifecycle.
void PageProxy::RemoveOldComponentBeforeReload() {
  if (!radon_page_) {
    return;
  }
  for (auto &child : radon_page_->radon_children_) {
    child->OnComponentRemovedInPostOrder();
  }
}

bool PageProxy::UpdateGlobalProps(const lepus::Value &table,
                                  bool should_render) {
  if (radon_page_) {
    global_props_ = table;
    return radon_page_->RefreshWithGlobalProps(table, should_render);
  }
#if ENABLE_AIR
  else if (element_manager()->AirRoot()) {
    return element_manager()->AirRoot()->RefreshWithGlobalProps(table,
                                                                should_render);
  }
#endif
  return false;
}

lepus::Value PageProxy::GetGlobalPropsFromTasm() const { return global_props_; }

void PageProxy::SetInvalidated(bool invalidated) {
  if (radon_page_ != nullptr) {
    radon_page_->SetInvalidated(true);
  }
}

void PageProxy::UpdateComponentData(const std::string &id,
                                    const lepus::Value &table) {
  if (radon_page_) {
    radon_page_->UpdateComponentData(id, table);
  }
}

std::vector<std::string> PageProxy::SelectComponent(
    const std::string &comp_id, const std::string &id_selector,
    const bool single) const {
  std::vector<std::string> result;
  NodeSelectOptions options(NodeSelectOptions::IdentifierType::CSS_SELECTOR,
                            id_selector);
  options.first_only = single;
  options.only_current_component = false;
  options.component_only = true;

  if (radon_page_) {
    auto unary_op = [](RadonBase *base) {
      return std::to_string(static_cast<RadonComponent *>(base)->ComponentId());
    };
    RadonComponent *component = radon_page_->GetComponent(comp_id);
    if (component == nullptr) {
      return result;
    }
    auto components = RadonNodeSelector::Select(component, options).nodes;
    std::transform(components.begin(), components.end(),
                   std::back_inserter(result), unary_op);
  } else if (client_ && client_->GetEnableFiberArch()) {
    auto unary_op = [](FiberElement *base) {
      return static_cast<ComponentElement *>(base)->component_id().str();
    };
    FiberElement *component =
        static_cast<FiberElement *>(element_manager()->GetComponent(comp_id));
    if (component == nullptr) {
      return result;
    }
    auto components = FiberElementSelector::Select(component, options).nodes;
    std::transform(components.begin(), components.end(),
                   std::back_inserter(result), unary_op);
  }
  return result;
}

std::vector<Element *> PageProxy::SelectElements(
    const NodeSelectRoot &root, const NodeSelectOptions &options) const {
  std::vector<Element *> targets;
  if (radon_page_) {
    auto unary_op = [](RadonBase *base) {
      return base->IsRadonComponent()
                 ? static_cast<RadonComponent *>(base)->TopLevelViewElement()
                 : base->element();
    };

    auto bases =
        RadonNodeSelector::Select(radon_page_.get(), root, options).nodes;
    std::transform(bases.begin(), bases.end(), std::back_inserter(targets),
                   unary_op);
  } else if (client_ && client_->GetEnableFiberArch()) {
    auto unary_op = [](FiberElement *base) {
      return static_cast<Element *>(base);
    };
    auto elements =
        FiberElementSelector::Select(element_manager(), root, options).nodes;
    std::transform(elements.begin(), elements.end(),
                   std::back_inserter(targets), unary_op);
  }
  return targets;
}

/*
 * Returns: vector of id of selected elements. returns empty when no node found.
 *
 * Args:
 * component_id: id of parent component given by user which we should search
 *               inside.
 * selector: selector or ref id. Currently ID, Class, ElementType and Descendant
 *           selectors are supported.
 * by_ref_id: if selector parameter is a ref id.
 * first_only: only return the first node satisfying the selector given.
 */
LynxGetUIResult PageProxy::GetLynxUI(const NodeSelectRoot &root,
                                     const NodeSelectOptions &options) const {
  if (radon_page_) {
    auto select_result =
        RadonNodeSelector::Select(radon_page_.get(), root, options);
    return select_result.PackageLynxGetUIResult();
  } else if (client_ && client_->GetEnableFiberArch()) {
    auto select_result =
        FiberElementSelector::Select(element_manager(), root, options);
    return select_result.PackageLynxGetUIResult();
  }
  return LynxGetUIResult({}, LynxGetUIResult::NODE_NOT_FOUND,
                         options.NodeIdentifierMessage());
}

void PageProxy::UpdateInLoadTemplate(lepus::Value &data) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "UpdateInLoadTemplate");
  if (Page()) {
    /*
     * Mock DIFF_ROOT_CREATE event in radon page here to ensure
     * that PerfCollector gets enough events to pass threshold
     * and call OnFirstLoadPerfReady.
     */
    Page()->CreatePage();
    UpdatePageOption update_page_option;
    update_page_option.update_first_time = true;
    Page()->UpdatePage(data, update_page_option);
  } else {
    LOGE("LoadTemplate UpdateData page is null");
  }
}

void PageProxy::ForceUpdate() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "ForceUpdate");
  lepus::Value data = lepus::Value(lepus::Dictionary::Create());
  UpdateInLoadTemplate(data);
}

void PageProxy::TraverseEmptyComponentsInOrder(
    const std::vector<uint32_t> &uid_list,
    base::MoveOnlyClosure<bool, uint32_t, EmptyComponentMap::iterator &> func) {
  // Traverse empty_component_map_ in order of uid_list and execute the
  // function. The return type of func is bool, decide whether to break early
  std::for_each(uid_list.begin(), uid_list.end(),
                [this, func = std::move(func)](const uint32_t uid) {
                  for (auto iter = empty_component_map_.begin();
                       iter != empty_component_map_.end(); ++iter) {
                    if (func(uid, iter)) {
                      break;
                    }
                  }
                });
}

void PageProxy::ForceUpdateInLoadDynamicComponent(
    const std::string &url, TemplateAssembler *tasm,
    const std::vector<uint32_t> &uid_list) {
  if (HasRadonPage()) {
    bool need_dispatch = false;
    TraverseEmptyComponentsInOrder(
        uid_list, [this, &url, tasm, &need_dispatch](auto uid, auto &iter) {
          auto *component = iter->second;
          if (component && component->LoadDynamicComponent(url, tasm, uid)) {
            empty_component_map_.erase(iter);
            need_dispatch = true;
            return true;
          }
          return false;
        });
    if (need_dispatch) {
      element_manager()->OnPatchFinishInner(PipelineOptions{});
    }
  }
}

void PageProxy::OnFailInLoadDynamicComponent(
    const std::vector<uint32_t> &uid_list, std::vector<int> &impl_ids) {
  if (HasRadonPage()) {
    bool need_dispatch = false;
    TraverseEmptyComponentsInOrder(
        uid_list, [&impl_ids, &need_dispatch](auto uid, auto &iter) {
          if (iter->second->Uid() == uid) {
            impl_ids.emplace_back(iter->second->ImplId());
            // try to render fallback if failed
            need_dispatch = iter->second->RenderFallback() || need_dispatch;
            return true;
          }
          return false;
        });
    if (need_dispatch) {
      element_manager()->OnPatchFinishInner(PipelineOptions{});
    }
  }
}

PageProxy::PageProxy(std::unique_ptr<ElementManager> client_ptr,
                     PageDelegate *delegate)
    : delegate_(delegate), client_(std::move(client_ptr)) {}

void PageProxy::SetRadonPage(RadonPage *page) {
  ResetComponentId();
  radon_page_.reset(page);
  if (themed_.hasTransConfig) {
    UpdateThemedTransMapsBeforePageUpdated();
  }
  if (radon_page_) {
    radon_page_->UpdateConfig(config_, false);
  }
}

void PageProxy::ResetComponentId() { component_id_generator_ = 1; }

uint32_t PageProxy::GetNextComponentID() { return component_id_generator_++; }

BaseComponent *PageProxy::ComponentWithId(int component_id) {
  auto iter = component_map_.find(component_id);
  if (iter == component_map_.end()) {
    return nullptr;
  }
  return iter->second;
}

Element *PageProxy::ComponentElementWithStrId(const std::string &id) {
  return element_manager()->GetComponent(id);
}

void PageProxy::UpdateComponentInComponentMap(RadonComponent *component) {
  AdoptComponent(component);
}

void PageProxy::SetCSSVariables(const std::string &component_id,
                                const std::string &id_selector,
                                const lepus::Value &properties) {
  if (Page()) {
    Page()->SetCSSVariables(component_id, id_selector, properties);
  } else if (client_ && client_->GetEnableFiberArch()) {
    NodeSelectRoot root = NodeSelectRoot::ByComponentId(component_id);
    NodeSelectOptions options(NodeSelectOptions::IdentifierType::CSS_SELECTOR,
                              id_selector);
    options.only_current_component = false;
    auto result =
        FiberElementSelector::Select(element_manager(), root, options);
    if (result.Success()) {
      FiberElement *node = result.GetOneNode();
      node->UpdateCSSVariable(properties);
    }
  }
}

PageProxy::~PageProxy() {
  destroyed_ = true;
  radon_page_.reset(nullptr);
}

bool PageProxy::UpdateGlobalDataInternal(
    const lepus_value &value, const UpdatePageOption &update_page_option) {
  if (Page()) {
    return Page()->UpdatePage(value, update_page_option);
  }
#if ENABLE_AIR
  else if (element_manager()->AirRoot()) {
    return element_manager()->AirRoot()->UpdatePageData(value,
                                                        update_page_option);
  }
#endif
  return false;
}

void PageProxy::OnComponentPropertyChanged(BaseComponent *node) {
  if (NeedSendTTComponentLifecycle(node) && delegate_ != nullptr) {
    delegate_->OnComponentPropertiesChanged(node->ComponentStrId(),
                                            node->properties());
  }
}

void PageProxy::OnComponentDataSetChanged(BaseComponent *node,
                                          const lepus::Value &data_set) {
  if (NeedSendTTComponentLifecycle(node) && delegate_ != nullptr) {
    delegate_->OnComponentDataSetChanged(node->ComponentStrId(), data_set);
  }
}

void PageProxy::OnComponentSelectorChanged(BaseComponent *node,
                                           const lepus::Value &instance) {
  if (NeedSendTTComponentLifecycle(node) && delegate_ != nullptr) {
    delegate_->OnComponentSelectorChanged(node->ComponentStrId(), instance);
  }
}

void PageProxy::OnComponentAdded(BaseComponent *node) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ON_COMPONENT_ADD);
  AdoptComponent(node);

  lepus::Value data = ProcessInitDataForJS(node->data());
  if (IsReact()) {
    if (delegate_ != nullptr) {
      lepus::Value props = ProcessReactPropsForJS(node->properties());
      auto *comp = node->GetParentComponent();
      if (comp) {
        OnReactComponentCreated(node, props, data, comp->ComponentStrId());
      }
    }
    return;
  }

  FireComponentLifecycleEvent(BaseComponent::kCreated, node, data);
  OnComponentPropertyChanged(node);
  if (radon_page_) {
    RadonComponent *component = static_cast<RadonComponent *>(node);
    component->OnDataSetChanged();
    component->OnSelectorChanged();
  }
  if (!GetComponentLifecycleAlignWithWebview()) {
    FireComponentLifecycleEvent(BaseComponent::kAttached, node);
    FireComponentLifecycleEvent(BaseComponent::kReady, node);
  }
}

void PageProxy::OnComponentRemoved(BaseComponent *node) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ON_COMPONENT_REMOVE);
  if (destroyed_) {
    return;
  }
  if (!node->IsEmpty() && !CheckComponentExists(node->ComponentId())) {
    return;
  }

  // Erase component from component_map_/empty_component_map_, if failed,
  // return.
  if (!EraseComponent(node)) {
    return;
  }

  if (IsReact()) {
    OnReactComponentUnmount(node);
    return;
  }
  FireComponentLifecycleEvent(BaseComponent::kDetached, node);
}

void PageProxy::OnComponentMoved(BaseComponent *node) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ON_COMPONENT_MOVE);
  if (!CheckComponentExists(node->ComponentId())) {
    LOGF("component doesn't exist in OnComponentMoved");
    return;
  }
  if (NeedSendTTComponentLifecycle(node)) {
    FireComponentLifecycleEvent(BaseComponent::kMoved, node);
  }
}

void PageProxy::OnReactComponentCreated(BaseComponent *component,
                                        const lepus::Value &props,
                                        const lepus::Value &data,
                                        const std::string &parent_id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentCreated");
  if (!component->IsEmpty() && delegate_ != nullptr) {
    // Here we keep track of the number of js constructor running if it is in
    // hydration process for react lynx page.
    IncreaseJSRenderCounterForHydrating();

    // The update callback of js constructor will be forced even if there is
    // nothing to be updated, when a react lynx page is trying to find a timing
    // to hydrate itself. It has to know when the js constructors is done.
    delegate_->OnReactComponentCreated(
        component->GetEntryName(), component->path().str(),
        component->ComponentStrId(), props, data, parent_id, HasSSRRadonPage());
  }
}

void PageProxy::OnReactComponentRender(BaseComponent *component,
                                       const lepus::Value &props,
                                       const lepus::Value &data,
                                       bool should_component_update) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentRender");
  if (!component->IsEmpty() && delegate_ != nullptr) {
    delegate_->OnReactComponentRender(component->ComponentStrId(), props, data,
                                      should_component_update);
  }
}

void PageProxy::OnReactComponentDidUpdate(BaseComponent *component) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentDidUpdate");
  if (!component->IsEmpty() && delegate_ != nullptr) {
    delegate_->OnReactComponentDidUpdate(component->ComponentStrId());
  }
}

void PageProxy::OnReactComponentDidCatch(BaseComponent *component,
                                         const lepus::Value &error) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentDidCatch");
  if (!component->IsEmpty() && delegate_ != nullptr) {
    delegate_->OnReactComponentDidCatch(component->ComponentStrId(), error);
  }
}

void PageProxy::OnReactComponentUnmount(BaseComponent *component) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentUnmount");
  if (!component->IsEmpty() && delegate_ != nullptr) {
    delegate_->OnReactComponentUnmount(component->ComponentStrId());
  }
}

void PageProxy::OnReactCardRender(const lepus::Value &data,
                                  bool should_component_update) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactCardRender");
  if (delegate_) {
    // Here we keep track of the number of js constructor running if it is in
    // hydration process for react lynx page.
    IncreaseJSRenderCounterForHydrating();

    // The update callback of js constructor will be forced even if there is
    // nothing to be updated, when a react lynx page is trying to find a timing
    // to hydrate itself. It has to know when the js constructors is done.
    delegate_->OnReactCardRender(data, should_component_update,
                                 HasSSRRadonPage());
  }
}

void PageProxy::OnReactCardDidUpdate() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactCardDidUpdate");
  if (delegate_ != nullptr) {
    delegate_->OnReactCardDidUpdate();
  }
}

lepus::Value PageProxy::ProcessReactPropsForJS(
    const lepus::Value &props) const {
  lepus::Value ret = props;
  static const lepus::String kPropsId{"propsId"};
  const auto props_id = props.GetProperty(kPropsId);
  // in ReactLynx@1.0, we could not get propsId here in first screen
  // thus we should check if we have propsId or not
  // - If we got propsId, we could only pass propsId and a flag to JS thread
  //   JS thread will use a propsMap to get correct props
  //   for more details and how it works, see: #5778
  // - Otherwise, we just pass all props to JS thread
  if (GetEnableReactOnlyPropsId() && props_id.IsString()) {
    ret = lepus::Value(lepus::Dictionary::Create());
    static const lepus::String kOnlyPropsId{"$$onlyPropsId"};
    ret.SetProperty(kPropsId, props_id);
    ret.SetProperty(kOnlyPropsId, lepus::Value(true));
  }
  return ret;
}

lepus::Value PageProxy::ProcessInitDataForJS(const lepus::Value &data) {
  if (!client_->GetEnableReduceInitDataCopy()) {
    return data;
  }

  if (IsReact()) {
    return data;
  }

  // For ttml, only copy Object.keys(data) to JS thread
  auto array = lepus::CArray::Create();
  ForEachLepusValue(
      data, [&array](const lepus::Value &key, const lepus::Value &value) {
        if (value.IsNil() || value.IsUndefined()) {
          // ignore null and undefined
          return;
        }
        array->push_back(key);
      });
  return lepus::Value(array);
}

void PageProxy::FireComponentLifecycleEvent(const std::string name,
                                            BaseComponent *component,
                                            const lepus::Value &data) {
  if (!component->IsEmpty() && delegate_ != nullptr) {
    std::string id = component->ComponentStrId();
    std::string entry_name = component->GetEntryName();
    std::string parent_id;
    if (name != BaseComponent::kDetached) {
      parent_id = GetParentComponentId(component);
    }
    delegate_->OnComponentActivity(name, id, parent_id, component->path().str(),
                                   entry_name, data);
  }
}

bool PageProxy::CheckComponentExists(int component_id) const {
  return component_map_.find(component_id) != component_map_.end();
}

std::string PageProxy::GetParentComponentId(BaseComponent *component) const {
  if (radon_page_) {
    RadonComponent *parent_component =
        static_cast<RadonComponent *>(component->GetParentComponent());
    if (!parent_component) {
      // in multi-layer slot, the parent_component may be nullptr
      LOGI("parent_component is nullptr in PageProxy::GetParentComponentId");
      return "";
    }
    if (parent_component->IsRadonComponent()) {
      return parent_component->ComponentStrId();
    } else if (parent_component->IsRadonPage()) {
      return PAGE_ID;
    } else {
      LOGF(
          "parent_component is not radon component or radon page in "
          "PageProxy::GetParentComponentId");
      return "";
    }
  }
  return "";
}

void PageProxy::AdoptComponent(BaseComponent *component) {
  if (!component) {
    LOGE("component is NULL in AdoptComponent" << this);
    return;
  }
  if (!component->ComponentId()) {
    LOGE("component's Id is not zero in AdoptComponent" << this);
    return;
  }
  // cast to RadonComponent
  RadonComponent *radon_component = static_cast<RadonComponent *>(component);

  if (radon_component->IsEmpty() &&
      radon_component->IsRadonDynamicComponent()) {
    // cast to RadonDynamicComponent
    auto *dynamic_component = static_cast<RadonDynamicComponent *>(component);
    // hold RadonDynamicComponent raw ptr
    empty_component_map_[component->ComponentId()] = dynamic_component;
    dynamic_component->OnComponentAdopted();
  } else if (!radon_component->IsEmpty()) {
    // hold RadonComponent raw ptr
    component_map_[radon_component->ComponentId()] = radon_component;
    // hold component's element raw ptr
    element_manager()->RecordComponent(radon_component->ComponentStrId(),
                                       radon_component->element());
  }
}

bool PageProxy::EraseComponent(BaseComponent *component) {
  if (!component) {
    LOGE("component is NULL in EraseComponent" << this);
    return false;
  }

  // cast to RadonComponent
  RadonComponent *radon_component = static_cast<RadonComponent *>(component);

  if (radon_component->IsEmpty() &&
      radon_component->IsRadonDynamicComponent()) {
    // cast to RadonDynamicComponent
    auto *dynamic_component =
        static_cast<RadonDynamicComponent *>(radon_component);

    // check if hold RadonDynamicComponent raw ptr
    auto iter = empty_component_map_.find(radon_component->ComponentId());
    if (iter != empty_component_map_.end() &&
        iter->second == dynamic_component) {
      empty_component_map_.erase(iter);
    } else {
      return false;
    }
  } else {
    // check if hold RadonComponent raw ptr
    auto iter = component_map_.find(component->ComponentId());
    if (iter != component_map_.end() && iter->second == radon_component) {
      component_map_.erase(iter);
      element_manager()->EraseComponentRecord(radon_component->ComponentStrId(),
                                              radon_component->element());
    } else {
      return false;
    }
  }

  return true;
}

bool PageProxy::NeedSendTTComponentLifecycle(BaseComponent *node) const {
  if (IsReact() || node->IsEmpty()) {
    return false;
  }
  if (!CheckComponentExists(node->ComponentId())) {
    LOGI("component doesn't exist in PageProxy::NeedSendTTComponentLifecycle");
    return false;
  }
  return true;
}

bool PageProxy::IsReact() const {
  if (radon_page_ && radon_page_->IsReact()) {
    return true;
  }
  return false;
}

void PageProxy::SetTasmEnableLayoutOnly(bool enable_layout_only) {
  client_->SetEnableLayoutOnly(enable_layout_only);
}

lepus::Value PageProxy::GetPathInfo(const NodeSelectRoot &root,
                                    const NodeSelectOptions &options) {
  auto package_data = [](lepus::Value &&status, lepus::Value &&data) {
    auto result_dict = lepus::Dictionary::Create();
    result_dict->SetValue("status", status);
    result_dict->SetValue("data", data);
    return lepus::Value(result_dict);
  };

  LOGI("GetPathInfo by root: " << root.ToPrettyString()
                               << ", node: " << options.ToString());
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PageProxy::GetPathInfo",
              [&](lynx::perfetto::EventContext ctx) {
                std::string info = std::string("root: ")
                                       .append(root.ToPrettyString())
                                       .append(", node: ")
                                       .append(options.ToString());
                auto *debug = ctx.event()->add_debug_annotations();
                debug->set_name("Info");
                debug->set_string_value(info);
              });

  if (radon_page_) {
    auto result = RadonNodeSelector::Select(radon_page_.get(), root, options);
    auto ui_result = GetLynxUI(root, options);
    if (!ui_result.Success()) {
      return package_data(ui_result.StatusAsLepusValue(),
                          options.first_only
                              ? lepus::Value()
                              : lepus::Value(lepus::CArray::Create()));
    }

    lepus::Value path_result;
    if (!options.first_only) {
      auto result_array = lepus::CArray::Create();
      for (auto &node : result.nodes) {
        auto path = RadonPathInfo::PathToRoot(node);
        result_array->push_back(RadonPathInfo::GetNodesInfo(path));
      }
      path_result.SetArray(result_array);
    } else {
      auto path = RadonPathInfo::PathToRoot(result.GetOneNode());
      path_result = RadonPathInfo::GetNodesInfo(path);
    }

    return package_data(ui_result.StatusAsLepusValue(), std::move(path_result));
  } else if (client_ && client_->GetEnableFiberArch()) {
    auto result =
        FiberElementSelector::Select(element_manager(), root, options);
    auto ui_result = result.PackageLynxGetUIResult();
    if (!ui_result.Success()) {
      return package_data(ui_result.StatusAsLepusValue(),
                          options.first_only
                              ? lepus::Value()
                              : lepus::Value(lepus::CArray::Create()));
    }

    lepus::Value path_result;
    if (!options.first_only) {
      auto result_array = lepus::CArray::Create();
      for (auto &node : result.nodes) {
        auto path = FiberNodeInfo::PathToRoot(node);
        result_array->push_back(FiberNodeInfo::GetNodesInfo(
            path, {"tag", "id", "dataSet", "index", "class"}));
      }
      path_result.SetArray(result_array);
    } else {
      auto path = FiberNodeInfo::PathToRoot(result.GetOneNode());
      path_result = FiberNodeInfo::GetNodesInfo(
          path, {"tag", "id", "dataSet", "index", "class"});
    }

    return package_data(ui_result.StatusAsLepusValue(), std::move(path_result));
  }
  return package_data(LynxGetUIResult::UnknownError(
                          "PageProxy::GetPathInfo: radon page not found")
                          .StatusAsLepusValue(),
                      lepus::Value());
}

lepus::Value PageProxy::GetFields(const NodeSelectRoot &root,
                                  const tasm::NodeSelectOptions &options,
                                  const std::vector<std::string> &fields) {
  auto package_data = [](lepus::Value &&status, lepus::Value &&data) {
    auto result_dict = lepus::Dictionary::Create();
    result_dict->SetValue("status", status);
    result_dict->SetValue("data", data);
    return lepus::Value(result_dict);
  };

  LOGI("GetFields by root: " << root.ToPrettyString()
                             << ", node: " << options.ToString());
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PageProxy::GetFields",
              [&](lynx::perfetto::EventContext ctx) {
                std::string info = std::string("root: ")
                                       .append(root.ToPrettyString())
                                       .append(", node: ")
                                       .append(options.ToString());
                auto *debug = ctx.event()->add_debug_annotations();
                debug->set_name("Info");
                debug->set_string_value(info);
              });

  if (radon_page_) {
    auto result = RadonNodeSelector::Select(radon_page_.get(), root, options);
    auto ui_result = result.PackageLynxGetUIResult();
    if (!ui_result.Success()) {
      return package_data(ui_result.StatusAsLepusValue(),
                          options.first_only
                              ? lepus::Value()
                              : lepus::Value(lepus::CArray::Create()));
    }

    lepus::Value fields_result;
    if (!options.first_only) {
      auto result_array = lepus::CArray::Create();
      for (auto &node : result.nodes) {
        result_array->push_back(RadonPathInfo::GetNodeInfo(node, fields));
      }
      fields_result.SetArray(result_array);
    } else {
      fields_result = RadonPathInfo::GetNodeInfo(result.GetOneNode(), fields);
    }
    return package_data(ui_result.StatusAsLepusValue(),
                        std::move(fields_result));
  } else if (client_ && client_->GetEnableFiberArch()) {
    auto result =
        FiberElementSelector::Select(element_manager(), root, options);
    auto ui_result = result.PackageLynxGetUIResult();
    if (!ui_result.Success()) {
      return package_data(ui_result.StatusAsLepusValue(),
                          options.first_only
                              ? lepus::Value()
                              : lepus::Value(lepus::CArray::Create()));
    }

    lepus::Value fields_result;
    if (!options.first_only) {
      auto result_array = lepus::CArray::Create();
      for (auto &node : result.nodes) {
        result_array->push_back(FiberNodeInfo::GetNodeInfo(node, fields));
      }
      fields_result.SetArray(result_array);
    } else {
      fields_result = FiberNodeInfo::GetNodeInfo(result.GetOneNode(), fields);
    }
    return package_data(ui_result.StatusAsLepusValue(),
                        std::move(fields_result));
  }
  return package_data(LynxGetUIResult::UnknownError(
                          "PageProxy::GetPathInfo: radon page not found")
                          .StatusAsLepusValue(),
                      lepus::Value());
}

#ifdef ENABLE_TEST_DUMP
std::string PageProxy::DumpTree() {
  if (!radon_page_) {
    return std::string();
  }

  rapidjson::Document dumped_document;
  rapidjson::Value dumped_virtual_tree;
  if (radon_page_) {
    dumped_virtual_tree = radon_page_->DumpToJSON(dumped_document);
  }

  dumped_document.Swap(dumped_virtual_tree);
  rapidjson::StringBuffer buffer;
  rapidjson::PrettyWriter<rapidjson::StringBuffer> writer(buffer);
  dumped_document.Accept(writer);
  return buffer.GetString();
}
#endif

void PageProxy::OnScreenMetricsSet(float &width, float &height) {
  if (radon_page_) {
    radon_page_->OnScreenMetricsSet(width, height);
  }
}

void PageProxy::ExecuteScreenMetricsOverrideWhenTemplateIsLoaded() {
  if (radon_page_) {
    auto &client = element_manager();
    float width = client->GetLynxEnvConfig().ScreenWidth();
    float height = client->GetLynxEnvConfig().ScreenHeight();
    radon_page_->OnScreenMetricsSet(width, height);
    client->UpdateScreenMetrics(width, height);
  }
}

void PageProxy::OnReactComponentJSFirstScreenReady() {
  if (!IsReact()) {
    return;
  }
  if (HasSSRRadonPage()) {
    --hydrate_info_.components_pending_js_render_;
  }
  if (ReadyToHydrate()) {
    radon_page_->Hydrate();
  }
}

void PageProxy::HydrateOnFirstScreenIfPossible() {
  if (!IsReact() && HasSSRRadonPage() && HasRadonPage()) {
    radon_page_->Hydrate();
  }
}

void PageProxy::RenderToBinary(
    const base::MoveOnlyClosure<void, RadonNode *, tasm::TemplateAssembler *>
        &binarizer,
    tasm::TemplateAssembler *template_assembler) {
  binarizer(radon_page_.get(), template_assembler);
}

bool PageProxy::IsServerSideRendering() {
#if BUILD_SSR_SERVER_RUNTIME
  return true;
#else
  return false;
#endif
}

void PageProxy::RenderWithSSRData(const lepus::Value &ssr_out_value,
                                  const lepus::Value &injected_data,
                                  int32_t trace_id) {
  DispatchOption option(this);
  // Reset the status of hydration.
  hydrate_info_ = HydrateInfo();

  // All the information of the dom will be constructed by ssr re-constructor.
  ssr_radon_page_ =
      std::make_unique<RadonPage>(this, 1, nullptr, nullptr, nullptr, nullptr);

  default_page_data_ = ssr::RetrievePageData(ssr_out_value, injected_data);
  default_global_props_ = ssr::RetrieveGlobalProps(ssr_out_value);

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "SSR create dom");

  PerfCollector::GetInstance().StartRecord(
      trace_id, PerfCollector::Perf::SSR_GENERATE_DOM);

  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_CREATE_VDOM_START_SSR);

  ssr::ReconstructDom(ssr_out_value, this, ssr_radon_page_.get(),
                      injected_data);

  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_CREATE_VDOM_END_SSR);

  PerfCollector::GetInstance().EndRecord(trace_id,
                                         PerfCollector::Perf::SSR_GENERATE_DOM);
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

  // ssr radon page dispatch.
  DispatchOption dispatch_option(this);
  SetRadonDiff(true);
  dispatch_option.need_update_element_ = true;

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "SSR Dispatch");
  PerfCollector::GetInstance().StartRecord(trace_id,
                                           PerfCollector::Perf::SSR_DISPATCH);

  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_DISPATCH_START_SSR);

  element_manager()->painting_context()->MarkUIOperationQueueFlushTiming(
      tasm::TimingKey::SETUP_UI_OPERATION_FLUSH_START, "");

  ssr_radon_page_->Dispatch(dispatch_option);

  tasm::TimingCollector::Instance()->Mark(
      tasm::TimingKey::SETUP_DISPATCH_END_SSR);

  PerfCollector::GetInstance().EndRecord(trace_id,
                                         PerfCollector::Perf::SSR_DISPATCH);
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

  PipelineOptions pipeline_options;
  pipeline_options.is_first_screen = true;
  pipeline_options.has_patched = true;
  element_manager()->OnPatchFinishFromRadon(true, pipeline_options);
}

void PageProxy::UpdateInitDataForSSRServer(const lepus::Value &page_data,
                                           const lepus::Value &system_info) {
  default_page_data_ = page_data;
  if (HasRadonPage()) {
    radon_page_->UpdateSystemInfo(system_info);
  }
}

void PageProxy::DiffHydrationData(const lepus::Value &data) {
  if (HasSSRRadonPage()) {
    hydrate_info_.hydrate_data_identical_as_ssr_ =
        data.IsEqual(default_page_data_);
  }
}

void PageProxy::ResetSSRPage() { ssr_radon_page_.reset(); }

}  // namespace tasm
}  // namespace lynx
