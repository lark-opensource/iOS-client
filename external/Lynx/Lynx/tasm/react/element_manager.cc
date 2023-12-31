// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/react/element_manager.h"

#include <array>
#include <memory>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "css/css_color.h"
#include "css/css_selector_constants.h"
#include "css/parser/css_string_parser.h"
#include "css/parser/length_handler.h"
#include "shell/common/vsync_monitor.h"
#include "shell/layout_mediator.h"
#include "starlight/style/computed_css_style.h"
#include "tasm/lynx_env_config.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/react/catalyzer.h"
#include "tasm/react/dynamic_css_styles_manager.h"
#include "tasm/react/fiber/component_element.h"
#include "tasm/react/fiber/fiber_element.h"
#include "tasm/react/fiber/image_element.h"
#include "tasm/react/fiber/list_element.h"
#include "tasm/react/fiber/none_element.h"
#include "tasm/react/fiber/page_element.h"
#include "tasm/react/fiber/raw_text_element.h"
#include "tasm/react/fiber/scroll_element.h"
#include "tasm/react/fiber/text_element.h"
#include "tasm/react/fiber/view_element.h"
#include "tasm/react/fiber/wrapper_element.h"
#include "tasm/react/painting_context.h"
#include "tasm/react/radon_element.h"
#include "tasm/recorder/recorder_controller.h"

#if ENABLE_AIR
#include "tasm/air/air_element/air_element.h"
#include "tasm/air/air_element/air_for_element.h"
#include "tasm/air/air_element/air_page_element.h"
#endif

#if ENABLE_INSPECTOR
using lynxdev::devtool::DevtoolFunction;
#endif

namespace lynx {
namespace tasm {
#pragma mark ElementManager

#if ENABLE_AIR
//====== for air element begin ========/
base::scoped_refptr<AirLepusRef> ElementManager::GetAirNode(
    const lepus::String &tag, int32_t lepus_id) {
  uint64_t key = air_root_->GetKeyForCreatedElement(lepus_id);
  auto element = air_node_manager_->GetForLepusId(lepus_id, key);
  if (element) {
    return element;
  }
  return nullptr;
}

base::scoped_refptr<AirLepusRef> ElementManager::CreateAirNode(
    const lepus::String &tag, int32_t lepus_id, int32_t impl_id, uint64_t key) {
  std::shared_ptr<AirElement> element =
      std::make_shared<AirElement>(kAirNormal, this, tag, lepus_id, impl_id);
  air_node_manager()->Record(element->impl_id(), element);

  auto res = AirLepusRef::Create(element);
  // In most cases, each element has a unique lepus id, but when tt:for node
  // or component node exists, there will be multiple elements with the same
  // lepus id. Use the double-map structure to record the elements. In the outer
  // map, key is the lepus id. In the inner map, for elements with the same
  // lepus id, using the unique id of tt:for or component to assemble a unique
  // key; for other cases, the key is the lepus id. We can find the specific
  // element with this record structrue.
  air_node_manager()->RecordForLepusId(lepus_id, key, res);
  return res;
}

AirPageElement *ElementManager::CreateAirPage(int32_t lepus_id) {
  auto page = std::make_shared<AirPageElement>(this, lepus_id);
  air_node_manager()->Record(page->impl_id(), page);
  return page.get();
}

void AirNodeManager::EraseLepusId(int id, AirElement *node) {
  auto iterator = air_lepus_id_map_.find(id);
  if (iterator != air_lepus_id_map_.end()) {
    auto &lepus_map = iterator->second;
    for (auto it = lepus_map.begin(); it != lepus_map.end();) {
      if (reinterpret_cast<AirLepusRef *>(it->second.Get())->Get() == node) {
        lepus_map.erase(it);
        break;
      } else {
        ++it;
      }
    }
  }
}

base::scoped_refptr<AirLepusRef> AirNodeManager::GetForLepusId(int tag,
                                                               uint64_t key) {
  auto it = air_lepus_id_map_.find(tag);
  if (it != air_lepus_id_map_.end()) {
    auto &map = it->second;
    if (map.find(key) != map.end()) {
      return AirLepusRef::Create(
          reinterpret_cast<AirLepusRef *>(map[key].Get()));
    }
  }
  return nullptr;
}

const std::vector<base::scoped_refptr<AirLepusRef>>
AirNodeManager::GetAllNodesForLepusId(int tag) const {
  auto it = air_lepus_id_map_.find(tag);
  if (it != air_lepus_id_map_.end()) {
    std::vector<base::scoped_refptr<AirLepusRef>> result;
    for (auto iter = it->second.begin(); iter != it->second.end(); ++iter) {
      // TODO(renpengcheng) delete the reinterpret_cast when AirLepusRef was
      // included by default
      result.push_back(AirLepusRef::Create(
          reinterpret_cast<AirLepusRef *>(iter->second.Get())));
    }
    return result;
  }
  return {};
}

void AirNodeManager::RecordForLepusId(int id, uint64_t key,
                                      base::scoped_refptr<AirLepusRef> node) {
  air_lepus_id_map_[id].emplace(key, std::move(node));
}

#endif

ElementManager::ElementManager(
    std::unique_ptr<PaintingContext::PlatformImpl> platform_painting_context,
    Delegate *delegate, const LynxEnvConfig &lynx_env_config,
    const std::shared_ptr<shell::VSyncMonitor> &vsync_monitor,
    const bool enable_diff_without_layout)
    : has_patches_(false),
      node_manager_(new NodeManager),
      air_node_manager_(new AirNodeManager),
      component_manager_(new ComponentManager),
      css_patch_(new CSSPatching),
      catalyzer_(std::make_unique<Catalyzer>(std::make_unique<PaintingContext>(
          std::move(platform_painting_context)))),
      root_(nullptr),
      is_first_patch_(true),
      lynx_env_config_(lynx_env_config),
      delegate_(delegate),
      vsync_monitor_(vsync_monitor),
      enable_diff_without_layout_(enable_diff_without_layout),
      platform_computed_css_(std::make_unique<starlight::ComputedCSSStyle>()),
      layout_computed_css_(std::make_unique<starlight::ComputedCSSStyle>()) {
  dom_tree_enabled_ = lynx::base::LynxEnv::GetInstance().IsDomTreeEnabled();
  platform_computed_css_->SetCSSParserConfigs(GetCSSParserConfigs());
}

ElementManager::~ElementManager() { WillDestroy(); }

void ElementManager::WillDestroy() {
  if (config_ && config_->GetEnableFiberArch()) {
    node_manager_->WillDestroy();
  }
}

void ElementManager::SetTraceId(int trace_id) { trace_id_ = trace_id; }

RadonElement *ElementManager::CreateNode(const lepus::String &tag,
                                         AttributeHolder *node) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager: CreateNode", "TagName",
              tag.str().c_str());
  RadonElement *element = new RadonElement(tag, node, this);
  EXEC_EXPR_FOR_INSPECTOR(PrepareNodeForInspector(element));
  return element;
}

#if ENABLE_INSPECTOR
void ElementManager::OnDocumentUpdated() {
  auto hierarchy_observer = hierarchy_observer_.lock();
  if (hierarchy_observer && IsDomTreeEnabled()) {
    hierarchy_observer->OnDocumentUpdated();
  }
}

void ElementManager::OnElementNodeAddedForInspector(Element *element) {
  auto hierarchy_observer = hierarchy_observer_.lock();
  if (hierarchy_observer && IsDomTreeEnabled()) {
    hierarchy_observer->OnElementNodeAdded(element);
  }
}

void ElementManager::OnElementNodeRemovedForInspector(Element *element) {
  auto hierarchy_observer = hierarchy_observer_.lock();
  if (hierarchy_observer && IsDomTreeEnabled()) {
    hierarchy_observer->OnElementNodeRemoved(element);
  }
}

void ElementManager::OnElementNodeSettedForInspector(
    Element *element, AttributeHolder *attribute_holder) {
  auto hierarchy_observer = hierarchy_observer_.lock();
  if (hierarchy_observer && IsDomTreeEnabled()) {
    hierarchy_observer->OnElementDataModelSetted(element, attribute_holder);
  }
}

void ElementManager::OnCSSStyleSheetAddedForInspector(Element *element) {
  auto hierarchy_observer = hierarchy_observer_.lock();
  if (hierarchy_observer && IsDomTreeEnabled()) {
    hierarchy_observer->OnCSSStyleSheetAdded(element);
  }
}

void ElementManager::OnComponentUselessUpdate(const std::string &component_name,
                                              const lepus::Value &properties) {
  auto hierarchy_observer = hierarchy_observer_.lock();
  if (hierarchy_observer) {
    hierarchy_observer->OnComponentUselessUpdate(component_name, properties);
    TRACE_EVENT_INSTANT(LYNX_TRACE_CATEGORY, "ComponentUselessUpdate",
                        [&component_name](lynx::perfetto::EventContext ctx) {
                          auto *debug = ctx.event()->add_debug_annotations();
                          debug->set_name("ComponentName");
                          debug->set_string_value(component_name);
                        });
  }
}

void ElementManager::OnSetNativeProps(tasm::Element *ptr,
                                      const std::string &name,
                                      const std::string &value, bool is_style) {
  auto hierarchy_observer = hierarchy_observer_.lock();
  if (hierarchy_observer && IsDomTreeEnabled()) {
    hierarchy_observer->OnSetNativeProps(ptr, name, value, is_style);
  }
}

void ElementManager::RunDevtoolFunction(
    lynxdev::devtool::DevtoolFunction func_enum, const base::any &data) {
  devtool_func_map_[func_enum](data);
}
#endif

void ElementManager::PrepareNodeForInspector(Element *element) {
#if ENABLE_INSPECTOR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "devtool logic: PrepareNodeForInspector");
  if (devtool_flag_ && IsDomTreeEnabled()) {
    RunDevtoolFunction(DevtoolFunction::InitForInspector,
                       std::make_tuple(element));
    if (element->GetTag() == "page" ||
        element->GetTag() == "component") {  // page is special component
      PrepareComponentNodeForInspector(element);
    }
  }
#endif
  return;
}

void ElementManager::CheckAndProcessSlotForInspector(Element *element) {
#if ENABLE_INSPECTOR
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "devtool logic: CheckAndProcessSlotForInspector");
  // If devtool_flag_ is false or IsDomTreeEnabled() is false, return.
  if (!devtool_flag_ || !IsDomTreeEnabled()) {
    return;
  }
  // Check if element is plug.
  FiberElement *current = static_cast<FiberElement *>(element);
  // If current is nullptr, return.
  if (current == nullptr) {
    return;
  }
  FiberElement *parent = static_cast<FiberElement *>(current->parent());
  // If parent is nullptr, return.
  if (parent == nullptr) {
    return;
  }
  FiberElement *component_element =
      static_cast<FiberElement *>(current->GetParentComponentElement());
  // If current's component_element is nullptr, return.
  if (component_element == nullptr) {
    return;
  }

  // If parent is current's component_element, current must not be plug, then
  // return.
  if (component_element == parent) {
    return;
  }

  // If parent's component_element == current's component_element, current must
  // not be plug, then return
  FiberElement *parent_component_element =
      static_cast<FiberElement *>(parent->GetParentComponentElement());
  if (component_element == parent_component_element) {
    return;
  }

  // Create slot elmenet for inspector.
  // TODO(songshourui.nll): unify the following code and create_element function
  // in PrepareComponentNodeForInspector as a common function.
  FiberElement *slot = nullptr;
  constexpr const static char *kSlotTag = "slot";
  slot = new FiberElement(this, kSlotTag);
  slot->SetParentComponentUniqueIdForFiber(parent_component_element->impl_id());
  PrepareNodeForInspector(slot);

  RunDevtoolFunction(DevtoolFunction::InsertPlug,
                     std::make_tuple(parent_component_element, element));
  RunDevtoolFunction(DevtoolFunction::SetSlotElement,
                     std::make_tuple(element, slot));
  RunDevtoolFunction(DevtoolFunction::InitSlotElement,
                     std::make_tuple(slot, element));
  RunDevtoolFunction(DevtoolFunction::SetPlugElement,
                     std::make_tuple(slot, element));
  RunDevtoolFunction(DevtoolFunction::SetSlotComponentElement,
                     std::make_tuple(slot, parent_component_element));
#endif
  return;
}

void ElementManager::RequestLayout(const PipelineOptions &options) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::RequestLayout");
  if (enable_diff_without_layout_) {
    delegate_->SetEnableLayout();
  } else {
    delegate_->DispatchLayoutUpdates(options);
  }
}

void ElementManager::DidPatchFinishForFiber() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::DidPatchFinishForFiber");
  is_first_patch_ = false;
}

void ElementManager::PrepareComponentNodeForInspector(Element *component) {
#if ENABLE_INSPECTOR
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "devtool logic: PrepareComponentNodeForInspector");

  const auto &create_element = [this, component](const std::string &tag) {
    bool enable_fiber = this->config_->GetEnableFiberArch();
    Element *element = nullptr;
    if (enable_fiber) {
      element = new FiberElement(this, tag.c_str());
      static_cast<FiberElement *>(element)->SetParentComponentUniqueIdForFiber(
          component->impl_id());
    } else {
      element = new RadonElement(tag.c_str(), nullptr, this);
    }
    return element;
  };

  if (component->GetTag() == "page") {
    Element *doc = create_element("doc");
    RunDevtoolFunction(DevtoolFunction::InitForInspector, std::make_tuple(doc));
    RunDevtoolFunction(DevtoolFunction::SetDocElement,
                       std::make_tuple(component, doc));
    node_manager_->Record(doc->impl_id(), doc);
  }

  Element *shadowRoot = create_element("shadow_root");
  RunDevtoolFunction(DevtoolFunction::InitForInspector,
                     std::make_tuple(shadowRoot));
  RunDevtoolFunction(DevtoolFunction::SetShadowRootElement,
                     std::make_tuple(component, shadowRoot));
  shadowRoot->set_parent(component);
  node_manager_->Record(shadowRoot->impl_id(), shadowRoot);

  Element *style = create_element("style");
  RunDevtoolFunction(DevtoolFunction::InitForInspector, std::make_tuple(style));
  RunDevtoolFunction(DevtoolFunction::SetStyleElement,
                     std::make_tuple(shadowRoot, style));
  style->set_parent(shadowRoot);
  node_manager_->Record(style->impl_id(), style);

  Element *style_value = create_element("stylevalue");
  RunDevtoolFunction(DevtoolFunction::InitForInspector,
                     std::make_tuple(style_value));

  RunDevtoolFunction(DevtoolFunction::InitStyleValueElement,
                     std::make_tuple(style_value, component));
  RunDevtoolFunction(DevtoolFunction::SetStyleValueElement,
                     std::make_tuple(style, style_value));
  style_value->set_parent(style);
  node_manager_->Record(style_value->impl_id(), style_value);

  RunDevtoolFunction(DevtoolFunction::SetStyleRoot,
                     std::make_tuple(style_value, style_value));
  RunDevtoolFunction(DevtoolFunction::SetStyleRoot,
                     std::make_tuple(style, style_value));
  RunDevtoolFunction(DevtoolFunction::SetStyleRoot,
                     std::make_tuple(shadowRoot, style_value));

  if (component->GetTag() == "page") {
    RunDevtoolFunction(DevtoolFunction::SetStyleRoot,
                       std::make_tuple(component, style_value));
  }

  std::string style_sheet_id = lepus::to_string(style_value->impl_id());
  OnCSSStyleSheetAddedForInspector(style_value);
#endif
  return;
}

RadonElement *ElementManager::CreatePseudoNode(int style_type) {
  RadonElement *element = nullptr;
  if (style_type & CSSSheet::BEFORE_SELECT) {
    element = new RadonElement(lepus::String("inline-text"), nullptr, this);
  } else if (style_type & CSSSheet::AFTER_SELECT) {
    element = new RadonElement(lepus::String("inline-text"), nullptr, this);
  } else if (style_type & CSSSheet::SELECTION_SELECT) {
    element = new RadonElement(lepus::String("text-selection"), nullptr, this);
  }
  if (element) {
    EXEC_EXPR_FOR_INSPECTOR({
      if (devtool_flag_ && IsDomTreeEnabled()) {
        RunDevtoolFunction(DevtoolFunction::InitForInspector,
                           std::make_tuple(element));
      }
    });
    element->ResetPseudoType(style_type);
  }
  return element;
}

void ElementManager::ResolveAttributesAndStyle(AttributeHolder *node,
                                               RadonElement *shadow_node,
                                               StyleMap &styles) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, RESOLVE_ATTR_AND_STYLE);
  // FIXME: key frames should not be singleton
  auto style_sheet = node->ParentStyleSheet();
  if (preresolving_style_sheet_ != style_sheet && style_sheet /* && TODO:(radon)
      node->component()->is_first_patch() */) {
    preresolving_style_sheet_ = style_sheet;
    const auto &all_fontfaces = style_sheet->fontfaces();
    if (!all_fontfaces.empty()) {
      root_->SetFontFaces(all_fontfaces);
    }
  }

  // Normally, all attributes should be consumed before consuming the style.
  // This is because attributes are usually a switch, such as
  // enable_new_animator, and the value of the attribute switch may be needed
  // when consuming the style. However, due to historical legacy issues,
  // attributes were consumed later than styles. If we directly exchange the
  // order of the two, it will cause a breaking change. Therefore, here we check
  // the new animator in advance.
  for (const auto &attribute : node->attributes()) {
    shadow_node->CheckNewAnimatorAttr(attribute.first, attribute.second.first);
  }

  shadow_node->SetStyle(styles);

  for (const auto &attribute : node->attributes()) {
    shadow_node->SetAttribute(attribute.first, attribute.second.first);
  }

  const DataMap &data_map = node->dataset();
  if (!data_map.empty()) {
    shadow_node->SetDataSet(node->dataset());
  }

  // Resolve other pseudo selectors
  {
    //::placeholder styles
    if (shadow_node->HasPlaceHolder()) {
      CSSFragment *fragment = node->ParentStyleSheet();
      if (!fragment) return;
      if (fragment->enable_css_selector()) {
        StyleMap result;
        AttributeHolder placeholder;
        placeholder.AddPseudoState(kPseudoStatePlaceHolder);
        placeholder.SetPseudoElementOwner(node);
        css_patch_->GetCSSStyleNew(&placeholder, result, fragment);
        if (result.empty()) return;
        PseudoPlaceHolderStyles style;
        ParsePlaceHolderTokens(style, result);
        shadow_node->SetPlaceHolderStyles(style);
        return;
      }
      std::vector<CSSParseToken *> tokens =
          ParsePseudoCSSTokens(node, kCSSSelectorPlaceholder);
      // process ::placeholder tokens
      const auto &placeholder_value = ParsePlaceHolderTokens(tokens);
      shadow_node->SetPlaceHolderStyles(placeholder_value);
    }
  }
  ResolveEvents(node, shadow_node);
}

void ElementManager::ResolveEvents(AttributeHolder *node, Element *element) {
  for (const auto &event : node->static_events()) {
    element->SetEventHandler(event.first, event.second.get());
  }

  for (const auto &lepus_event : node->lepus_events()) {
    element->SetEventHandler(lepus_event.first, lepus_event.second.get());
  }
  // handle global-bind event and store element id in order to construct
  // currentTarget object
  for (const auto &global_bind_event : node->global_bind_events()) {
    EventHandler *handler = global_bind_event.second.get();
    element->SetEventHandler(global_bind_event.first, handler);
    SetGlobalBindElementId(handler->name(), handler->type(),
                           element->impl_id());
  }
}

void ElementManager::ResolveAttributesAndStyle(AttributeHolder *node,
                                               RadonElement *shadow_node) {
  // Styles
  StyleMap styles;
  css_patch_->GetCSSStyle(node, styles);
  css_var_handler_.HandleCSSVariables(styles, node, GetCSSParserConfigs());
  ResolveAttributesAndStyle(node, shadow_node, styles);
}

std::vector<CSSParseToken *> ElementManager::ParsePseudoCSSTokens(
    AttributeHolder *node, const char *selector) {
  std::vector<CSSParseToken *> tokens;

  CSSFragment *fragment = node->ParentStyleSheet();
  if (!fragment) return tokens;

  const lepus::String &tag_node = node->tag();
  // Global  ::xxx
  {
    auto token = fragment->GetPseudoStyle(selector);
    if (token) {
      tokens.emplace_back(token);
    }
  }

  // tag selector  tag::xxx
  if (!tag_node.empty()) {
    std::string rule = tag_node.str() + selector;
    auto token = fragment->GetPseudoStyle(rule);
    if (token) {
      tokens.emplace_back(token);
    }
  }

  // class selector  .class::xxx
  auto const &class_list = node->classes();
  for (auto const &clazz : class_list) {
    std::string rule = kCSSSelectorClass + clazz.impl()->str() + selector;

    auto token = fragment->GetPseudoStyle(rule);
    if (token) {
      tokens.emplace_back(token);
    }
  }

  // id selector #id::xxx
  auto const &id = node->idSelector();
  if (!id.empty()) {
    std::string rule = kCSSSelectorID + id.str() + selector;
    auto token = fragment->GetPseudoStyle(rule);
    if (token) {
      tokens.emplace_back(token);
    }
  }

  return tokens;
}

void ElementManager::UpdateContentNode(const StyleMap &attrs,
                                       RadonElement *element) {
  if (!element->IsPseudoNode() || !element->content_data()) return;

  ContentData *data = element->content_data();
  while (data) {
    RadonElement *node = nullptr;

    if (data->isText()) {
      node = new RadonElement("raw-text", nullptr, this);
      TextContentData *text_data = static_cast<TextContentData *>(data);
      lepus::Value value(lepus::StringImpl::Create(text_data->text().c_str()));
      node->SetAttribute("text", value);
      lepus::Value value1(true);
      // For reason: lepus string c++ do not support unicode convert now
      // so we pass a flag to RawTextShadowNode
      node->SetAttribute("pseudo", value1);
    } else if (data->isImage()) {
      node = new RadonElement("inline-image", nullptr, this);
      ImageContentData *image_data = static_cast<ImageContentData *>(data);
      lepus::Value value(lepus::StringImpl::Create(image_data->url().c_str()));
      node->SetAttribute("src", value);
    } else if (data->isAttr()) {
      AttrContentData *content_data = static_cast<AttrContentData *>(data);
      auto content = content_data->attr_content();
      if (content.IsString()) {
        node = new RadonElement("raw-text", nullptr, this);
        node->SetAttribute("text", content);
      }
    }

    if (node) {
      EXEC_EXPR_FOR_INSPECTOR({
        if (devtool_flag_ && IsDomTreeEnabled()) {
          RunDevtoolFunction(DevtoolFunction::InitForInspector,
                             std::make_tuple(node));
        }
      });
      node->SetIsPseudoNode();
      node->SetStyle(attrs);
      node->FlushProps();
      element->InsertNode(node);
    }

    data = data->next();
  }
}

void ElementManager::UpdateScreenMetrics(float width, float height) {
  LOGI("ElementManager::UpdateScreenMetrics width:" << width
                                                    << ",height:" << height);
  GetLynxEnvConfig().UpdateScreenSize(width, height);
  // 1.update layout tree
  delegate_->UpdateLynxEnvForLayoutThread(GetLynxEnvConfig());
  if (root()) {
    // 2.update element tree
    root()->UpdateDynamicElementStyle();
  }
}

void ElementManager::UpdateFontScale(float font_scale) {
  GetLynxEnvConfig().SetFontScale(font_scale);
  // update element tree
  delegate_->UpdateLynxEnvForLayoutThread(GetLynxEnvConfig());
  if (root()) {
    root()->UpdateDynamicElementStyle();
    delegate_->SetRootOnLayout(root_->layout_node());
  }
}

void ElementManager::SetHierarchyObserver(
    const std::shared_ptr<HierarchyObserver> &hierarchy_observer) {
  hierarchy_observer_ = hierarchy_observer;
}

void ElementManager::UpdatePseudoShadowsNew(AttributeHolder *node,
                                            RadonElement *self) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, UPDATE_PSEUDO_SHADOWS);
  CSSFragment *fragment = node->ParentStyleSheet();
  if (!fragment) return;

  if (self->GetTag() == "text") {  // only text can support selection
    AttributeHolder selection;
    selection.AddPseudoState(kPseudoStateSelection);
    selection.SetPseudoElementOwner(node);
    StyleMap result;
    css_patch_->GetCSSStyleNew(&selection, result, fragment);
    if (result.empty()) {
      return;
    }
    // ::selection
    auto pseudo_node = CreatePseudoNode(CSSSheet::SELECTION_SELECT);
    if (!pseudo_node) {
      return;
    }
    pseudo_node->SetIsPseudoNode();
    pseudo_node->SetStyle(result);
    pseudo_node->FlushProps();
    self->InsertNode(pseudo_node);
  }
}

void ElementManager::UpdatePseudoShadows(AttributeHolder *node,
                                         RadonElement *self) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, UPDATE_PSEUDO_SHADOWS);
  CSSFragment *fragment = node->ParentStyleSheet();
  if (!fragment) return;

  if (!fragment->HasPseudoStyle()) {
    return;
  }

  // ::before
  UpdateBeforeAfterPseudo(ParsePseudoCSSTokens(node, kCSSSelectorBefore), node,
                          self, true);
  // ::after
  UpdateBeforeAfterPseudo(ParsePseudoCSSTokens(node, kCSSSelectorAfter), node,
                          self, false);
  if (self->GetTag() == "text") {  // only text can support selection
    // ::selection
    UpdateSelectionPseudo(ParsePseudoCSSTokens(node, kCSSSelectorSelection),
                          self);
  }
}

void ElementManager::ParsePlaceHolderTokens(PseudoPlaceHolderStyles &result,
                                            const StyleMap &map) {
  for (const auto &i : map) {
    auto id = i.first;
    auto &value = i.second;
    if (id == kPropertyIDColor) {
      result.color_ = value;
    } else if (id == kPropertyIDFontSize) {
      result.font_size_ = value;
    } else if (id == kPropertyIDFontWeight) {
      result.font_weight_ = value;
    } else if (id == kPropertyIDFontFamily) {
      result.font_family_ = value;
    } else {
      UnitHandler::CSSWarning(false,
                              GetCSSParserConfigs().enable_css_strict_mode,
                              "placeholder only support color && font-size");
    }
  }
}

PseudoPlaceHolderStyles ElementManager::ParsePlaceHolderTokens(
    std::vector<CSSParseToken *> tokens) {
  PseudoPlaceHolderStyles result;

  for (const auto &token : tokens) {
    auto &map = token->GetAttribute();
    ParsePlaceHolderTokens(result, map);
  }
  return result;
}

void ElementManager::UpdateBeforeAfterPseudo(
    const std::vector<CSSParseToken *> &token_list, AttributeHolder *node,
    RadonElement *self, bool before) {
  for (auto token : token_list) {
    if (!token->IsPseudoStyleToken()) {
      continue;
    }

    auto target_sheet = token->TargetSheet();
    if (!target_sheet) {
      continue;
    }

    auto const &styles = token->GetAttribute();
    auto it = styles.find(CSSPropertyID::kPropertyIDContent);

    if (it == styles.end()) {
      continue;
    }

    auto pseudo_node = CreatePseudoNode(target_sheet->GetType());
    if (!pseudo_node) {
      continue;
    }

    pseudo_node->SetIsPseudoNode();
    pseudo_node->SetStyle(styles);
    pseudo_node->FlushProps();

    if (before) {
      self->InsertNode(pseudo_node, 0);
    } else {
      self->InsertNode(pseudo_node);
    }

    // parser content attr to construct ContentData
    GenerateContentData(it->second.GetValue(), node, pseudo_node);
    UpdateContentNode(styles, pseudo_node);
  }
}

void ElementManager::UpdateSelectionPseudo(
    const std::vector<CSSParseToken *> &token_list, RadonElement *self) {
  if (token_list.empty()) {
    return;
  }

  // TODO support more selection style, and handle multi selection style merge
  // currently only the last element is meaningful
  auto token = token_list.back();
  auto sheet = token->TargetSheet();

  if (!sheet) {
    return;
  }

  auto pseudo_node = CreatePseudoNode(sheet->GetType());

  if (!pseudo_node) {
    return;
  }

  pseudo_node->SetIsPseudoNode();
  pseudo_node->SetStyle(token->GetAttribute());
  pseudo_node->FlushProps();

  self->InsertNode(pseudo_node);
}

void ElementManager::GenerateContentData(const lepus::Value &value,
                                         const AttributeHolder *vnode,
                                         RadonElement *node) {
  struct Content {
    enum ContentType {
      TEXT = 0,
      URL,
      ATTR,
    };

    ContentType type;
    std::string content;
  };

  if (!value.IsString()) return;

  std::string str = value.String()->c_str();

  static std::string quote = "\"";
  static std::string right_brackets = ")";
  static std::string url_key = "url(";
  static std::string attr_key = "attr(";

  std::vector<Content> pseudo_contents;
  std::string tmp = str;
  bool left_match = false;
  bool right_match = false;
  size_t left_pos = 0;
  size_t right_pos = 0;

  bool invalidate_str = false;

  while (!tmp.empty() && !invalidate_str) {
    size_t quote_pos = tmp.find(quote);
    size_t url_pos = tmp.find(url_key);
    size_t attr_pos = tmp.find(attr_key);
    size_t blank_pos = tmp.find(" ");
    if (quote_pos == 0) {
      left_pos = quote_pos;
      left_match = (left_pos != std::string::npos);
      right_pos = tmp.find(quote, left_pos + 1);
      right_match = (right_pos != std::string::npos);

      if (left_match && right_match) {
        std::string sub_str =
            tmp.substr(left_pos + 1, right_pos - left_pos - 1);
        Content curr;
        curr.type = Content::TEXT;
        curr.content = sub_str;
        pseudo_contents.push_back(curr);
        tmp.erase(left_pos, right_pos - left_pos + 1);
        left_match = right_match = false;
      } else {
        invalidate_str = true;
      }
    } else if (url_pos == 0) {
      left_pos = url_pos;
      right_pos = tmp.find(right_brackets, left_pos + 4);
      CSSStringParser parser(tmp.c_str(), static_cast<int>(tmp.size()),
                             GetCSSParserConfigs());
      std::string sub_str = parser.ParseUrl();
      if (!sub_str.empty()) {
        Content curr;
        curr.type = Content::URL;
        curr.content = sub_str;
        pseudo_contents.push_back(curr);
        tmp.erase(left_pos, right_pos - left_pos + 1);
      } else {
        invalidate_str = true;
      }
    } else if (attr_pos == 0) {
      left_pos = attr_pos;
      left_match = (left_pos != std::string::npos);
      right_pos = tmp.find(right_brackets, left_pos + 5);
      right_match = (right_pos != std::string::npos);

      if (left_match && right_match) {
        std::string sub_str =
            tmp.substr(left_pos + 5, right_pos - left_pos - 5);
        Content curr;
        curr.type = Content::ATTR;
        curr.content = sub_str;
        pseudo_contents.push_back(curr);
        tmp.erase(left_pos, right_pos - left_pos + 1);
        left_match = right_match = false;
      } else {
        invalidate_str = true;
      }
    } else if (blank_pos == 0) {
      do {
        tmp.erase(0, 1);
        blank_pos = tmp.find(" ");
      } while (blank_pos == 0);
    } else {
      std::string result;
      for (auto c : tmp) {
        if (c != '\'') {
          result.push_back(c);
        }
      }
      Content curr;
      curr.type = Content::TEXT;
      curr.content = result;
      pseudo_contents.push_back(curr);
      tmp.clear();
    }
  }

  if (invalidate_str) pseudo_contents.clear();

  ContentData *pre = nullptr;
  for (const auto &pseudo_content : pseudo_contents) {
    ContentData *cur = nullptr;
    if (pseudo_content.type == Content::TEXT)
      cur =
          ContentData::createTextContent(lepus::String(pseudo_content.content));
    else if (pseudo_content.type == Content::URL)
      cur = ContentData::createImageContent(pseudo_content.content);
    else
      cur = ContentData::createAttrContent(vnode, pseudo_content.content);
    if (pre)
      pre->set_next(cur);
    else
      node->SetContentData(cur);
    pre = cur;
  }
}

void ElementManager::OnDeleteStyle(RadonElement *node,
                                   std::vector<CSSPropertyID> &style_names) {
  node->ResetStyle(style_names);
}

void ElementManager::OnUpdateStyle(RadonElement *node, StyleMap &styles) {
  node->SetStyle(styles);
}

void ElementManager::OnDeletedAttr(RadonElement *node,
                                   const lepus::String &attr_name) {
  node->ResetAttribute(attr_name);
}

void ElementManager::OnUpdateAttr(RadonElement *node,
                                  const lepus::String &attr_name,
                                  const lepus::Value &new_value) {
  node->SetAttribute(attr_name, new_value);
}

void ElementManager::OnUpdateDataSet(RadonElement *node, const DataMap &data) {
  node->SetDataSet(data);
}

void ElementManager::GetStyleList(AttributeHolder *node, StyleMap &new_styles,
                                  bool process_variable) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::GetStyleList");
  css_patch_->GetCSSStyle(node, new_styles);
  if (process_variable) {
    css_var_handler_.HandleCSSVariables(new_styles, node,
                                        GetCSSParserConfigs());
  }
}

void ElementManager::GetCachedStyleList(AttributeHolder *node,
                                        StyleMap &new_styles,
                                        bool process_variable) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::GetCachedStyleList");
  css_patch_->GetCachedCSSStyle(node, new_styles);
  if (process_variable) {
    css_var_handler_.HandleCSSVariables(new_styles, node,
                                        GetCSSParserConfigs());
    node->set_cached_styles(new_styles);
  }
}

void ElementManager::GetUpdatedStyleList(AttributeHolder *node,
                                         StyleMap &new_styles,
                                         bool process_variable) {
#if ENABLE_HMR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::GetUpdatedStyleList");
  css_patch_->GetUpdatedCSSStyle(node, new_styles);

  if (process_variable) {
    css_var_handler_.HandleCSSVariables(new_styles, node,
                                        GetCSSParserConfigs());
  }
#endif
}

void ElementManager::OnFinishUpdateProps(Element *node) {
  if (node->is_radon_element()) {
    static_cast<RadonElement *>(node)->FlushProps();
  } else if (node->is_fiber_element()) {
    static_cast<FiberElement *>(node)->MarkPropsDirty();
  }
  has_patches_ = true;
}

void ElementManager::OnValidateNode(Element *node) {
  // TODO: (liujilong.me) handle validate shadow node.
  catalyzer_->painting_context()->HandleValidate(node->impl_id());
  has_patches_ = true;
}

void ElementManager::OnPatchFinishFromRadon(bool outer_has_patches,
                                            const PipelineOptions &options) {
  has_patches_ = outer_has_patches;
  OnPatchFinish(options);
}

void ElementManager::OnPatchFinish(const PipelineOptions &options) {
  if (root() == nullptr) {
    // There is no element to be processed.
    return;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "ElementManager::OnPatchFinish");
  catalyzer_->painting_context()->FinishTasmOperation(options);
  if (!has_patches_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::OnPatchFinishNoPatch");
    LOGI("ElementManager::OnPatchFinishNoPatch!");
    catalyzer_->painting_context()->FinishLayoutOperation(options);
    delegate_->OnUpdateDataWithoutChange();
    return;
  }
  LOGI("ElementManager::OnPatchFinish");

  OnPatchFinishInner(options, false);

  has_patches_ = false;
}

void ElementManager::PatchEventRelatedInfo() {
  if (push_touch_pseudo_flag_) {
    catalyzer_->painting_context()->UpdateEventInfo(true);
    push_touch_pseudo_flag_ = false;
  }
}

void ElementManager::OnPatchFinishInner(const PipelineOptions &options) {
  OnPatchFinishInner(options, true);
}

void ElementManager::OnPatchFinishInner(
    const PipelineOptions &options,
    const bool is_need_notify_finish_patch_operation) {
  if (GetLayoutHasBaseline()) {
    delegate_->DispatchLayoutHasBaseline();
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::OnPatchFinishInner",
              [&options](lynx::perfetto::EventContext ctx) {
                options.UpdateTraceDebugInfo(ctx.event());
              });
  if (is_need_notify_finish_patch_operation) {
    catalyzer_->painting_context()->FinishTasmOperation(options);
  }
  PatchEventRelatedInfo();
  root()->UpdateDynamicElementStyle();
  {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager sort z-index");
    // sort z-index children
    for (const auto &context : dirty_stacking_contexts_) {
      context->UpdateZIndexList();
    }
  }
  dirty_stacking_contexts_.clear();
  RequestLayout(options);
  is_first_patch_ = false;
}

#if ENABLE_AIR
void ElementManager::OnPatchFinishInnerForAir(const PipelineOptions &options) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::OnPatchFinishInnerForAir");
  delegate_->DispatchLayoutUpdates(options);
}
#endif

void ElementManager::OnNodeFailedToRender(int tag) {
  auto *element = node_manager()->Get(tag);
  if (element == nullptr || element->data_model() == nullptr) {
    return;
  }
  element->OnRenderFailed();
}

PaintingContext *ElementManager::painting_context() {
  return catalyzer_->painting_context();
}

void ElementManager::UpdateViewport(float width, SLMeasureMode width_mode,
                                    float height, SLMeasureMode height_mode,
                                    bool need_layout) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::UpdateViewport");
  auto old_env = GetLynxEnvConfig();
  GetLynxEnvConfig().UpdateViewport(width, width_mode, height, height_mode);
  if (old_env.ViewportHeight() != GetLynxEnvConfig().ViewportHeight() ||
      old_env.ViewportWidth() != GetLynxEnvConfig().ViewportWidth()) {
    delegate_->UpdateLynxEnvForLayoutThread(GetLynxEnvConfig());
  }
  if (root()) {
    // 2.update element tree
    root()->UpdateDynamicElementStyle();
  }
  OnUpdateViewport(width, width_mode, height, height_mode, need_layout);
}

void ElementManager::OnUpdateViewport(float width, int width_mode, float height,
                                      int height_mode, bool need_layout) {
  delegate_->OnUpdateViewport(width, width_mode, height, height_mode,
                              need_layout);
}

void ElementManager::SetHierarchyObserverOnLayout(
    const std::weak_ptr<HierarchyObserver> &hierarchy_observer) {
  delegate_->SetHierarchyObserverOnLayout(hierarchy_observer);
}

void ElementManager::SetRootOnLayout(const std::shared_ptr<LayoutNode> &root) {
  delegate_->SetRootOnLayout(root);
}

// delegate for class element
void ElementManager::UpdateLayoutNodeFontSize(
    tasm::LayoutContext::SPLayoutNode node, double cur_node_font_size,
    double root_node_font_size) {
  delegate_->UpdateLayoutNodeFontSize(node, cur_node_font_size,
                                      root_node_font_size,
                                      GetLynxEnvConfig().FontScale());
}

void ElementManager::InsertLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                                      tasm::LayoutContext::SPLayoutNode child,
                                      int index) {
  delegate_->InsertLayoutNode(parent, child, index);
}

void ElementManager::RemoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                                      tasm::LayoutContext::SPLayoutNode child,
                                      int index, bool destroy) {
  delegate_->RemoveLayoutNode(parent, child, index, destroy);
}

void ElementManager::InsertLayoutNodeBefore(
    tasm::LayoutContext::SPLayoutNode parent,
    tasm::LayoutContext::SPLayoutNode child,
    tasm::LayoutContext::SPLayoutNode ref_node) {
  delegate_->InsertLayoutNodeBefore(parent, child, ref_node);
}

void ElementManager::RemoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                                      tasm::LayoutContext::SPLayoutNode child) {
  delegate_->RemoveLayoutNode(parent, child);
}
void ElementManager::DestroyLayoutNode(tasm::LayoutContext::SPLayoutNode node) {
  delegate_->DestroyLayoutNode(node);
}

void ElementManager::MoveLayoutNode(tasm::LayoutContext::SPLayoutNode parent,
                                    tasm::LayoutContext::SPLayoutNode child,
                                    int from_index, int to_index) {
  delegate_->MoveLayoutNode(parent, child, from_index, to_index);
}

void ElementManager::SendAnimationEvent(const char *type, int tag,
                                        const lepus::Value &dict) {
  delegate_->SendAnimationEvent(type, tag, dict);
}

void ElementManager::UpdateLayoutNodeStyle(
    tasm::LayoutContext::SPLayoutNode node, tasm::CSSPropertyID css_id,
    const tasm::CSSValue &value) {
  has_patches_ = true;
  delegate_->UpdateLayoutNodeStyle(node, css_id, value);
}

void ElementManager::ResetLayoutNodeStyle(
    tasm::LayoutContext::SPLayoutNode node, tasm::CSSPropertyID css_id) {
  has_patches_ = true;
  delegate_->ResetLayoutNodeStyle(node, css_id);
}

void ElementManager::UpdateLayoutNodeAttribute(
    tasm::LayoutContext::SPLayoutNode node, starlight::LayoutAttribute key,
    const lepus::Value &value) {
  has_patches_ = true;
  delegate_->UpdateLayoutNodeAttribute(node, key, value);
}

void ElementManager::SetFontFaces(const tasm::CSSFontFaceTokenMap &fontfaces) {
  delegate_->SetFontFaces(fontfaces);
}

void ElementManager::MarkNodeAnimated(tasm::LayoutContext::SPLayoutNode node,
                                      bool animated) {
  delegate_->MarkNodeAnimated(node, animated);
}

void ElementManager::UpdateLayoutNodeProps(
    tasm::LayoutContext::SPLayoutNode node,
    const std::shared_ptr<tasm::PropBundle> &props) {
  delegate_->UpdateLayoutNodeProps(node, props);
}

// FIXME(heshan):workaround, now must sync create shadow node
void ElementManager::AttachLayoutNode(tasm::LayoutContext::SPLayoutNode node,
                                      tasm::PropBundle *props) {
  lepus::String tag = props->tag();
  auto it = node_type_recorder_.find(tag);
  bool found = it != node_type_recorder_.end();
  if (found) {
    node->set_type(static_cast<LayoutNodeType>(it->second));
    if (node->is_common() && !node->IsParentInlineContainer()) {
      return;
    }
  }
  // Root node is a common node
  if ((root() && node->id() == root()->layout_node()->id())
#if ENABLE_AIR
      || (AirRoot() && node->id() == AirRoot()->layout_node()->id())
#endif
  ) {
    node->set_type(LayoutNodeType::COMMON);
    return;
  }
  if (tag.str() == kListNodeTag) {
    node->set_type(LayoutNodeType::LIST);
    if (!found) {
      node_type_recorder_.insert({tag, LayoutNodeType::LIST});
      if (!node->IsParentInlineContainer()) {
        return;
      }
    }
  }
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, CREATE_LAYOUT_NODE);

  int type =
      shadow_node_creator_(node->id(), reinterpret_cast<intptr_t>(node.get()),
                           tag.str(), props, node->IsParentInlineContainer());
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  node->set_type(static_cast<LayoutNodeType>(type));
  delegate_->RegisterPlatformAttachedLayoutNode(node);
  if (!found) {
    if (!(type & INLINE)) {
      node_type_recorder_.insert({tag, type});
    }
#if ENABLE_ARK_RECORDER
    tasm::recorder::ArkBaseRecorder::GetInstance().RecordComponent(
        tag.str().c_str(), type, record_id_);
#endif
  }
}

bool ElementManager::IsShadowNodeVirtual(const lepus::String &tag_name) {
  auto it = node_virtuality_recorder_.find(tag_name.str());
  if (it != node_virtuality_recorder_.end()) {
    return it->second;
  }
  bool result = painting_context()->IsTagVirtual(tag_name.str());
  node_virtuality_recorder_.emplace(tag_name.str(), result);
  return result;
}

void ElementManager::MarkLayoutDirty(tasm::LayoutContext::SPLayoutNode node) {
  delegate_->MarkLayoutDirty(node);
}

void ElementManager::UpdateTouchPseudoStatus(bool value) {
  push_touch_pseudo_flag_ = value;
}

void ElementManager::SetConfig(const std::shared_ptr<PageConfig> &config) {
  config_ = config;
  // Apply pagewise configs
  if (config_) {
    painting_context()->SetEnableVsyncAlignedFlush(
        config_->GetEnableVsyncAlignedFlush());
    lynx_env_config_.SetFontScaleSpOnly(GetLayoutConfigs().font_scale_sp_only_);
    css_var_handler_.SetEnableFiberArch(config_->GetEnableFiberArch());
  }
}

void ElementManager::RequestNextFrameTime(Element *element) {
  animation_element_set_.insert(element);
  if (animation_vsync_proxy_ == nullptr) {
    animation_vsync_proxy_ = std::make_shared<animation::AnimationVSyncProxy>(
        animation::AnimationVSyncProxy(this, vsync_monitor_));
  }
  animation_vsync_proxy_->RequestNextFrameTime();
}

void ElementManager::NotifyElementDestroy(Element *element) {
  if (animation_element_set_.find(element) != animation_element_set_.end()) {
    animation_element_set_.erase(element);
  }
}

void ElementManager::TickAllElement(fml::TimePoint &frame_time) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::TickAllElement");
  if (animation_vsync_proxy_) {
    auto temp_element_set = std::set<Element *>();
    // We should swap all element to a temporary set before when we tick them.
    temp_element_set.swap(animation_element_set_);
    if (!temp_element_set.empty()) {
      for (auto iter : temp_element_set) {
        iter->TickAllAnimation(frame_time);
      }
      PipelineOptions options;
      if (config_ && config_->GetEnableFiberArch()) {
        // Optimization: If there is only an element need to be ticked, take it
        // as root to flush action.
        if (temp_element_set.size() == 1) {
          OnPatchFinishForFiber(options, static_cast<tasm::FiberElement *>(
                                             *temp_element_set.begin()));
        } else {
          OnPatchFinishForFiber(options);
        }
      } else {
        OnPatchFinish(options);
      }
    }
  }
}

void ElementManager::SetGlobalBindElementId(const lepus::String &name,
                                            const lepus::String &type,
                                            const int node_id) {
  auto &map = global_bind_name_to_ids_;
  auto name_str = name.str();
  if (name_str.empty()) {
    return;
  }
  auto iter = map.find(name_str);
  if (iter == map.end()) {
    std::set<int> set;
    set.insert(node_id);
    map[name_str] = set;
  } else {
    iter->second.insert(node_id);
  }
}

void ElementManager::EraseGlobalBindElementId(const EventMap &global_event_map,
                                              const int node_id) {
  if (global_event_map.empty()) {
    return;
  }
  auto &map = global_bind_name_to_ids_;
  for ([[maybe_unused]] auto &[key, event] : map) {
    event.erase(node_id);
  }
}

std::set<int> ElementManager::GetGlobalBindElementIds(
    const std::string &name) const {
  auto &map = global_bind_name_to_ids_;

  auto iter = map.find(name);
  if (iter != map.end()) {
    return iter->second;
  }
  return {};
}

bool ElementManager::Hydrate(AttributeHolder *node, RadonElement *shadow_node) {
  if (node->static_events().empty() && node->lepus_events().empty()) {
    return false;
  }

  for (const auto &event : node->static_events()) {
    shadow_node->SetEventHandler(event.first, event.second.get());
  }

  for (const auto &lepus_event : node->lepus_events()) {
    shadow_node->SetEventHandler(lepus_event.first, lepus_event.second.get());
  }

  return true;
}

base::scoped_refptr<FiberElement> ElementManager::CreateFiberNode(
    const lepus::String &tag) {
  auto res = base::AdoptRef<FiberElement>(new FiberElement(this, tag));
  return res;
}

base::scoped_refptr<PageElement> ElementManager::CreateFiberPage(
    const lepus::String &component_id, int32_t css_id) {
  if (fiber_page_) {
    node_manager()->Erase(fiber_page_->impl_id());
  }

  fiber_page_ =
      base::AdoptRef<PageElement>(new PageElement(this, component_id, css_id));
  return fiber_page_;
}

base::scoped_refptr<ComponentElement> ElementManager::CreateFiberComponent(
    const lepus::String &component_id, int32_t css_id,
    const lepus::String &entry_name, const lepus::String &name,
    const lepus::String &path) {
  auto res = base::AdoptRef<ComponentElement>(
      new ComponentElement(this, component_id, css_id, entry_name, name, path));
  return res;
}

base::scoped_refptr<ViewElement> ElementManager::CreateFiberView() {
  auto res = base::AdoptRef<ViewElement>(new ViewElement(this));
  return res;
}

base::scoped_refptr<ImageElement> ElementManager::CreateFiberImage(
    const lepus::String &tag) {
  auto res = base::AdoptRef<ImageElement>(new ImageElement(this, tag));
  return res;
}

base::scoped_refptr<TextElement> ElementManager::CreateFiberText(
    const lepus::String &tag) {
  auto res = base::AdoptRef<TextElement>(new TextElement(this, tag));
  return res;
}

base::scoped_refptr<RawTextElement> ElementManager::CreateFiberRawText() {
  return base::AdoptRef<RawTextElement>(new RawTextElement(this));
}

base::scoped_refptr<ScrollElement> ElementManager::CreateFiberScrollView(
    const lepus::String &tag) {
  auto res = base::AdoptRef<ScrollElement>(new ScrollElement(this, tag));
  return res;
}

base::scoped_refptr<ListElement> ElementManager::CreateFiberList(
    tasm::TemplateAssembler *tasm, const lepus::String &tag,
    const lepus::Value &component_at_index,
    const lepus::Value &enqueue_component) {
  auto res = base::AdoptRef<ListElement>(
      new ListElement(this, tag, component_at_index, enqueue_component));
  res->set_tasm(tasm);
  return res;
}

base::scoped_refptr<NoneElement> ElementManager::CreateFiberNoneElement() {
  auto res = base::AdoptRef<NoneElement>(new NoneElement(this));
  return res;
}

base::scoped_refptr<WrapperElement>
ElementManager::CreateFiberWrapperElement() {
  auto res = base::AdoptRef<WrapperElement>(new WrapperElement(this));
  return res;
}

void ElementManager::OnPatchFinishForFiber(const PipelineOptions &options,
                                           FiberElement *element) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager::OnPatchFinishInner");
  if (element == nullptr) {
    element = static_cast<FiberElement *>(root());
  }

  if (!element) {
    LOGE(
        "ElementManager::OnPatchFinishForFiber failed since element is "
        "nullptr");
    return;
  }

  if (options.is_first_screen) {
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::SETUP_DISPATCH_START);
  } else if (!options.timing_flag.empty()) {
    painting_context()->MarkUIOperationQueueFlushTiming(
        tasm::TimingKey::UPDATE_UI_OPERATION_FLUSH_START, options.timing_flag);
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_DISPATCH_START);
  }

  bool need_layout = element->FlushActionsAsRoot();

  if (options.is_first_screen) {
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::SETUP_DISPATCH_END);
  } else if (!options.timing_flag.empty()) {
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_DISPATCH_END);
  }
  catalyzer_->painting_context()->FinishTasmOperation(options);

  // if flush_option do not need layout or options do not need layout, skip
  // layout.
  if (!need_layout || !options.trigger_layout_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY,
                "ElementManager::OnPatchFinishForFiberNoPatch");
    LOGI("ElementManager::OnPatchFinishForFiber NoPatch!");
    catalyzer_->painting_context()->FinishLayoutOperation(options);
    delegate_->OnUpdateDataWithoutChange();
  } else {
    LOGI("ElementManager::OnPatchFinishForFiber WithPatch!");
    {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementManager sort z-index");
      // sort z-index children
      for (const auto &context : dirty_stacking_contexts_) {
        context->UpdateZIndexList();
      }
    }
    dirty_stacking_contexts_.clear();
    RequestLayout(options);
  }

  DidPatchFinishForFiber();
}

void ElementManager::ResolveStyleForFiber(FiberElement *holder,
                                          CSSFragment *style_sheet,
                                          StyleMap &styles) {
  css_patch_->GetCSSStyleForFiber(holder, style_sheet, styles);
  css_var_handler_.HandleCSSVariables(styles, holder->data_model(),
                                      GetCSSParserConfigs());
}

int32_t ElementManager::GenerateElementID() { return element_id_++; }

void ElementManager::RecordComponent(const std::string &id, Element *node) {
  if (component_manager_) {
    component_manager_->Record(id, node);
  }
}

void ElementManager::EraseComponentRecord(const std::string &id,
                                          Element *node) {
  if (component_manager_) {
    component_manager_->Erase(id, node);
  }
}

Element *ElementManager::GetComponent(const std::string &id) {
  if (id.empty() || id == PAGE_ID) {
    if (fiber_page_) {
      return fiber_page_.Get();
    }
  }
  if (component_manager_) {
    return component_manager_->Get(id);
  }
  return nullptr;
}
}  // namespace tasm
}  // namespace lynx
