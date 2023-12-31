// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/radon/radon_list_base.h"

#include <base/string/string_utils.h>

#include <memory>
#include <utility>

#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/array.h"
#include "tasm/base/tasm_utils.h"
#include "tasm/component_attributes.h"
#include "tasm/diff_algorithm.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_dynamic_component.h"
#include "tasm/radon/radon_page.h"
#include "tasm/recorder/recorder_controller.h"
#include "tasm/template_assembler.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace tasm {

void RadonListBase::AppendComponentInfo(ListComponentInfo& info) {
  new_components_.push_back(std::move(info));
}

RadonListBase::RadonListBase(const RadonListBase& node, PtrLookupMap& map)
    : RadonNode{node, map}, context_{node.context_}, tasm_{node.tasm_} {}

// TODO: 1. check component name valid.  2. read diffable attribute.
RadonListBase::RadonListBase(lepus::Context* context, PageProxy* page_proxy,
                             TemplateAssembler* tasm, uint32_t node_index)
    : RadonNode{page_proxy, kListNodeTag, node_index},
      context_{context},
      tasm_{tasm} {
  RadonNode::node_type_ = kRadonListNode;
  if (page_proxy) {
    platform_info_.enable_move_operation_ =
        page_proxy->GetListEnableMoveOperation();
    platform_info_.enable_plug_ = page_proxy->GetListEnablePlug();
  }
}

RadonComponent* RadonListBase::CreateComponentWithType(uint32_t index) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "List::CreateComponentWithType",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  const auto& component_info = components_.at(index);
  const auto lepus_component_name = lepus::String{component_info.name_};
  lepus::Dictionary* map = component()->component_info_map().Table().Get();

  RadonComponent* result = nullptr;
  if (component()->GetComponentType(component_info.name_) !=
      BaseComponent::ComponentType::kStatic) {
    // dynamic component
    auto current_entry = component_info.current_entry_;
    const auto& url = tasm_->GetTargetUrl(current_entry, component_info.name_);
    // for dynamic components in list, tid is 0 and index is 0;
    RadonDynamicComponent* dynamic_component =
        RadonDynamicComponent::CreateRadonDynamicComponent(
            tasm_, url, component_info.name_, 0, 0);
    result = static_cast<RadonComponent*>(dynamic_component);
  } else {
    // static component
    const lepus::Value& info = map->find(lepus_component_name)->second;
    const lepus::Value& path = component()
                                   ->component_path_map()
                                   .Table()
                                   .Get()
                                   ->find(lepus_component_name)
                                   ->second;

    // DCHECK(info.Array().Get()->size() == 2);
    const auto tid = static_cast<int>(info.Array().Get()->get(0).Number());

    const auto& name = component()->GetEntryName().empty()
                           ? DEFAULT_ENTRY_NAME
                           : component()->GetEntryName();
    ComponentMould* cm = tasm_->component_moulds(name).find(tid)->second.get();
    auto* page_proxy = tasm_->page_proxy();
    result = new RadonListComponent{page_proxy,
                                    tid,
                                    nullptr,
                                    tasm_->style_sheet_manager(name),
                                    cm,
                                    context_,
                                    kRadonInvalidNodeIndex,
                                    component_info.distance_from_root_};
    result->SetPath(path.String());
    if (tasm_->GetPageConfig()->GetDSL() == PackageInstanceDSL::REACT) {
      result->SetDSL(PackageInstanceDSL::REACT);
      // set "getDerivedStateFromProps" function for react component
      result->SetGetDerivedStateFromPropsProcessor(
          tasm_->GetComponentProcessorWithName(result->path().c_str(),
                                               REACT_PRE_PROCESS_LIFECYCLE,
                                               context_->name()));
      // set "getDerivedStateFromError" function for react component
      result->SetGetDerivedStateFromErrorProcessor(
          tasm_->GetComponentProcessorWithName(result->path().c_str(),
                                               REACT_ERROR_PROCESS_LIFECYCLE,
                                               context_->name()));
      result->SetShouldComponentUpdateProcessor(
          tasm_->GetComponentProcessorWithName(result->path().c_str(),
                                               REACT_SHOULD_COMPONENT_UPDATE,
                                               context_->name()));
    }
    result->SetName(lepus_component_name);
  }
  result->SetDynamicAttribute(lepus::String("flatten"),
                              lepus_value(lepus::StringImpl::Create("false")));
  AddChild(std::unique_ptr<RadonBase>{result});
  return result;
}

void RadonListBase::SyncComponentExtraInfo(RadonComponent* comp, uint32_t index,
                                           int64_t operation_id) {
  auto* comp_info = &components_.at(index);
  const lepus::Value& props = comp_info->properties_;
  DCHECK(props.IsObject());
  lepus::Value type = lepus::Value(static_cast<uint32_t>(comp_info->type_));
  comp->SetStaticAttribute(ListComponentInfo::kListCompType, type);

  comp->SetClass(comp_info->clazz_.String());
  comp->SetIdSelector(comp_info->ids_.String());
  ForEachLepusValue(
      props, [comp](const lepus::Value& key, const lepus::Value& val) {
        if (ComponentAttributes::GetAttrNames().end() !=
            ComponentAttributes::GetAttrNames().find(key.String()->str())) {
          comp->UpdateDynamicAttribute(key.String(), val);
        }
      });
  auto splits = base::SplitStringByCharsOrderly(
      comp_info->style_.String()->str(), {':', ';'});
  auto& parser_configs = tasm_->GetPageConfig()->GetCSSParserConfigs();
  for (size_t i = 0; i + 1 < splits.size(); i = i + 2) {
    std::string key = base::TrimString(splits[i]);
    std::string value = base::TrimString(splits[i + 1]);

    CSSPropertyID id = CSSProperty::GetPropertyID(key);
    if (CSSProperty::IsPropertyValid(id) && value.length() > 0) {
      if (page_proxy_->IsRadonDiff()) {
        comp->SetInlineStyle(id, value, parser_configs);
      } else {
        auto css_values = UnitHandler::Process(
            id, lepus::Value(lepus::StringImpl::Create(value)), parser_configs);
        for (auto& pair : css_values) {
          comp->UpdateInlineStyle(pair.first, pair.second);
        }
      }
    }
  }
  if (comp_info->event_.IsArrayOrJSArray()) {
    ForEachLepusValue(
        comp_info->event_, [comp](const auto& key, const auto& value) {
          if (value.Contains("script")) {
            comp->SetLepusEvent(value.GetProperty("type").String(),
                                value.GetProperty("name").String(),
                                value.GetProperty("script"),
                                value.GetProperty("value"));
          } else {
            comp->SetStaticEvent(value.GetProperty("type").String(),
                                 value.GetProperty("name").String(),
                                 value.GetProperty("value").String());
          }
        });
  }

  if (comp_info->dataset_.IsObject()) {
    ForEachLepusValue(comp_info->dataset_, [&comp](const lepus::Value& key,
                                                   const lepus::Value& value) {
      comp->SetDataSet(key.String(), value);
    });
  }
  comp->SetDSL(tasm_->GetPageDSL());
  lepus::String item_key{"item-key"};
  if (props.Contains(item_key)) {
    comp->UpdateDynamicAttribute(item_key, props.GetProperty(item_key));
  }

  if (platform_info_.enable_plug_) {
    static_cast<RadonListComponent*>(comp)->distance_from_root_ =
        comp_info->distance_from_root_;
  }
}

void RadonListBase::RenderComponentAtIndex(uint32_t index,
                                           int64_t operation_id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "List::RenderComponent",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
#if ENABLE_ARK_RECORDER
  recorder::ListNodeRecorder::RecordRenderComponentAtIndex(
      index, operation_id, element()->impl_id(), GetRootElement()->impl_id(),
      tasm_->GetRecordID());
#endif
  DCHECK(index < platform_info_.components_.size());
  auto* comp = CreateComponentWithType(index);
  if (comp != nullptr) {
    auto config = tasm_->page_proxy()->GetConfig();
    comp->UpdateSystemInfo(GenerateSystemInfo(&config));
    SyncComponentExtraInfo(comp, index, operation_id);
  }
  // FIXME(heshan):invoke RenderComponentAtIndex in LynxEngine
  tasm_->page_proxy()
      ->element_manager()
      ->painting_context()
      ->FlushImmediately();
}

RadonComponent* RadonListBase::GetComponent(uint32_t sign) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "List::GetComponent",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  auto& patching = tasm_->page_proxy()->element_manager();
  auto* node = patching->node_manager()->Get(sign);
  if (node == nullptr) {
    return nullptr;
  }
  auto* comp = static_cast<RadonComponent*>(node->data_model());
  return comp;
}

// this is only called when the platform list is __DEALLOCATED__
// thus we do not need to care
// @param sign is the sign of the __LynxListTableViewCell__
// use GetParam could get the associated RadonComponent
void RadonListBase::RemoveComponent(uint32_t sign) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "List::RemoveComponent",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
#if ENABLE_ARK_RECORDER
  recorder::ListNodeRecorder::RecordRemoveComponent(sign, element()->impl_id(),
                                                    GetRootElement()->impl_id(),
                                                    tasm_->GetRecordID());
#endif
  auto* comp = GetComponent(sign);
  if (comp == nullptr) {
    return;
  }
  // remove its element
  comp->RemoveElementFromParent();
  // dtor its radon subtree in post order
  comp->ClearChildrenRecursivelyInPostOrder();
  // notify its element is removed
  comp->OnElementRemoved(0);
  // remove it from its parent
  auto unique_comp_ptr = this->RemoveChild(comp);
  // comp deleted here

  // FIXME(heshan):invoke RemoveComponent in LynxEngine
  tasm_->page_proxy()
      ->element_manager()
      ->painting_context()
      ->FlushImmediately();
}

void RadonListBase::UpdateComponent(uint32_t sign, uint32_t row,
                                    int64_t operation_id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "List::UpdateComponent",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
#if ENABLE_ARK_RECORDER
  recorder::ListNodeRecorder::RecordUpdateComponent(
      sign, row, operation_id, element()->impl_id(),
      GetRootElement()->impl_id(), tasm_->GetRecordID());
#endif
  DCHECK(row < platform_info_.components_.size());
  if (row < 0 || row >= components_.size()) {
    LOGE("row out of range in RadonListBase::UpdateComponent.");
    return;
  }
  auto* comp = GetComponent(sign);
  if (!comp) {
    LOGE("comp is nullptr in RadonListBase::UpdateComponent.");
    return;
  }
  SyncComponentExtraInfo(comp, row, operation_id);

  // FIXME(heshan):invoke UpdateComponent in LynxEngine
  tasm_->page_proxy()
      ->element_manager()
      ->painting_context()
      ->FlushImmediately();
}

void RadonListBase::DispatchFirstTime() {
  platform_info_.diffable_list_result_ = false;
  RadonNode::DispatchFirstTime();
}

bool RadonListBase::HasComponent(const std::string& component_name,
                                 const std::string& current_entry) {
  const auto& type = component()->GetComponentType(component_name);
  // static component
  if (type == BaseComponent::ComponentType::kStatic) {
    return true;
  } else {
    // component is not a static component
    // should component exist, it must be a dynamic component, current_entry is
    // required to check its existence.
    const auto& url = tasm_->GetTargetUrl(current_entry, component_name);
    auto entry = tasm_->FindTemplateEntry(url);
    if (!entry) {
      return true;
    }
    auto cm_it = entry->dynamic_component_moulds().find(0);
    if (cm_it == entry->dynamic_component_moulds().end()) {
      return false;
    }
    auto& cm = cm_it->second;
    if (!cm || cm->path().empty()) {
      return false;
    }
    return true;
  }
}

bool RadonListBase::DiffListComponents() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "List::DiffListComponents",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  FilterComponents(new_components_, tasm_);
  bool is_updating_config = page_proxy_->isUpdatingConfig();
  platform_info_.update_actions_ = myers_diff::MyersDiff(
      false, components_.begin(), components_.end(), new_components_.begin(),
      new_components_.end(),
      [](const ListComponentInfo& lhs, const ListComponentInfo& rhs) {
        return lhs.CanBeReusedBy(rhs);
      },
      [is_updating_config](const ListComponentInfo& lhs,
                           const ListComponentInfo& rhs) {
        return !is_updating_config && (lhs == rhs);
      });

  auto need_flush = !platform_info_.update_actions_.Empty();

  if (need_flush) {
    components_ = std::move(new_components_);
    platform_info_.Generate(components_);
  } else {
    platform_info_.update_actions_.Clear();
    new_components_.clear();
  }
  return need_flush;
}

}  // namespace tasm
}  // namespace lynx
