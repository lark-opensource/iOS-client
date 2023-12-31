// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/radon/radon_diff_list_node2.h"

#include <string>
#include <unordered_set>
#include <utility>

#include "base/trace_event/trace_event.h"
#include "tasm/base/tasm_utils.h"
#include "tasm/diff_algorithm.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/list_reuse_pool.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_page.h"
#include "tasm/template_assembler.h"

namespace {
constexpr static const char kListDefaultItemKeyPrefix[] =
    "lynx-list-default-item-key";
static uint64_t kAnonymousItemCount = 0;
}  // namespace

namespace lynx {
namespace tasm {

RadonDiffListNode2::RadonDiffListNode2(lepus::Context* context,
                                       PageProxy* page_proxy,
                                       TemplateAssembler* tasm,
                                       uint32_t node_index)
    : RadonListBase(context, page_proxy, tasm, node_index),
      reuse_pool_{std::make_unique<ListReusePool>()} {
  platform_info_.new_arch_list_ = true;
}

bool RadonDiffListNode2::ShouldFlush(
    const std::unique_ptr<RadonBase>& old_radon_child,
    const DispatchOption& option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "RadonDiffListNode::ShouldFlush in Radon Compatible",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  if (!old_radon_child || old_radon_child->NodeType() != kRadonListNode) {
    return false;
  }
  auto* old = static_cast<RadonDiffListNode2*>(old_radon_child.get());

  auto& new_components = new_components_;
  auto& old_components = old->components_;

  // check if the list node itself needs flush.
  bool should_flush = RadonNode::ShouldFlush(old_radon_child, option);

  // move resources from the old component to the new one.
  reuse_pool_ = std::move(old->reuse_pool_);

  // filter illegal components, i.e. components whose name do not exist.
  // all illegal components are removed before the generation of the
  // platform_info thus they are treated as if they have never appended
  // themselves into the `components_`
  FilterComponents(new_components_, tasm_);
  platform_info_.Generate(new_components_);
  platform_info_.new_arch_list_ = true;
  platform_info_.diffable_list_result_ = true;

  // generate the `platform_info_.update_actions_` by diff'ing.
  bool list_updated =
      MyersDiff(old_components, new_components, option.ShouldForceUpdate());

  // if a item-key is removed and inserted again, reset list_need_remove flag,
  // so that it can be reused
  for (auto index : platform_info_.update_actions_.insertions_) {
    const auto& item_key = new_components[index].diff_key_.String();
    auto* component =
        reuse_pool_->GetComponentFromListKeyComponentMap(item_key);
    if (component != nullptr) {
      component->list_need_remove_ = false;
      component->list_need_remove_after_reused_ = false;
    }
  }

  // remove the JS components here, and mark the Native components as "need to
  // reset data", so that next time when the same component is inserted, it data
  // will be reset

  bool remove_component = page_proxy_->GetListRemoveComponent();

  for (auto index : platform_info_.update_actions_.removals_) {
    const auto& item_key = old_components[index].diff_key_.String();
    auto* component =
        reuse_pool_->GetComponentFromListKeyComponentMap(item_key);
    // We always save its JS counterpart, no matter whether it's plug or not.
    if (component) {
      component->OnComponentRemovedInPostOrder();
      component->need_reset_data_ = true;
      // remove outdated radon from reuse_pool
      if (remove_component) {
        reuse_pool_->Remove(item_key,
                            lepus::String{old_components[index].name_});
      }
    }
  }

  for (size_t i = 0; i < platform_info_.update_actions_.update_from_.size();
       i++) {
    auto from = platform_info_.update_actions_.update_from_[i];
    auto to = platform_info_.update_actions_.update_to_[i];
    TransmitDispatchOptionFromOldComponentToNewComponent(old_components[from],
                                                         new_components[to]);
  }

  components_ = std::move(new_components_);

  SetupListInfo(list_updated);

  return should_flush || list_updated;
}

void RadonDiffListNode2::TransmitDispatchOptionFromOldComponentToNewComponent(
    ListComponentInfo& old_component, ListComponentInfo& new_component) {
  new_component.list_component_dispatch_option_.global_properties_changed_ |=
      old_component.list_component_dispatch_option_.global_properties_changed_;

  new_component.list_component_dispatch_option_.css_variable_changed_ |=
      old_component.list_component_dispatch_option_.css_variable_changed_;

  new_component.list_component_dispatch_option_.force_diff_entire_tree_ |=
      old_component.list_component_dispatch_option_.force_diff_entire_tree_;

  new_component.list_component_dispatch_option_.use_new_component_data_ |=
      old_component.list_component_dispatch_option_.use_new_component_data_;

  new_component.list_component_dispatch_option_.refresh_lifecycle_ |=
      old_component.list_component_dispatch_option_.refresh_lifecycle_;
}

void RadonDiffListNode2::SetupListInfo(bool list_updated) {
  // assemble diff_result and current components, and dispatch them to platform
  // by updating props
  auto lepus_platform_result = lepus::Dictionary::Create();

  lepus_platform_result->SetValue(
      lepus::String("diffable"),
      lepus::Value(platform_info_.diffable_list_result_));

  lepus_platform_result->SetValue(lepus::String("newarch"),
                                  lepus::Value(platform_info_.new_arch_list_));

  auto lepus_view_types = lepus::CArray::Create();
  for (const auto& cur : platform_info_.components_) {
    lepus_view_types->push_back(lepus::Value(cur.c_str()));
  }
  lepus_platform_result->SetValue(lepus::String("viewTypes"),
                                  lepus::Value(lepus_view_types));

  auto lepus_full_spans = lepus::CArray::Create();
  for (auto cur : platform_info_.fullspan_) {
    lepus_full_spans->push_back((lepus::Value(static_cast<int32_t>(cur))));
  }
  lepus_platform_result->SetValue(lepus::String("fullspan"),
                                  lepus::Value(lepus_full_spans));

  auto lepus_item_keys = lepus::CArray::Create();
  for (const auto& cur : platform_info_.item_keys_) {
    lepus_item_keys->push_back(lepus::Value(cur.c_str()));
  }

  lepus_platform_result->SetValue(lepus::String("itemkeys"),
                                  lepus::Value(lepus_item_keys));

  auto lepus_stick_tops = lepus::CArray::Create();
  for (auto cur : platform_info_.stick_top_items_) {
    lepus_stick_tops->push_back(lepus::Value(static_cast<int32_t>(cur)));
  }
  lepus_platform_result->SetValue(lepus::String("stickyTop"),
                                  lepus::Value(lepus_stick_tops));

  auto lepus_stick_bottoms = lepus::CArray::Create();
  for (auto cur : platform_info_.stick_bottom_items_) {
    lepus_stick_bottoms->push_back(lepus::Value(static_cast<int32_t>(cur)));
  }
  lepus_platform_result->SetValue(lepus::String("stickyBottom"),
                                  lepus::Value(lepus_stick_bottoms));

  auto lepus_estimated_height = lepus::CArray::Create();
  for (auto cur : platform_info_.estimated_heights_) {
    lepus_estimated_height->push_back(lepus::Value(static_cast<int32_t>(cur)));
  }
  lepus_platform_result->SetValue(lepus::String("estimatedHeight"),
                                  lepus::Value(lepus_estimated_height));

  auto lepus_estimated_height_px = lepus::CArray::Create();
  for (auto cur : platform_info_.estimated_heights_px) {
    lepus_estimated_height_px->push_back(
        lepus::Value(static_cast<int32_t>(cur)));
  }
  lepus_platform_result->SetValue(lepus::String("estimatedHeightPx"),
                                  lepus::Value(lepus_estimated_height_px));

  if (list_updated) {
    auto lepus_diff_insertions = lepus::CArray::Create();
    for (const auto& cur : platform_info_.update_actions_.insertions_) {
      lepus_diff_insertions->push_back(lepus::Value(cur));
    }

    auto lepus_diff_removals_ = lepus::CArray::Create();
    for (const auto& cur : platform_info_.update_actions_.removals_) {
      lepus_diff_removals_->push_back(lepus::Value(cur));
    }

    auto lepus_diff_update_from = lepus::CArray::Create();
    for (const auto& cur : platform_info_.update_actions_.update_from_) {
      lepus_diff_update_from->push_back(lepus::Value(cur));
    }

    auto lepus_diff_update_to = lepus::CArray::Create();
    for (const auto& cur : platform_info_.update_actions_.update_to_) {
      lepus_diff_update_to->push_back(lepus::Value(cur));
    }

    auto lepus_diff_move_from = lepus::CArray::Create();
    for (const auto& cur : platform_info_.update_actions_.move_from_) {
      lepus_diff_move_from->push_back(lepus::Value(cur));
    }

    auto lepus_diff_move_to = lepus::CArray::Create();
    for (const auto& cur : platform_info_.update_actions_.move_to_) {
      lepus_diff_move_to->push_back(lepus::Value(cur));
    }

    auto lepus_diff_result = lepus::Dictionary::Create();

    lepus_diff_result->SetValue(lepus::String("insertions"),
                                lepus::Value(lepus_diff_insertions));
    lepus_diff_result->SetValue(lepus::String("removals"),
                                lepus::Value(lepus_diff_removals_));
    lepus_diff_result->SetValue(lepus::String("updateFrom"),
                                lepus::Value(lepus_diff_update_from));
    lepus_diff_result->SetValue(lepus::String("updateTo"),
                                lepus::Value(lepus_diff_update_to));
    lepus_diff_result->SetValue(lepus::String("moveFrom"),
                                lepus::Value(lepus_diff_move_from));
    lepus_diff_result->SetValue(lepus::String("moveTo"),
                                lepus::Value(lepus_diff_move_to));

    lepus_platform_result->SetValue(lepus::String("diffResult"),
                                    lepus::Value(lepus_diff_result));
  } else {
    lepus_platform_result->SetValue(lepus::String("diffResult"),
                                    lepus::Value(lepus::Dictionary::Create()));
  }

  page_proxy_->element_manager()->OnUpdateAttr(
      element(), lepus::String("list-platform-info"),
      lepus::Value(lepus_platform_result));
}

void RadonDiffListNode2::RadonDiffChildren(
    const std::unique_ptr<RadonBase>& old_radon_child,
    const DispatchOption& option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "RadonDiffListNode::RadonDiffChildren in Radon Compatible",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  if (!old_radon_child || old_radon_child->NodeType() != kRadonListNode) {
    return;
  }

  auto* old = static_cast<RadonDiffListNode2*>(old_radon_child.get());
  for (auto& child : old->radon_children_) {
    auto* component = static_cast<RadonComponent*>(child.get());
    // only add useful component
    if (!component->list_need_remove_) {
      AddChild(std::move(child));
    }
  }
  NeedModifySubTreeComponent(component());
  TransmitDispatchOptionFromListNodeToListComponent(option);
}

void RadonDiffListNode2::TransmitDispatchOptionFromListNodeToListComponent(
    const DispatchOption& option) {
  if (option.css_variable_changed_) {
    for (auto& comp : components_) {
      comp.list_component_dispatch_option_.css_variable_changed_ = true;
    }
  }
  if (option.global_properties_changed_) {
    for (auto& comp : components_) {
      comp.list_component_dispatch_option_.global_properties_changed_ = true;
    }
  }
  if (option.force_diff_entire_tree_) {
    for (auto& comp : components_) {
      comp.list_component_dispatch_option_.force_diff_entire_tree_ = true;
    }
  }
  if (option.use_new_component_data_) {
    for (auto& comp : components_) {
      comp.list_component_dispatch_option_.use_new_component_data_ = true;
    }
  }
  if (option.refresh_lifecycle_) {
    for (auto& comp : components_) {
      comp.list_component_dispatch_option_.refresh_lifecycle_ = true;
    }
  }
}

void RadonDiffListNode2::DispatchFirstTime() {
  platform_info_.diffable_list_result_ = false;
  bool list_updated = DiffListComponents();
  SetupListInfo(list_updated);
  RadonNode::DispatchFirstTime();
}

int32_t RadonDiffListNode2::ComponentAtIndex(uint32_t index,
                                             int64_t operationId,
                                             bool enable_reuse_notification) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonDiffListNode2::ComponentAtIndex");
  if (index >= components_.size()) {
    LOGE("index out of range in RadonDiffListNode2::ComponentAtIndex.");
    return 0;
  }
  // try to get reuse_identifier and item_key.
  ListComponentInfo& component_info = components_[index];
  const auto& reuse_identifier = lepus::String{component_info.name_};
  const auto& item_key = component_info.diff_key_.String();
  bool component_is_newly_created{false};
  auto* component = reuse_pool_->GetComponentFromListKeyComponentMap(item_key);

  if (!component) {
    // the component need to be created.
    component = CreateComponentWithType(index);
    RadonListBase::SyncComponentExtraInfo(component, index, operationId);
    reuse_pool_->InsertIntoListKeyComponentMap(
        component_info.diff_key_.String(), component);
    component_is_newly_created = true;
  }

  if (!component) {
    LOGE("Component is nullptr in ComponentAtIndex of list new arch.");
    return 0;
  }

  auto reuse_action =
      reuse_pool_->Dequeue(item_key, reuse_identifier, component);
  if (reuse_action.type_ == ListReusePool::Action::Type::UPDATE) {
    LOGI("UPDATE key: " << item_key->c_str() << " , index: " << index);
    SyncComponentExtraInfo(component, index, operationId);
  } else {
    RadonListBase::SyncComponentExtraInfo(component, index, operationId);
    bool ignore_component_lifecycle = false;
    // Check whether the component is newly created.
    if (component_is_newly_created) {
      // use component info's data and property to render new component.
      // After render, the component tree structure should be complete and
      // determined.
      UpdateAndRenderNewComponent(component, component_info.properties_,
                                  component_info.data_);
      // if the component is new created, should call component's lifecycle
      // later.
      ignore_component_lifecycle = false;
    } else {
      component->ResetElementRecursively();
      // diff old component with component info, but not handle element.
      // After diff, the component tree structure should be complete and
      // determined.
      UpdateOldComponent(component, component_info);
      // if the component has been updated, shouldn't call component's lifecycle
      // later.
      ignore_component_lifecycle = true;
    }

    DispatchOption dispatch_option(page_proxy_);
    dispatch_option.ignore_component_lifecycle_ = ignore_component_lifecycle;
    switch (reuse_action.type_) {
      case ListReusePool::Action::Type::CREATE: {
        LOGI("CREATE key: " << item_key->c_str() << " , index: " << index);
        component->ResetElementRecursively();
        component->Dispatch(dispatch_option);
        break;
      }
      case ListReusePool::Action::Type::REUSE: {
        const auto& from_item_key = reuse_action.key_to_reuse_;
        LOGI("REUSE from key: " << from_item_key.c_str() << " to key: "
                                << item_key->c_str() << " , index: " << index);
        auto* reuse =
            reuse_pool_->GetComponentFromListKeyComponentMap(from_item_key);
        if (!reuse) {
          LOGE("REUSE component doesn't exist, key is: "
               << from_item_key.c_str());
          break;
        }

        if (component->ComponentId() == 0) {
          component->GenerateAndSetComponentId();
        }

        auto* reuser = component;
        dispatch_option.only_swap_element_ = true;
        std::unique_ptr<RadonBase> fake_unique_reuse{reuse};

        if (enable_reuse_notification) {
          // reuser will reuse the element from fake_unique_reuse,
          // pass through the element's impl_id and reuser's item_key to
          // platform, so that the Native UI can be notified that it will be
          // reused
          auto* element = fake_unique_reuse->element();
          if (element) {
            page_proxy_->element_manager()
                ->painting_context()
                ->ListReusePaintingNode(element->impl_id(), item_key);
          }
        }

        reuser->SwapElement(fake_unique_reuse, dispatch_option);
        reuser->RadonDiffChildren(fake_unique_reuse, dispatch_option);
        // Should reset the  whole element structure
        reuse->ResetElementRecursively();
        fake_unique_reuse.release();

        // remove outdated component after being reused
        if (reuse->list_need_remove_after_reused_) {
          // remove from reuse_pool
          reuse_pool_->Remove(from_item_key, reuse_identifier);
          // remove from parent
          auto* parent = reuse->Parent();
          if (parent != nullptr) {
            // dtor its radon subtree in post order
            reuse->ClearChildrenRecursivelyInPostOrder();
            // remove it from its parent
            parent->RemoveChild(reuse);
          }
        }
        break;
      }
      default: {
        break;
      }
    }
  }
  component->SetListItemKey(item_key);
  PipelineOptions pipeline_options;
  pipeline_options.operation_id = operationId;
  pipeline_options.list_comp_id = component->element()->impl_id();
  page_proxy_->element_manager()->OnPatchFinishInner(pipeline_options);
  page_proxy_->element_manager()->painting_context()->FlushImmediately();
  component_info.list_component_dispatch_option_.reset();
  return component->element()->impl_id();
}

void RadonDiffListNode2::EnqueueComponent(int32_t sign) {
  // EnqueueComponent is a public API which might be called without care
  // Rigorous checks must be done to avoid crash.

  if (!tasm_ || !tasm_->page_proxy() ||
      !tasm_->page_proxy()->element_manager() ||
      !tasm_->page_proxy()->element_manager()->node_manager()) {
    return;
  }
  auto* element =
      tasm_->page_proxy()->element_manager()->node_manager()->Get(sign);
  if (!element) {
    return;
  }
  auto* component = static_cast<RadonComponent*>(element->data_model());
  if (!component) {
    return;
  }

  LOGI("EnqueueComponent component, component name: "
       << component->name().c_str()
       << ", component item_key_: " << component->GetListItemKey().c_str());

  reuse_pool_->Enqueue(component->GetListItemKey(), component->name());
}

// helper function; It's essentially a wrapper of UpdateRadonComponent().
void UpdateRadonComponentWithInitialData(RadonComponent* comp,
                                         const lepus::Value& props,
                                         DispatchOption& option) {
  option.need_create_js_counterpart_ = true;
  option.use_new_component_data_ = true;
  option.refresh_lifecycle_ = true;
  comp->UpdateRadonComponent(BaseComponent::RenderType::UpdateByNativeList,
                             props, comp->GetInitialData(), option);
}

void RadonDiffListNode2::SyncComponentExtraInfo(RadonComponent* comp,
                                                uint32_t index,
                                                int64_t operation_id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonDiffListNode2::SyncComponentExtraInfo",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  std::unique_ptr<RadonComponent> original_component_node;
  PtrLookupMap lookup_map;
  original_component_node = std::make_unique<RadonComponent>(*comp, lookup_map);
  RadonListBase::SyncComponentExtraInfo(comp, index, operation_id);
  auto* comp_info = &components_.at(index);
  const lepus::Value& props = comp_info->properties_;
  DispatchOption dispatch_option(page_proxy_);

  dispatch_option.css_variable_changed_ =
      comp_info->list_component_dispatch_option_.css_variable_changed_;
  dispatch_option.global_properties_changed_ =
      comp_info->list_component_dispatch_option_.global_properties_changed_;
  dispatch_option.force_diff_entire_tree_ =
      comp_info->list_component_dispatch_option_.force_diff_entire_tree_;
  dispatch_option.use_new_component_data_ =
      comp_info->list_component_dispatch_option_.use_new_component_data_;
  dispatch_option.refresh_lifecycle_ =
      comp_info->list_component_dispatch_option_.refresh_lifecycle_;
  bool should_flush =
      comp->ShouldFlush(std::move(original_component_node), dispatch_option);
  if (should_flush) {
    comp->element()->FlushProps();
  }
  if (comp->need_reset_data_) {
    UpdateRadonComponentWithInitialData(comp, props, dispatch_option);
    comp->need_reset_data_ = false;
    return;
  }
  comp->UpdateRadonComponent(BaseComponent::RenderType::UpdateByNativeList,
                             props, comp_info->data_, dispatch_option);
}

void RadonDiffListNode2::UpdateAndRenderNewComponent(
    RadonComponent* component, const lepus::Value& incoming_property,
    const lepus::Value& incoming_data) {
  auto config = tasm_->page_proxy()->GetConfig();
  component->UpdateSystemInfo(GenerateSystemInfo(&config));
  component->UpdateRadonComponentWithoutDispatch(
      BaseComponent::RenderType::FirstRender, incoming_property, incoming_data);
  RenderOption render_option;
  render_option.recursively = true;
  component->RenderRadonComponentIfNeeded(render_option);
}

void RadonDiffListNode2::UpdateOldComponent(RadonComponent* component,
                                            ListComponentInfo& component_info) {
  DispatchOption dispatch_update_option(page_proxy_);
  dispatch_update_option.need_update_element_ = false;
  dispatch_update_option.global_properties_changed_ =
      component_info.list_component_dispatch_option_.global_properties_changed_;
  component_info.list_component_dispatch_option_.global_properties_changed_ =
      false;
  if (component->need_reset_data_) {
    UpdateRadonComponentWithInitialData(component, component_info.properties_,
                                        dispatch_update_option);
    component->need_reset_data_ = false;
    return;
  }
  component->UpdateRadonComponent(BaseComponent::RenderType::UpdateByNativeList,
                                  component_info.properties_,
                                  component_info.data_, dispatch_update_option);
}

void RadonDiffListNode2::CheckItemKeys(
    std::vector<ListComponentInfo>& components) {
  std::unordered_set<lepus::String> cache;

  for (auto& curr : components) {
    bool use_default_item_key = false;

    // check if the item-key is a string and has been specified for the current
    // component
    if (!(curr.diff_key_.IsString() && !curr.diff_key_.String()->empty())) {
      use_default_item_key = true;
    }
    // check if another component shares a same item-key with the current
    // component
    if (!cache.insert(curr.diff_key_.String()).second) {
      use_default_item_key = true;
    }

    if (use_default_item_key) {
      kAnonymousItemCount++;
      curr.diff_key_ = lepus::Value((std::string(kListDefaultItemKeyPrefix) +
                                     std::to_string(kAnonymousItemCount))
                                        .c_str());
    }
  }
}

void RadonDiffListNode2::FilterComponents(
    std::vector<ListComponentInfo>& components, TemplateAssembler* tasm) {
  ListNode::FilterComponents(components, tasm);
  CheckItemKeys(components);
}
}  // namespace tasm
}  // namespace lynx
