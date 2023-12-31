// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/radon/radon_component.h"

#include <utility>

#include "base/lynx_env.h"
#include "base/string/string_utils.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/context.h"
#include "tasm/base/base_def.h"
#include "tasm/base/tasm_utils.h"
#include "tasm/component_config.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/radon/node_selector.h"
#include "tasm/radon/radon_page.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace tasm {

RadonComponent::RadonComponent(
    PageProxy* page_proxy, int tid, CSSFragment* style_sheet,
    std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
    ComponentMould* mould, lepus::Context* context, uint32_t node_index,
    const lepus::String& tag_name)
    : RadonNode(page_proxy, tag_name, node_index),
      BaseComponent(mould, context, style_sheet, style_sheet_manager, tid) {
  node_type_ = kRadonComponent;
  UpdateLepusTopLevelVariableToData();
  SetRenderType(RenderType::FirstRender);
  SetComponent(this);
  if (page_proxy && page_proxy_->IsRadonDiff()) {
    radon_slots_helper_ = std::make_unique<RadonSlotsHelper>(this);
    compile_render_ = page_proxy_->element_manager()->GetCompileRender();
  }
}

RadonComponent::RadonComponent(const RadonComponent& node, PtrLookupMap& map)
    : RadonNode(node, map),
      BaseComponent(node.mould_, node.context_, node.intrinsic_style_sheet_,
                    node.style_sheet_manager_, node.tid_) {
  entry_name_ = node.entry_name_;
  name_ = node.name_;
  path_ = node.path_;
  style_sheet_ = node.style_sheet_;  // TODO: Move to Base.
  UpdateSystemInfo(GenerateSystemInfo(nullptr));
  SetRenderType(node.render_type_);
  SetComponent(this);
  dsl_ = node.dsl_;
  if (!page_proxy_->GetEnableGlobalComponentMap()) {
    for (auto iter : *node.component_info_map().Table()) {
      component_info_map_.Table()->SetValue(iter.first, iter.second);
    }
    for (auto iter : *node.component_path_map().Table()) {
      component_path_map_.Table()->SetValue(iter.first, iter.second);
    }
  }
  get_derived_state_from_props_function_ =
      node.get_derived_state_from_props_function_;

  get_derived_state_from_error_function_ =
      node.get_derived_state_from_error_function_;

  ForEachLepusValue(node.properties_, [this](const lepus::Value& key,
                                             const lepus::Value& value) {
    this->SetProperties(key.String(), value,
                        static_cast<AttributeHolder*>(this), false);
  });

  ForEachLepusValue(node.data_,
                    [this](const lepus::Value& key, const lepus::Value& value) {
                      this->SetData(key.String(), value);
                    });
  SetGlobalPropsFromTasm();
  if (page_proxy_->IsRadonDiff()) {
    radon_slots_helper_ = std::make_unique<RadonSlotsHelper>(this);
  }
  for (auto& plug : node.plugs_) {
    auto plug_name = plug.first;
    auto* plug_ptr = plug.second.get();
    auto* copied_plug_ptr =
        radon_factory::CopyRadonDiffSubTree(*static_cast<RadonBase*>(plug_ptr));
    AddRadonPlug(plug_name, std::unique_ptr<RadonBase>(copied_plug_ptr));
  }
}

RadonComponent::~RadonComponent() { OnElementRemoved(0); }

void RadonComponent::UpdateLepusTopLevelVariableToData() {
  UpdateSystemInfo(GenerateSystemInfo(nullptr));
  SetGlobalPropsFromTasm();
}

// for remove element
int RadonComponent::ImplId() const {
  RadonElement* element = TopLevelViewElement();
  if (!element) {
    return kInvalidImplId;
  }
  return element->impl_id();
}

void RadonComponent::OnComponentRemovedInPostOrder() {
  RadonBase::OnComponentRemovedInPostOrder();
  OnElementRemoved(0);
}

void RadonComponent::SetComponent(RadonComponent* component) {
  radon_component_ = component;
  for (auto& child : radon_children_) {
    child->SetComponent(this);
  }
}

bool RadonComponent::SetRemoveComponentElement(const lepus::String& key,
                                               const lepus::Value& value) {
  if (key.IsEqual(kRemoveComponentElement) && value.IsBool()) {
    if (value.Bool()) {
      remove_component_element_ = BooleanProp::TrueValue;
    } else {
      remove_component_element_ = BooleanProp::FalseValue;
    }
    return true;
  }
  return false;
}

bool RadonComponent::SetSpecialComponentAttribute(const lepus::String& key,
                                                  const lepus::Value& value) {
  if (SetRemoveComponentElement(key, value)) {
    return true;
  } else if (SetLynxKey(key, value)) {
    // SetLynxKey function only store value in radon_base
    // set lynx-key attribute then component is consistent with other nodes
    SetDynamicAttribute(key, value);
    return true;
  } else {
    return false;
  }
}

void RadonComponent::AddChild(std::unique_ptr<RadonBase> child) {
  AddChildWithoutSetComponent(std::move(child));
  // need to set component to this after child is added
  radon_children_.back()->SetComponent(this);
}

void RadonComponent::AddSubTree(std::unique_ptr<RadonBase> child) {
  AddChild(std::move(child));
  for (auto& plug : plugs_) {
    AddRadonPlug(plug.first, std::move(plug.second));
  }
  radon_children_.back()->NeedModifySubTreeComponent(this);
}

int RadonComponent::ComponentId() { return component_id_; }

bool RadonComponent::IsPropertiesUndefined(const lepus::Value& value) const {
  // methods to check properties undefined.
  // it's result will differ according to pageConfig `enableComponentNullProps`
  // if enableComponentNullProps on, it depends on whether value isEmpty, else
  // it depends on whether value inUndefined
  if (page_proxy_->GetEnableComponentNullProp()) {
    return value.IsUndefined();
  } else {
    // compatible for sdk 2.8 and before versions.
    // in before versions, we only block Undefined type and Value_Nil
    return value.IsUndefined() || value.Type() == lepus::Value_Nil;
  }
}

void RadonComponent::SetGlobalPropsFromTasm() {
  if (page_proxy_) {
    auto global_props = page_proxy_->GetGlobalPropsFromTasm();
    UpdateGlobalProps(global_props);
  }
}

bool RadonComponent::ShouldBlockEmptyProperty() {
  // For some previous reason, RadonDiff does not allow Empty Property
  // So we Block Empty property for RadonDiff, but Allow Empty property
  // for Actual Radon.
  if (!page_proxy_->IsRadonDiff()) {
    return false;
  }

  if (IsInList()) {
    // This is a bit tricky.
    // For history reason: Block empty props in list only when targetSDKVersion
    // higher than 2.1
    if (page_proxy_->element_manager()->GetIsTargetSdkVerionHigherThan21()) {
      return true;
    }
    return false;
  }
  // normal component that not in list, should block empty props
  // unconditionally.
  return true;
}

bool RadonComponent::UpdateRadonComponentWithoutDispatch(
    RenderType render_type, lepus::Value incoming_property,
    lepus::Value incoming_data) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "RadonComponent::UpdateRadonComponentWithoutDispatch",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  RenderType ori_render_type = render_type;
  if (!dispatched_) {
    render_type = RenderType::FirstRender;
  }
  SetRenderType(render_type);
  if (NeedSavePreState(render_type)) {
    if (incoming_property.IsObject()) {
      set_pre_properties(lepus::Value::ShallowCopy(properties_));
    } else {
      set_pre_properties(properties_);
    }
    if (incoming_data.IsObject()) {
      set_pre_data(lepus::Value::ShallowCopy(data_));
    } else {
      set_pre_data(data_);
    }
  }

  if (IsReact() && render_type == RenderType::UpdateFromJSBySelf) {
    if (CheckReactShouldAbortUpdating(incoming_data)) {
      return false;
    }
    if (CheckReactShouldComponentUpdateKey(incoming_data)) {
      return false;
    }
  }

  if (incoming_data.IsObject() && incoming_data.GetLength() > 0) {
    if ((data_.IsObject() && CheckTableShadowUpdated(data_, incoming_data)) ||
        data_.IsNil()) {
      UpdateTable(data_, incoming_data);
      data_dirty_ = true;
    }
  }

  if (incoming_property.IsObject() && incoming_property.GetLength() > 0) {
    if ((properties_.IsObject() &&
         CheckTableShadowUpdated(properties_, incoming_property)) ||
        properties_.IsNil()) {
      properties_dirty_ = true;
      ForEachLepusValue(incoming_property, [this](const lepus::Value& key,
                                                  const lepus::Value& val) {
        this->SetProperties(key.String(), val,
                            static_cast<AttributeHolder*>(this),
                            page_proxy_->GetStrictPropType());
      });
    }
  }

  // shouldn't update when both of data and properties are not changed.
  if (!data_dirty_ && !properties_dirty_ &&
      render_type != RenderType::UpdateByRenderError) {
    EXEC_EXPR_FOR_INSPECTOR({
      if (lynx::base::LynxEnv::GetInstance().IsTableDeepCheckEnabled()) {
        page_proxy_->element_manager()->OnComponentUselessUpdate(name_.str(),
                                                                 properties_);
      }
    });
    return false;
  }
  if (ori_render_type == RenderType::UpdateByNativeList && properties_dirty_) {
    return PreRender(RenderType::UpdateByNativeList);
  }
  return PreRender(render_type);
}

void RadonComponent::UpdateRadonComponent(RenderType render_type,
                                          lepus::Value incoming_property,
                                          lepus::Value incoming_data,
                                          const DispatchOption& option) {
  LOGI("RadonComponent::UpdateRadonComponent, name: "
       << name_.c_str() << ", component id: " << ComponentId());
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonComponent::UpdateRadonComponent",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  SetRenderType(render_type);
  bool shouldUpdate = UpdateRadonComponentWithoutDispatch(
      render_type, incoming_property, incoming_data);

  bool forceUpdate =
      option.css_variable_changed_ || option.need_create_js_counterpart_ ||
      option.global_properties_changed_ || option.force_update_this_component ||
      option.force_diff_entire_tree_;

  if (shouldUpdate || forceUpdate) {
    Refresh(option);
  }
}

void RadonComponent::SetCSSVariables(const std::string& id_selector,
                                     const lepus::Value& properties) {
  set_variable_ops_.emplace_back(SetCSSVariableOp(id_selector, properties));
  DispatchOption dispatch_option(page_proxy_);
  dispatch_option.css_variable_changed_ = true;
  Refresh(dispatch_option);
  PipelineOptions pipeline_options;

  page_proxy_->element_manager()->OnPatchFinishFromRadon(
      dispatch_option.has_patched_, pipeline_options);
}

void RadonComponent::Refresh(const DispatchOption& option) {
  if (!page_proxy_->IsRadonDiff()) {
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_CREATE_VDOM_START);
    // Actual Radon Logic.
    UpdateComponentInLepus();
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_CREATE_VDOM_END);
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_DISPATCH_START);
    page_proxy_->element_manager()
        ->painting_context()
        ->MarkUIOperationQueueFlushTiming(
            tasm::TimingKey::UPDATE_UI_OPERATION_FLUSH_START,
            option.timing_flag_);
    Dispatch(option);
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_DISPATCH_END);
  } else {
    // Radon Compatible
    OnComponentUpdate(option);
    for (auto& slot : slots()) {
      slot.second->SetPlugCanBeMoved(true);
    }

    auto original_slots = slots_;
    // clear original slots
    radon_slots_helper_->RemoveAllSlots();
    // save original children
    auto original_radon_children = std::move(radon_children_);
    radon_children_.clear();
    RenderOption renderOption;
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_CREATE_VDOM_START);
    RenderRadonComponentIfNeeded(renderOption);
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_CREATE_VDOM_END);
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_DISPATCH_START);
    page_proxy_->element_manager()
        ->painting_context()
        ->MarkUIOperationQueueFlushTiming(
            tasm::TimingKey::UPDATE_UI_OPERATION_FLUSH_START,
            option.timing_flag_);
    RadonMyersDiff(original_radon_children, option);
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_DISPATCH_END);
    /*
     * In this UpdateRadonComponent case, plugs cannot be changed, but slots
     * may be changed. We've already saved original plugs and original slots,
     * we just need to refill the original plugs to new slots.
     */
    // TODO: brothers' lifecycle
    radon_slots_helper_->ReFillSlotsAfterChildrenDiff(original_slots, option);
    ResetDispatchedStatus();
    // if component is update in HMR mode, ignore lifecycle of current component
    if (option.component_update_by_hmr_) {
      return;
    }
    OnReactComponentDidUpdate(option);
  }
}

void RadonComponent::RefreshWithNewStyle(const DispatchOption& option) {
#if ENABLE_HMR
  if (page_proxy_->IsRadonDiff()) {
    // Radon Compatible
    LightDiffForStyle(radon_children_, option);
  }
#endif
}

void RadonComponent::PreHandlerCSSVariable() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonComponent::PreHandlerCSSVariable",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  if (set_variable_ops_.empty()) {
    return;
  }

  for (auto& temp : set_variable_ops_) {
    NodeSelectOptions options(NodeSelectOptions::IdentifierType::CSS_SELECTOR,
                              temp.GetIdSelector());
    options.only_current_component = false;
    auto result = RadonNodeSelector::Select(this, options);
    if (result.Success()) {
      RadonNode* node = result.GetOneNode();
      auto css_variable_kv = temp.GetProperties();
      if (css_variable_kv.IsObject()) {
        ForEachLepusValue(css_variable_kv, [node](const lepus::Value& key,
                                                  const lepus::Value& val) {
          node->UpdateCSSVariableFromSetProperty(key.String(), val.String());
        });
      }
    }
  }
}

void RadonComponent::CreateComponentInLepus() RADON_ONLY {
  if (page_proxy_->IsRadonDiff()) {
    return;
  }
  lepus::Value p1(this);
  lepus::Value p2(data_);
  lepus::Value p3(properties_);
  context_->Call("$createComponent" + std::to_string(tid_), {p1, p2, p3});
}

void RadonComponent::RenderRadonComponentIfNeeded(RenderOption& option)
    RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "RadonComponent::RenderRadonComponentIfNeeded",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  if (!page_proxy_->IsRadonDiff()) {
    return;
  }
  if (radon_children_.empty()) {
    RenderRadonComponent(option);
  }
}

void RadonComponent::RenderRadonComponent(RenderOption& option)
    RADON_DIFF_ONLY {
  if (context_) {
    lepus::Value p1(this);
    lepus::Value p2(data_);
    lepus::Value p3(properties_);
    context_->Call("$renderComponent" + std::to_string(tid_),
                   {p1, p2, p3, lepus::Value(option.recursively)});
    PreHandlerCSSVariable();
  }
}

void RadonComponent::UpdateComponentInLepus() RADON_ONLY {
  if (page_proxy_->IsRadonDiff()) {
    return;
  }
  lepus::Value p1(this);
  lepus::Value p2(data_);
  lepus::Value p3(properties_);
  context_->Call("$updateComponent" + std::to_string(tid_), {p1, p2, p3});
  update_function_called_ = true;
}

// 非首屏, native触发 updateData ( list 或者 parent component 修改 data)
void RadonComponent::OnReactComponentRenderBase(lepus::Value& new_data,
                                                bool should_component_update) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonComponent::OnReactComponentRenderBase",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  if (!IsReact()) {
    return;
  }

  RadonPage* page = root_node();
  if (!page) {
    return;
  }
  page_proxy_->OnReactComponentRender(
      this, page_proxy_->ProcessReactPropsForJS(properties_), new_data,
      should_component_update);
}

void RadonComponent::AdoptPlugToSlot(RadonSlot* slot,
                                     std::unique_ptr<RadonBase> plug) {
  RadonPlug* plug_to_reattach = static_cast<RadonPlug*>(plug.get());
  slot->AdoptPlug(std::move(plug));
  // re-attach plug's radon_component_ if needed
  if (plug_to_reattach->radon_component_ != radon_component_) {
    plug_to_reattach->SetAttachedComponent(this);
  }
}

void RadonComponent::AddRadonPlug(const lepus::String& name,
                                  std::unique_ptr<RadonBase> plug) {
  if (!plug) {
    return;
  }
  auto it = slots_.find(name);
  if (it != slots_.end()) {
    AdoptPlugToSlot(it->second, std::move(plug));
  } else {
    plugs_[name] = std::move(plug);
  }
}

void RadonComponent::RemovePlugByName(const lepus::String& name) {
  auto it = slots_.find(name);
  if (it != slots_.end()) {
    it->second->ReleasePlug();
  }
}

void RadonComponent::AddRadonSlot(const lepus::String& name, RadonSlot* slot) {
  slots_[name] = slot;
  slot->radon_component_ = this;
}

void RadonComponent::ResetElementRecursively() {
  // In the Radon diff list scenario, when two VDOM components are reused for
  // Diff, any addition or deletion of a node will not trigger the corresponding
  // Component Add/Remove lifecycle. Previously, we would execute
  // EraseComponentRecord in OnComponentRemoved, but in this situation,
  // EraseComponentRecord will not be executed, which causes a destructed object
  // to remain in the component map. This leads to crashes when it is
  // subsequently used. To solve this problem, we perform an operation in the
  // ResetElementRecursively. If this RadonNode is a RadonComponent and it holds
  // a RadonElement, it will delete the element from the component map when exec
  // ResetElementRecursively.
  if (element() != nullptr) {
    page_proxy_->element_manager()->EraseComponentRecord(ComponentStrId(),
                                                         element());
  }
  RadonNode::ResetElementRecursively();
}

void RadonComponent::OnElementRemoved(int idx) {
  if (IsRadonComponent() && page_proxy_) {
    page_proxy_->OnComponentRemoved(this);
  }
  dispatched_ = false;
}

void RadonComponent::OnElementMoved(int from_idx, int to_idx) {
  if (IsRadonComponent()) {
    page_proxy_->OnComponentMoved(this);
  }
}

void RadonComponent::DispatchChildren(const DispatchOption& option) {
  RadonBase::DispatchChildren(option);
  auto* root = static_cast<RadonPage*>(root_node());
  if (root) {
    root->CollectComponentDispatchOrder(this);
  }
}

void RadonComponent::DispatchChildrenForDiff(const DispatchOption& option) {
  RadonBase::DispatchChildrenForDiff(option);
  auto* root = static_cast<RadonPage*>(root_node());
  if (root) {
    root->CollectComponentDispatchOrder(this);
  }
}

void RadonComponent::DispatchSelf(const DispatchOption& option) {
  if (!page_proxy_->IsRadonDiff() && !update_function_called_) {
    UpdateComponentInLepus();
  }

  RadonNode::DispatchSelf(option);
}

void RadonComponent::Dispatch(const DispatchOption& option) {
  auto* root = static_cast<RadonPage*>(root_node());
  if (root == nullptr) {
    return;
  }
  // data and props are all clean.
  // No need to dispatch its children.
  bool should_update =
      data_dirty_ || properties_dirty_ || !option.class_transmit_.IsEmpty() ||
      option.css_variable_changed_ || option.global_properties_changed_ ||
      option.ssr_hydrating_;
  if (dispatched_ && !should_update) {
    DispatchSelf(option);
    return;
  }

  bool dispatched = dispatched_;
  if (!dispatched) {
    // Set component_id_ and then dispatch self
    if (component_id_ == 0) {
      component_id_ = page_proxy_->GetNextComponentID();
    }
  }
  DispatchSelf(option);
  OnComponentUpdate(option);
  RenderOption render_option;
  render_option.recursively = true;
  RenderRadonComponentIfNeeded(render_option);
  DispatchSubTree(option);
  ResetDispatchedStatus();
  OnReactComponentDidUpdate(option);
}

void RadonComponent::OnDataSetChanged() {
  RadonPage* page = root_node();
  if (page) {
    lepus::Value data = lepus::Value();
    data.SetTable(lepus::Dictionary::Create());
    for (auto& temp : data_set_) {
      data.Table()->SetValue(temp.first, temp.second);
    }
    page_proxy_->OnComponentDataSetChanged(this, data);
  }
}

void RadonComponent::OnSelectorChanged() {
  RadonPage* page = root_node();
  if (page) {
    lepus::Value data = lepus::Value();
    data.SetTable(lepus::Dictionary::Create());
    std::string class_array_string;
    for (size_t i = 0; i < classes_.size(); i++) {
      class_array_string.append(classes_[i].c_str());
      if (i < classes_.size() - 1) {
        class_array_string.append(" ");
      }
    }
    data.Table()->SetValue("className",
                           lepus::Value(class_array_string.c_str()));
    data.Table()->SetValue("id", lepus::Value(id_selector_.c_str()));
    page_proxy_->OnComponentSelectorChanged(this, data);
  }
}

void RadonComponent::DispatchForDiff(const DispatchOption& option)
    RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "RadonComponent::DispatchForDiff in Radon Compatible",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  auto* root = static_cast<RadonPage*>(root_node());
  if (root == nullptr) {
    return;
  }
  RenderOption render_option;
  render_option.recursively = true;
  RenderRadonComponentIfNeeded(render_option);
  // attach plugs
  radon_slots_helper_->FillUnattachedPlugs();

  // Set component_id_ and then dispatch self
  if (!component_id_) {
    component_id_ = page_proxy_->GetNextComponentID();
  }

  DispatchSelf(option);

  // update component lifecycle and then dispatch subtree
  OnComponentUpdate(option);

  DispatchChildrenForDiff(option);

  ResetDispatchedStatus();
  OnReactComponentDidUpdate(option);
}

BaseComponent* RadonComponent::GetParentComponent() {
  RadonBase* parent_node = Parent();
  while (parent_node != nullptr) {
    if (parent_node->IsRadonComponent() || parent_node->IsRadonPage()) {
      RadonComponent* parent_component =
          static_cast<RadonComponent*>(parent_node);
      return static_cast<BaseComponent*>(parent_component);
    }
    parent_node = parent_node->Parent();
  }

  return nullptr;
}

const lepus::Value& RadonComponent::component_info_map() const {
  if (page_proxy_->GetEnableGlobalComponentMap()) {
    return page_proxy_->component_info_map();
  }
  return component_info_map_;
}

const lepus::Value& RadonComponent::component_path_map() const {
  if (page_proxy_->GetEnableGlobalComponentMap()) {
    return page_proxy_->component_path_map();
  }
  return component_path_map_;
}

// Search for list in the ancestor chain and cache the result ever after.
bool RadonComponent::IsInList() {
  if (in_list_status_ != InListStatus::Unknown) {
    return in_list_status_ == InListStatus::InList;
  }
  auto* parent = Parent();
  while (parent) {
    if (parent->NodeType() == kRadonListNode) {
      in_list_status_ = InListStatus::InList;
      return true;
    }
    parent = parent->Parent();
  }
  in_list_status_ = InListStatus::NotInList;
  return false;
}

CSSFragment* RadonComponent::GetStyleSheet() {
  auto* fragment = GetStyleSheetBase(static_cast<AttributeHolder*>(this));
  OnStyleSheetReady(fragment);
  return fragment;
}

void RadonComponent::OnStyleSheetReady(CSSFragment* fragment) {
  if (!page_proxy_ || !page_proxy_->element_manager() || !fragment ||
      !fragment->HasTouchPseudoToken()) {
    return;
  }
  page_proxy_->element_manager()->UpdateTouchPseudoStatus(true);
}

void RadonComponent::OnComponentUpdate(const DispatchOption& option) {
  if ((!dispatched_ && page_proxy_->ComponentWithId(ComponentId())) ||
      option.ignore_component_lifecycle_) {
    page_proxy_->UpdateComponentInComponentMap(this);
  }
  if (option.ignore_component_lifecycle_) {
    return;
  }
  if (option.refresh_lifecycle_) {
    // refresh lifecycle should call OnComponentAdded lifecycle.
    page_proxy_->OnComponentAdded(this);
    return;
  }
  if (!dispatched_ && !page_proxy_->ComponentWithId(ComponentId())) {
    page_proxy_->OnComponentAdded(this);
  } else if (properties_dirty_) {
    if (!IsReact()) {
      page_proxy_->OnComponentPropertyChanged(this);
    }
  }
}

void RadonComponent::OnReactComponentDidUpdate(const DispatchOption& option) {
  if (IsReact() && !option.ignore_component_lifecycle_) {
    page_proxy_->OnReactComponentDidUpdate(this);
    if (!CheckReactShouldAbortRenderError(data_) && render_error_.IsObject() &&
        !render_error_.IsNil()) {
      auto catch_error = lepus::Dictionary::Create();
      catch_error->SetValue(
          "message",
          lepus::Value(render_error_.GetProperty("message").String()));
      catch_error->SetValue(
          "stack", lepus::Value(render_error_.GetProperty("stack").String()));
      catch_error->SetValue("name", lepus::Value(LEPUS_RENDER_ERROR));
      DispatchOption dispatch_option(page_proxy_);
      UpdateRadonComponent(BaseComponent::RenderType::UpdateByRenderError,
                           lepus::Value(), lepus::Value(), dispatch_option);
      page_proxy_->OnReactComponentDidCatch(this, lepus::Value(catch_error));
    }
  }
}

void RadonComponent::ResetDispatchedStatus() {
  this->properties_dirty_ = false;
  this->data_dirty_ = false;
  this->dispatched_ = true;
}

// for remove component element
bool RadonComponent::NeedsElement() const {
  if (radon_parent_ != nullptr && radon_parent_->NodeType() == kRadonListNode) {
    return true;
  }
  if (remove_component_element_ == BooleanProp::NotSet) {
    // use page_config's RemoveComponentElement config.
    // TODO: inject page proxy for config when doing ssr for react lynx
    return page_proxy_ == nullptr ||
           !page_proxy_->element_manager()->GetRemoveComponentElement();
  } else if (remove_component_element_ == BooleanProp::TrueValue) {
    return false;
  }
  return true;
}

bool RadonComponent::NeedsExtraData() const {
  // remove extra data and need extra data are the opposite
  switch (remove_extra_data_) {
    case BooleanProp::TrueValue:
      return false;
    case BooleanProp::FalseValue:
      return true;
    case BooleanProp::NotSet: {
      // use page_config's GetEnableRemoveComponentExtraData config.
      // TODO: inject page proxy for config when doing ssr for react lynx
      return page_proxy_ == nullptr ||
             !page_proxy_->GetEnableRemoveComponentExtraData();
    }
  }
}

void RadonComponent::WillRemoveNode() {
  if (will_remove_node_has_been_called_) {
    return;
  }
  will_remove_node_has_been_called_ = true;
  for (auto& plug : plugs_) {
    if (plug.second) {
      plug.second->WillRemoveNode();
    }
  }
  for (auto& node : radon_children_) {
    if (node) {
      node->WillRemoveNode();
    }
  }
}

void RadonComponent::ModifySubTreeComponent(RadonComponent* const target) {
  // iteratively set this and this's children's radon_component_ to target
  if (!target) {
    return;
  }
  radon_component_ = target;
  for (auto& slot : slots()) {
    slot.second->SetComponent(this);
    if (!slot.second->radon_children_.empty()) {
      // modify the plug's radon_component_
      slot.second->radon_children_.front()->ModifySubTreeComponent(target);
    }
  }
  if (compile_render_) {
    for (auto& plug : plugs_) {
      // modify the plug's radon_component_.
      // only need to handle in compile render.
      if (plug.second && plug.second->component() != target) {
        plug.second->ModifySubTreeComponent(target);
      }
    }
  }
  return;
}

// for remove component element
RadonElement* RadonComponent::TopLevelViewElement() const {
  if (!NeedsElement() && !IsRadonPage() && !radon_children_.empty()) {
    RadonBase* first_child = radon_children_[0].get();
    if (first_child->IsRadonComponent()) {
      return static_cast<RadonComponent*>(first_child)->TopLevelViewElement();
    }
    return first_child->element();
  }
  return element();
}

void RadonComponent::RadonDiffChildren RADON_DIFF_ONLY(
    const std::unique_ptr<RadonBase>& old_radon_child,
    const DispatchOption& option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "RadonComponent::RadonDiffChildren in Radon Compatible",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });

  if (option.ssr_hydrating_) {
    // Hydration is attaching current nodes to nodes rendered by server side.
    // For component, it only needs to be treated as a regular node.
    // Neither info update, nor component life cycle are executed during
    // hydration.
    radon_slots_helper_->FillUnattachedPlugs();
    RadonBase::RadonDiffChildren(old_radon_child, option);
    // Component map should still be updated when hydrating.
    page_proxy_->UpdateComponentInComponentMap(this);
    return;
  }

  auto old_radon_component =
      static_cast<RadonComponent*>(old_radon_child.get());

  if (old_radon_component == nullptr ||
      old_radon_component->NodeType() != NodeType()) {
    LOGE(
        "Radon compatible error: diff radon-component with "
        "non-radon-component.");
    return;
  }
  if (option.only_swap_element_) {
    RadonReusableDiffChildren(old_radon_component, option);
    return;
  }
  if (option.refresh_lifecycle_) {
    // TODO(wangqingyu): TT should also reset when support data version
    if (IsReact()) {
      // nativeStateVersion and jsStateVersion should be reset like a new
      // created component since JS counter part are newly created
      ResetDataVersions();
    }

    // component's component_id_ should be generated like a new created
    // component when refresh lifecycle
    component_id_ = page_proxy_->GetNextComponentID();
    if (NeedsElement() && element() && option.need_update_element_) {
      element()->FlushProps();
    }
  } else {
    // reuse old radon component's component_id_
    component_id_ = old_radon_component->ComponentId();
  }

  LOGV("RadonComponent::RadonDiffChildren in Radon Compatible, name: "
       << name_.c_str() << ", component id: " << component_id_);

  // update component in component-map
  page_proxy_->UpdateComponentInComponentMap(this);

  // if use_new_component_data_ is set true, shouldn't re-use old component's
  // data_, worklet_instances_ and inner_state_.
  if (!option.use_new_component_data_) {
    // reuse old component's data
    // data cannot be changed by the component's parent component, but
    // properties may be changed
    data_ = old_radon_component->data_;
    worklet_instances_ = old_radon_component->worklet_instances_;
    inner_state_ = old_radon_component->inner_state_;
  }

  dispatched_ = true;

  bool force_update_all = option.ShouldForceUpdate();

  // check the properties of the component
  bool should_update_properties =
      properties() != old_radon_component->properties();
  if (should_update_properties) {
    properties_dirty_ = true;
  }
  if (should_update_properties || option.refresh_lifecycle_) {
    OnComponentUpdate(option);
  }

  bool final_should_update = false;

  if (option.refresh_lifecycle_) {
    // If should refresh lifecycle, shouldn't call PreRender.
    final_should_update = true;
  } else if (should_update_properties || force_update_all) {
    SetRenderType(RenderType::UpdateByParentComponent);
    if (NeedSavePreState(render_type_)) {
      set_pre_properties(old_radon_component->properties());
      set_pre_data(data_);
    }
    final_should_update = PreRender(render_type_) || force_update_all;
  }

  if (final_should_update) {
    // need to re-render and continue diff the components' children

    // clear original slots
    radon_slots_helper_->RemoveAllSlots();
    RenderOption renderOption;
    RenderRadonComponentIfNeeded(renderOption);
    /*
     * attach new plugs
     * Q: Why need to clear original slots and then attach new plugs?
     * A: Because the plugs are created before and outside this new component.
     * The plugs are bound to this new component before the component
     * re-rendered, too. So after the new component finished re-rendering, we
     * need to re-attach these newly created plugs.
     */
    radon_slots_helper_->FillUnattachedPlugs();
    // destroy old plugs.
    // already has new plugs, the old plugs has been removed but not destroyed
    // need to guarantee to be destroyed here to avoid leak.
    for (auto& plug : old_radon_component->plugs_) {
      if (plug.second && plug.second->LastChild() &&
          plug.second->LastChild()->element()) {
        auto element = plug.second->LastChild()->element();
        element->DestroyNode(element);
      }
    }

    // continue diff the components' children
    RadonMyersDiff(old_radon_component->radon_children_, option);
    ResetDispatchedStatus();
    OnReactComponentDidUpdate(option);
    return;
  }

  // no need to re-render, just reuse everything from the old component, expect
  // plugs
  component_info_map_ = old_radon_component->component_info_map_;
  component_path_map_ = old_radon_component->component_path_map_;

  /*
   * Save original plugs to diff with new plugs.
   * Here although we reuse everything from the old component, we still need to
   * do diff on the plugs of the new and old component. Because the plugs depend
   * on outer component, but not this component.
   */
  NameToPlugMap original_plugs;
  radon_slots_helper_->MovePlugsFromSlots(original_plugs,
                                          old_radon_component->slots_);

  // reuse old slots
  for (auto& slot : old_radon_component->slots_) {
    AddRadonSlot(slot.first, slot.second);
  }
  // move children from old component to new component
  for (auto& child : old_radon_component->radon_children_) {
    AddChild(std::move(child));
  }
  old_radon_component->radon_children_.clear();
  // attach new plugs
  radon_slots_helper_->FillUnattachedPlugs();
  // diff old plug vs new plug
  radon_slots_helper_->DiffWithPlugs(original_plugs, option);
  // iteratively set children's radon_component_ to this
  for (auto& child : radon_children_) {
    child->NeedModifySubTreeComponent(this);
  }
  // issue: #5462
  // should not call OnReactComponentDidUpdate. remove it since 2.2.
  // leave it here in lower versions for compatibility.
  ResetDispatchedStatus();
  bool should_run_component_did_update =
      !page_proxy_->element_manager()->GetIsTargetSdkVerionHigherThan21();
  if (should_run_component_did_update) {
    OnReactComponentDidUpdate(option);
  }
}

void RadonComponent::RadonReusableDiffChildren(
    RadonComponent* old_radon_component,
    const DispatchOption& option) RADON_DIFF_ONLY {
  // OnComponentAdded lifecycle
  if (component_id_ == 0) {
    component_id_ = page_proxy_->GetNextComponentID();
  }
  // flush component to update the map of component_id -> view
  if (NeedsElement() && element()) {
    element()->FlushProps();
  }
  OnComponentUpdate(option);
  // continue diff the components' children
  RadonMyersDiff(old_radon_component->radon_children_, option);
  // OnReactComponentDidUpdate lifecycle
  ResetDispatchedStatus();
  OnReactComponentDidUpdate(option);
  return;
}

const std::string& RadonComponent::GetEntryName() const {
  if (entry_name_.empty() && radon_component_ != nullptr) {
    entry_name_ = radon_component_->GetEntryName();
  }
  return entry_name_;
}

bool RadonComponent::CanBeReusedBy(const RadonBase* const radon_base) const {
  if (!RadonBase::CanBeReusedBy(radon_base)) {
    return false;
  }
  // In this case, radon_base's node_type must by kRadonComponent
  // because node_type has been checked in RadonBase::CanBeReusedBy()
  const RadonComponent* const component =
      static_cast<const RadonComponent* const>(radon_base);
  return name().IsEqual(component->name()) &&
         remove_component_element_ == component->remove_component_element_;
}

void RadonComponent::GenerateAndSetComponentId() {
  component_id_ = page_proxy_->GetNextComponentID();
}

void RadonComponent::ClearStyleSheetAndVariables() {
#if ENABLE_HMR
  style_sheet_.reset();
  css_variables_.clear();
#endif
}

void RadonComponent::SetIntrinsicStyleSheet(
    CSSFragment* new_intrinsic_style_sheet) {
#if ENABLE_HMR
  intrinsic_style_sheet_ = new_intrinsic_style_sheet;
#endif
}

// Essentially a wrapper of RadonComponent.
RadonListComponent::RadonListComponent(
    PageProxy* page_proxy, int tid, CSSFragment* style_sheet,
    std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
    ComponentMould* mould, lepus::Context* context, uint32_t node_index,
    int distance_from_root, const lepus::String& tag_name)
    : RadonComponent(page_proxy, tid, style_sheet, style_sheet_manager, mould,
                     context, node_index, tag_name),
      distance_from_root_(distance_from_root) {}

// Change the radonListComponent's parentComponent to where it gets defined.
void RadonListComponent::SetComponent(RadonComponent* component) {
  RadonComponent* curr = component;
  for (int i = 0; curr && i < distance_from_root_; i++) {
    curr = curr->component();
  }
  RadonComponent::SetComponent(curr);
}

// Same as RadonListComponent::SetComponent().
void RadonListComponent::ModifySubTreeComponent(RadonComponent* const target) {
  if (!target) {
    return;
  }
  RadonComponent* curr = target;
  for (int i = 0; curr && i < distance_from_root_; i++) {
    curr = curr->component();
  }
  RadonComponent::ModifySubTreeComponent(curr);
}

}  // namespace tasm
}  // namespace lynx
