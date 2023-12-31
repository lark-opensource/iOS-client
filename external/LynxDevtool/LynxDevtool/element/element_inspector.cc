// Copyright 2022 The Lynx Authors. All rights reserved.

#include "element/element_inspector.h"

#include "base/any.h"
#include "css/css_decoder.h"
#include "css/css_property.h"
#include "inspector/style_sheet.h"
#include "inspector_css_helper.h"
#include "lepus/json_parser.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/radon/node_selector.h"
#include "tasm/radon/radon_base.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_node.h"
#include "tasm/react/fiber/component_element.h"
#include "tasm/react/fiber/fiber_element.h"

using lynx::base::any;
using lynx::lepus::String;
using lynx::lepus::Value;
using lynx::tasm::AttributeHolder;
using lynx::tasm::BaseComponent;
using lynx::tasm::CSSProperty;
using lynx::tasm::CSSVariableMap;
using lynx::tasm::RadonBase;
using lynx::tasm::RadonComponent;
using lynx::tasm::RadonNode;
using lynx::tasm::RadonSlot;
using lynx::tasm::StyleMap;

namespace lynxdev {
namespace devtool {

namespace {

// Compare keyframes name order
// For exmaple:
//@keyframes identifier {
//  0% {
//    top: 0;
//  }
//  30% {
//    top: 50px;
//  100% {
//    top: 100px;
//  }
//}
// from = 0%  to = 100%

bool CompareKeyframesNameOrder(std::string str_lhs, std::string str_rhs) {
  if (str_lhs == "from")
    return true;
  else if (str_rhs == "from")
    return false;
  str_lhs = str_lhs.substr(0, str_lhs.find("%"));
  str_rhs = str_rhs.substr(0, str_rhs.find("%"));
  double num_lhs = std::atof(str_lhs.c_str());
  double num_rhs = std::atof(str_rhs.c_str());
  return num_lhs < num_rhs;
}

std::unordered_map<InspectorElementType, InspectorNodeType>&
GetInspectorElementTypeNodeMap() {
  static lynx::base::NoDestructor<
      std::unordered_map<InspectorElementType, InspectorNodeType>>
      s_inspector_element_type_node_map{
          {{InspectorElementType::STYLE, InspectorNodeType::ElementNode},
           {InspectorElementType::STYLEVALUE, InspectorNodeType::kTextNode},
           {InspectorElementType::ELEMENT, InspectorNodeType::ElementNode},
           {InspectorElementType::COMPONENT, InspectorNodeType::ElementNode},
           {InspectorElementType::DOCUMENT, InspectorNodeType::kDocumentNode},
           {InspectorElementType::SHADOWROOT,
            InspectorNodeType::kDocumentFragmentNode},
           {InspectorElementType::SLOT, InspectorNodeType::ElementNode}}};
  return *s_inspector_element_type_node_map;
}

std::unordered_map<std::string, InspectorElementType>&
GetInspectorTagElementTypeMap() {
  static lynx::base::NoDestructor<
      std::unordered_map<std::string, InspectorElementType>>
      s_inspector_tag_element_type_map{
          {{"doc", InspectorElementType::DOCUMENT},
           {"page", InspectorElementType::COMPONENT},
           {"component", InspectorElementType::COMPONENT},
           {"style", InspectorElementType::STYLE},
           {"stylevalue", InspectorElementType::STYLEVALUE},
           {"shadow_root", InspectorElementType::SHADOWROOT},
           {"slot", InspectorElementType::SLOT}}};
  return *s_inspector_tag_element_type_map;
}

}  // namespace

void ElementInspector::SetDocElement(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* doc = std::get<1>(tuple);
  element->inspector_attribute_->doc_ = std::unique_ptr<Element>(doc);
}

void ElementInspector::SetStyleElement(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* style = std::get<1>(tuple);
  element->inspector_attribute_->style_ = std::unique_ptr<Element>(style);
}

void ElementInspector::SetStyleValueElement(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* style_value = std::get<1>(tuple);
  element->inspector_attribute_->style_value_ =
      std::unique_ptr<Element>(style_value);
}

void ElementInspector::SetShadowRootElement(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* shadow_root = std::get<1>(tuple);
  element->inspector_attribute_->shadow_root_ =
      std::unique_ptr<Element>(shadow_root);
}

void ElementInspector::SetSlotElement(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* slot = std::get<1>(tuple);
  element->inspector_attribute_->slot_ = std::unique_ptr<Element>(slot);
}

void ElementInspector::SetPlugElement(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* plug = std::get<1>(tuple);
  element->inspector_attribute_->plug_ = plug;
  element->inspector_attribute_->plug_id = NodeId(plug);
}

void ElementInspector::SetSlotComponentElement(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* component = std::get<1>(tuple);
  element->inspector_attribute_->slot_component_ = component;
}

void ElementInspector::InsertPlug(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* slot_plug = std::get<1>(tuple);
  element->inspector_attribute_->slot_plug_.push_back(slot_plug);
}

void ElementInspector::ErasePlug(Element* element, Element* plug) {
  for (auto iter = element->inspector_attribute_->slot_plug_.begin();
       iter != element->inspector_attribute_->slot_plug_.end(); iter++) {
    if (*iter == plug) {
      element->inspector_attribute_->slot_plug_.erase(iter);
      break;
    }
  }
}

bool ElementInspector::HasDataModel(Element* element) {
  return element->data_model() != nullptr;
}

void ElementInspector::InitForInspector(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*>>(data);
  Element* element = std::get<0>(tuple);
  element->inspector_attribute_ =
      std::make_unique<lynx::tasm::InspectorAttribute>();
  InitTypeForInspector(element);
  switch (element->inspector_attribute_->type_) {
    case InspectorElementType::DOCUMENT: {
      InitDocumentElement(element);
      break;
    }
    case InspectorElementType::COMPONENT: {
      InitComponentElement(element);
      break;
    }
    case InspectorElementType::SHADOWROOT: {
      InitShadowRootElement(element);
      break;
    }
    case InspectorElementType::STYLE: {
      InitStyleElement(element);
      break;
    }
    case InspectorElementType::STYLEVALUE: {
      break;
    }
    case InspectorElementType::SLOT: {
      break;
    }
    default: {
      InitNormalElement(element);
      break;
    }
  }
  InitInlineStyleSheetForInspector(element);
  InitIdForInspector(element);
  InitClassForInspector(element);
  InitAttrForInspector(element);
  InitDataSetForInspector(element);
  InitEventMapForInspector(element);

  InitStyleRoot(data);
}

void ElementInspector::InitTypeForInspector(Element* element) {
  std::string tag = element->GetTag();
  if (GetInspectorTagElementTypeMap().find(tag) !=
      GetInspectorTagElementTypeMap().end()) {
    element->inspector_attribute_->type_ = GetInspectorTagElementTypeMap()[tag];
  } else {
    element->inspector_attribute_->type_ = InspectorElementType::ELEMENT;
  }
}

void ElementInspector::InitInlineStyleSheetForInspector(Element* element) {
  if (HasDataModel(element)) {
    std::string name = "inline" + lynx::lepus::to_string(element->impl_id());
    intptr_t ptr = reinterpret_cast<intptr_t>(element->data_model());
    element->inspector_attribute_->inline_style_sheet_ = InitStyleSheet(
        element, 0, name, GetInlineStylesFromAttributeHolder(element, ptr));
  }
}

void ElementInspector::InitIdForInspector(Element* element) {
  if (HasDataModel(element)) {
    intptr_t ptr = reinterpret_cast<intptr_t>(element->data_model());
    element->inspector_attribute_->selector_id_ =
        GetSelectorIDFromAttributeHolder(element, ptr);
  }
}

void ElementInspector::InitClassForInspector(Element* element) {
  if (HasDataModel(element)) {
    intptr_t ptr = reinterpret_cast<intptr_t>(element->data_model());
    element->inspector_attribute_->class_order_ =
        GetClassOrderFromAttributeHolder(element, ptr);
  }
}

void ElementInspector::InitAttrForInspector(Element* element) {
  if (HasDataModel(element)) {
    intptr_t ptr = reinterpret_cast<intptr_t>(element->data_model());
    auto res = GetAttrFromAttributeHolder(element, ptr);
    element->inspector_attribute_->attr_order_ = res.first;
    element->inspector_attribute_->attr_map_ = res.second;
  }
}

void ElementInspector::InitDataSetForInspector(Element* element) {
  if (HasDataModel(element)) {
    intptr_t ptr = reinterpret_cast<intptr_t>(element->data_model());
    auto res = GetDataSetFromAttributeHolder(element, ptr);
    element->inspector_attribute_->data_order_ = res.first;
    element->inspector_attribute_->data_map_ = res.second;
  }
}

void ElementInspector::InitEventMapForInspector(Element* element) {
  if (HasDataModel(element)) {
    intptr_t ptr = reinterpret_cast<intptr_t>(element->data_model());
    auto res = GetEventMapFromAttributeHolder(element, ptr);
    element->inspector_attribute_->event_order_ = res.first;
    element->inspector_attribute_->event_map_ = res.second;
  }
}

void ElementInspector::InitDocumentElement(Element* element) {
  element->inspector_attribute_->local_name_ = "";
  element->inspector_attribute_->node_name_ = "#document";
  element->inspector_attribute_->node_type_ = static_cast<int>(
      GetInspectorElementTypeNodeMap()[element->inspector_attribute_->type_]);
  element->inspector_attribute_->node_value_ = "";
}

void ElementInspector::InitComponentElement(Element* element) {
  std::string local_name;
  if (element->GetTag() == "page") {
    local_name = "page";
  } else {
    local_name = GetComponentName(element);
  }

  element->inspector_attribute_->local_name_ = local_name;
  std::transform(local_name.begin(), local_name.end(), local_name.begin(),
                 ::toupper);
  element->inspector_attribute_->node_name_ = local_name;
  element->inspector_attribute_->node_type_ = static_cast<int>(
      GetInspectorElementTypeNodeMap()[element->inspector_attribute_->type_]);
  element->inspector_attribute_->node_value_ = "";
}

void ElementInspector::InitShadowRootElement(Element* element) {
  element->inspector_attribute_->local_name_ = "";
  element->inspector_attribute_->node_name_ = "#document-fragment";
  element->inspector_attribute_->node_type_ = static_cast<int>(
      GetInspectorElementTypeNodeMap()[element->inspector_attribute_->type_]);
  element->inspector_attribute_->node_value_ = "";
  element->inspector_attribute_->shadow_root_type_ = "open";
}

void ElementInspector::InitStyleElement(Element* element) {
  element->inspector_attribute_->local_name_ = "style";
  element->inspector_attribute_->node_name_ = "STYLE";
  element->inspector_attribute_->node_type_ = static_cast<int>(
      GetInspectorElementTypeNodeMap()[element->inspector_attribute_->type_]);
  element->inspector_attribute_->node_value_ = "";
}

void ElementInspector::InitStyleValueElement(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* root_node = std::get<1>(tuple);
  element->inspector_attribute_->local_name_ = "";
  element->inspector_attribute_->node_name_ = "STYLEVALUE";
  element->inspector_attribute_->node_type_ = static_cast<int>(
      GetInspectorElementTypeNodeMap()[element->inspector_attribute_->type_]);
  element->inspector_attribute_->node_value_ = "";
  element->inspector_attribute_->start_line_ = 1;
  element->inspector_attribute_->node_value_ += "\n";

  auto* style_sheet = GetElementCSSFragment(root_node);
  if (!style_sheet) return;
  element->inspector_attribute_->has_cascaded_style_ =
      style_sheet->HasCascadeStyle();
  element->inspector_attribute_->enable_css_selector_ =
      style_sheet->enable_css_selector();
}

void ElementInspector::InitSlotElement(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* slot_plug = std::get<1>(tuple);
  element->inspector_attribute_->local_name_ = "slot";
  element->inspector_attribute_->node_name_ = "SLOT";
  element->inspector_attribute_->node_type_ = static_cast<int>(
      GetInspectorElementTypeNodeMap()[element->inspector_attribute_->type_]);
  element->inspector_attribute_->node_value_ = "";
  element->inspector_attribute_->slot_name_ = GetVirtualSlotName(slot_plug);
  element->inspector_attribute_->attr_order_.push_back("name");
  element->inspector_attribute_->attr_map_["name"] =
      element->inspector_attribute_->slot_name_;
}

void ElementInspector::InitNormalElement(Element* element) {
  std::string local_name = element->GetTag();
  element->inspector_attribute_->local_name_ = local_name;
  std::transform(local_name.begin(), local_name.end(), local_name.begin(),
                 ::toupper);
  element->inspector_attribute_->node_name_ = local_name;
  element->inspector_attribute_->node_type_ = static_cast<int>(
      GetInspectorElementTypeNodeMap()[element->inspector_attribute_->type_]);
  element->inspector_attribute_->node_value_ = "";
}

lynxdev::devtool::InspectorStyleSheet ElementInspector::InitStyleSheet(
    Element* element, int start_line, std::string name,
    std::unordered_map<std::string, std::string> styles) {
  InspectorStyleSheet res;
  res.empty = false;
  res.style_name_ = name;
  res.origin_ = "regular";
  res.style_sheet_id_ = lynx::lepus::to_string(element->impl_id());
  res.style_name_range_.start_line_ = start_line;
  res.style_name_range_.end_line_ = start_line;
  res.style_name_range_.start_column_ = 0;

  int property_start_column;
  if (lynx::base::BeginsWith(name, "inline")) {
    res.style_name_range_.end_column_ = 0;
    property_start_column = 0;
  } else {
    res.style_name_range_.end_column_ =
        static_cast<int>(res.style_name_.size());
    property_start_column = res.style_name_range_.end_column_ + 1;
  }
  res.style_value_range_.start_line_ = start_line;
  res.style_value_range_.end_line_ = start_line;
  res.style_value_range_.start_column_ = property_start_column;

  std::unordered_multimap<std::string, lynxdev::devtool::CSSPropertyDetail>
      temp_map;
  lynxdev::devtool::CSSPropertyDetail temp_css_property;
  std::string css_text;
  for (const auto& style : styles) {
    temp_css_property.name_ = style.first;
    temp_css_property.value_ = style.second;
    temp_css_property.text_ = style.first + ":" + style.second + ";";
    css_text += temp_css_property.text_;
    temp_css_property.disabled_ = false;
    temp_css_property.implicit_ = false;
    temp_css_property.parsed_ok_ = true;
    temp_css_property.property_range_.start_line_ = start_line;
    temp_css_property.property_range_.end_line_ = start_line;
    temp_css_property.property_range_.start_column_ = property_start_column;
    temp_css_property.property_range_.end_column_ =
        property_start_column +
        static_cast<int>(temp_css_property.text_.size());
    property_start_column = temp_css_property.property_range_.end_column_;
    temp_map.insert(std::make_pair(style.first, temp_css_property));
    res.property_order_.push_back(style.first);
  }

  res.css_text_ = css_text;
  res.style_value_range_.end_column_ = property_start_column;
  res.css_properties_ = temp_map;
  return res;
}

Element* ElementInspector::GetParentComponentElementFromDataModel(
    Element* element) {
  // Get Element's parent, if the parent is component/page, return the parent.
  // Otherwise, return nullptr.
  if (element->is_fiber_element()) {
    auto parent = element->parent();
    if (parent &&
        static_cast<lynx::tasm::FiberElement*>(parent)->is_component()) {
      return parent;
    }
    return nullptr;
  } else {
    auto* attribute_holder = element->data_model();
    if (attribute_holder) {  // radon node
      RadonNode* node = static_cast<RadonNode*>(attribute_holder);
      if (node->Parent() &&
          node->Parent()->NodeType() == lynx::tasm::kRadonComponent) {
        return node->Parent()->element();
      } else {
        return nullptr;
      }
    }
    return nullptr;
  }
}

Element* ElementInspector::GetParentElementForComponentRemoveView(
    Element* element) {
  auto* attribute_holder = element->data_model();
  RadonNode* component_node = static_cast<RadonNode*>(attribute_holder);
  RadonNode* component_child =
      static_cast<RadonNode*>(component_node->radon_children_[0].get());
  if (component_child && component_child->element()) {
    return component_child->element()->parent();
  } else {
    return nullptr;
  }
}

Element* ElementInspector::GetChildElementForComponentRemoveView(
    Element* element) {
  auto* attribute_holder = element->data_model();
  RadonNode* component_node = static_cast<RadonNode*>(attribute_holder);
  RadonNode* component_child =
      static_cast<RadonNode*>(component_node->radon_children_[0].get());
  if (component_child && component_child->element()) {
    return component_child->element();
  } else {
    return nullptr;
  }
}

void ElementInspector::Flush(Element* element) {
  if (HasDataModel(element)) {  // slot element doesn't set datamodel
    for (const auto& name : element->inspector_attribute_->attr_order_) {
      std::string value = element->inspector_attribute_->attr_map_.at(name);
      auto local_value = Value(lynx::lepus::ValueType::Value_String);
      local_value.SetString(lynx::lepus::StringImpl::Create(value));
      element->SetAttribute(name, local_value);
    }

    std::vector<lynx::tasm::CSSPropertyID> reset_names;
    const auto& compute_style_map = CSSProperty::GetComputeStyleMap();
    reset_names.reserve(compute_style_map.size());
    for (const auto& pair : compute_style_map) {
      if (!pair.first.empty()) {
        auto id = CSSProperty::GetPropertyID(pair.first);
        if (!CSSProperty::IsShorthand(id)) {
          reset_names.push_back(id);
        }
      }
    }
    element->ResetStyle(reset_names);
    if (element->GetTag() == "page") {
      element->element_manager()->SetRootOnLayout(element->layout_node());
    }
    element->element_manager()->OnFinishUpdateProps(element);

    if (ElementInspector::IsEnableCSSSelector(element)) {
      const std::vector<InspectorStyleSheet>& match_rules =
          GetMatchedStyleSheet(element);
      for (const auto& style : match_rules) {
        SetPropsAccordingToStyleSheet(element, style);
      }
    } else {
      SetPropsAccordingToStyleSheet(element, GetStyleSheetByName(element, "*"));
      SetPropsAccordingToStyleSheet(
          element, GetStyleSheetByName(element, SelectorTag(element)));
      for (const auto& name : element->inspector_attribute_->class_order_) {
        SetPropsAccordingToStyleSheet(element,
                                      GetStyleSheetByName(element, name));
        SetPropsForCascadedStyleSheet(element, name);
      }
      if (!SelectorId(element).empty()) {
        SetPropsAccordingToStyleSheet(
            element, GetStyleSheetByName(element, SelectorId(element)));
        SetPropsForCascadedStyleSheet(element, SelectorId(element));
      }
    }

    SetPropsAccordingToStyleSheet(element, GetInlineStyleSheet(element));

    // Need to call OnPatchFinish() since some css styles will be updated there
    // e.g. margin calculation may rely on font-size configuration
    element->element_manager()->OnFinishUpdateProps(element);
    lynx::tasm::PipelineOptions options;
    element->element_manager()->OnPatchFinish(options);
  }
}

void ElementInspector::InitStyleRoot(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*>>(data);
  Element* element = std::get<0>(tuple);
  if (element->GetTag() == "page") {
    return;
  }
  if (HasDataModel(element)) {
    auto comp = element->GetParentComponentElement();
    if (comp != nullptr && Type(comp) == InspectorElementType::COMPONENT &&
        ShadowRootElement(comp) != nullptr &&
        StyleElement(ShadowRootElement(comp)) != nullptr) {
      element->inspector_attribute_->style_root_ =
          StyleValueElement(StyleElement(ShadowRootElement(comp)));
    }
  }
}

void ElementInspector::SetStyleRoot(const any& data) {
  auto tuple = lynx::base::any_cast<std::tuple<Element*, Element*>>(data);
  Element* element = std::get<0>(tuple);
  Element* style_root = std::get<1>(tuple);
  element->inspector_attribute_->style_root_ = style_root;
}

std::unordered_map<std::string, std::string> ElementInspector::GetCssByStyleMap(
    Element* element, const StyleMap& style_map) {
  std::unordered_map<std::string, std::string> res;
  for (const auto& pair : style_map) {
    const auto name = InspectorCSSHelper::GetPropertyName(pair.first);

    if (pair.second.GetValueType() == lynx::tasm::CSSValueType::VARIABLE) {
      Value value_expr = pair.second.GetValue();
      String property = pair.second.GetDefaultValue();
      if (value_expr.IsString()) {
        lynx::tasm::CSSVariableHandler handler;
        property = handler.FormatStringWithRule(
            value_expr.String()->c_str(), element->data_model(), property);
      }
      lynx::tasm::CSSValue modified_value(Value(property.impl()),
                                          pair.second.GetPattern());
      res[name] =
          lynx::tasm::CSSDecoder::CSSValueToString(pair.first, modified_value);
    } else {
      res[name] =
          lynx::tasm::CSSDecoder::CSSValueToString(pair.first, pair.second);
    }
  }
  return res;
}

std::unordered_map<std::string, std::string>
ElementInspector::GetCssVariableByMap(const CSSVariableMap& style_variables) {
  std::unordered_map<std::string, std::string> res;
  for (const auto& pair : style_variables) {
    res[pair.first.str()] = pair.second.str();
  }
  return res;
}

std::unordered_map<std::string, std::string> ElementInspector::GetCSSByName(
    Element* element, std::string name) {
  std::unordered_map<std::string, std::string> res;
  auto* style_sheet =
      GetElementCSSFragment(element->GetParentComponentElement());
  if (!style_sheet) return res;
  auto* css = style_sheet->GetCSSStyle(name);
  return GetCSSByParseToken(element, css);
}

std::unordered_map<std::string, std::string>
ElementInspector::GetCSSByParseToken(Element* element,
                                     lynx::tasm::CSSParseToken* token) {
  std::unordered_map<std::string, std::string> res;
  if (!token) {
    return res;
  }
  const StyleMap& style_map = token->GetAttribute();
  res = GetCssByStyleMap(element, style_map);
  const CSSVariableMap& css_variable_map = token->GetStyleVariables();
  std::unordered_map<std::string, std::string> css_variable =
      GetCssVariableByMap(css_variable_map);
  res.insert(css_variable.begin(), css_variable.end());
  return res;
}

std::vector<lynxdev::devtool::InspectorStyleSheet>
ElementInspector::GetMatchedStyleSheet(Element* element) {
  std::vector<lynxdev::devtool::InspectorStyleSheet> res;
  auto* attribute_holder = element->data_model();
  if (!attribute_holder) return res;
  lynx::tasm::CSSFragment* style_sheet =
      GetElementCSSFragment(element->GetParentComponentElement());
  if (!style_sheet) return res;
  auto* style_root = element->inspector_attribute_->style_root_;
  std::vector<lynx::css::MatchedRule> matched_rules =
      lynx::tasm::CSSPatching::GetCSSMatchedRule(attribute_holder, style_sheet);
  for (const auto& matched : matched_rules) {
    if (matched.Data()->Rule()->Token() != nullptr) {
      std::string name = matched.Data()->Selector().ToString();
      if (style_root != nullptr) {
        auto map = GetStyleSheetMap(style_root);
        if (map.find(name) != map.end()) {
          res.push_back(map.at(name));
        } else {
          std::unordered_map<std::string, std::string> css = GetCSSByParseToken(
              element, matched.Data()->Rule()->Token().get());
          if (!css.empty()) {
            lynxdev::devtool::InspectorStyleSheet style_sheet = InitStyleSheet(
                style_root, style_root->inspector_attribute_->start_line_++,
                name, css);
            res.push_back(style_sheet);
            style_root->inspector_attribute_->style_sheet_order_.push_back(
                name);
            style_root->inspector_attribute_->style_sheet_map_[name] =
                style_sheet;
            style_root->inspector_attribute_->node_value_ =
                style_root->inspector_attribute_->node_value_ + name + "{" +
                style_root->inspector_attribute_->style_sheet_map_[name]
                    .css_text_ +
                "}\n";
          }
        }
      }
    }
  }
  return res;
}

lynxdev::devtool::LynxDoubleMapString ElementInspector::GetAnimationByName(
    Element* element, std::string name) {
  LynxDoubleMapString res;
  auto* style_sheet =
      GetElementCSSFragment(element->GetParentComponentElement());
  if (!style_sheet) return res;
  const auto& animation_map = style_sheet->keyframes();
  auto animation_item = animation_map.find(name);
  if (animation_item == animation_map.end()) return res;
  auto animation = animation_item->second;
  for (const auto& style : animation->GetKeyframes()) {
    std::unordered_map<std::string, std::string> keyframe;
    for (const auto& pair : *(style.second)) {
      const auto name = InspectorCSSHelper::GetPropertyName(pair.first);
      keyframe[name] =
          lynx::tasm::CSSDecoder::CSSValueToString(pair.first, pair.second);
    }
    res[std::to_string(style.first)] = keyframe;
  }
  return res;
}

lynxdev::devtool::InspectorStyleSheet ElementInspector::GetStyleSheetByName(
    Element* element, const std::string& name) {
  InspectorStyleSheet res;
  auto* style_root = element->inspector_attribute_->style_root_;
  if (style_root != nullptr) {
    auto map = GetStyleSheetMap(style_root);
    if (map.find(name) != map.end()) {
      res = map.at(name);
    } else {
      std::unordered_map<std::string, std::string> css =
          GetCSSByName(element, name);
      if (!css.empty()) {
        res = InitStyleSheet(style_root,
                             style_root->inspector_attribute_->start_line_++,
                             name, css);
        style_root->inspector_attribute_->style_sheet_order_.push_back(name);
        style_root->inspector_attribute_->style_sheet_map_[name] = res;
        style_root->inspector_attribute_->node_value_ =
            style_root->inspector_attribute_->node_value_ + name + "{" +
            style_root->inspector_attribute_->style_sheet_map_[name].css_text_ +
            "}\n";
      }
    }
  }
  return res;
}

std::vector<lynxdev::devtool::InspectorKeyframe>
ElementInspector::GetAnimationKeyframeByName(Element* element,
                                             const std::string& name) {
  std::vector<lynxdev::devtool::InspectorKeyframe> res;
  auto* style_root = element->inspector_attribute_->style_root_;
  if (style_root != nullptr) {
    auto animation_map = GetAnimationMap(style_root);
    if (animation_map.find(name) != animation_map.end()) {
      res = animation_map.at(name);
    } else {
      LynxDoubleMapString animation = GetAnimationByName(element, name);
      if (!animation.empty()) {
        std::vector<std::string> keyframe_names;
        for (auto pair : animation) {
          keyframe_names.push_back(pair.first);
        }
        std::sort(keyframe_names.begin(), keyframe_names.end(),
                  CompareKeyframesNameOrder);
        style_root->inspector_attribute_->node_value_ +=
            "@keyframes " + name + "{\n";
        style_root->inspector_attribute_->start_line_++;
        for (const auto& keyframe_name : keyframe_names) {
          InspectorKeyframe frame;
          frame.key_text_ = keyframe_name;
          frame.style_ = InitStyleSheet(
              style_root, style_root->inspector_attribute_->start_line_++,
              keyframe_name, animation[keyframe_name]);
          if (style_root->inspector_attribute_->animation_map_.find(name) ==
              style_root->inspector_attribute_->animation_map_.end()) {
            std::vector<InspectorKeyframe> frame_vec;
            frame_vec.push_back(frame);
            style_root->inspector_attribute_->animation_map_[name] = frame_vec;
          } else
            style_root->inspector_attribute_->animation_map_[name].push_back(
                frame);
          style_root->inspector_attribute_->node_value_ +=
              frame.key_text_ + "{" + frame.style_.css_text_ + "}\n";
        }
        style_root->inspector_attribute_->node_value_ += "}\n";
      }
      res = style_root->inspector_attribute_->animation_map_[name];
    }
  }
  return res;
}

std::string ElementInspector::GetVirtualSlotName(Element* slot_plug) {
  if (slot_plug->is_fiber_element()) {
    constexpr const static char* kSlot = "slot";
    constexpr const static char* kDefaultName = "default";

    // In fiber mode, lepus runtime will set slot name as a attribute to the
    // elment, which's key is "slot". Then we can get slot name from the pulg
    // element's attributes. If the attributes does not contain "slot", then
    // return kDefaultName.
    const auto& attr_map = slot_plug->data_model()->attributes();
    auto iter = attr_map.find(kSlot);
    if (iter != attr_map.end()) {
      return iter->second.first.String()->str();
    }
    return kDefaultName;
  }

  auto* attribute_holder = slot_plug->data_model();
  // find radon slot
  auto* current =
      static_cast<RadonBase*>(static_cast<RadonNode*>(attribute_holder));
  auto* parent = current->Parent();
  while (parent) {
    if (parent->NodeType() == lynx::tasm::kRadonSlot) {
      break;
    } else {
      parent = parent->Parent();
    }
  }

  auto* node = static_cast<RadonSlot*>(parent);
  return node->name().str();
}

std::string ElementInspector::GetComponentName(Element* element) {
  if (element->is_fiber_element()) {
    return static_cast<lynx::tasm::ComponentElement*>(element)
        ->component_name()
        .str();
  } else {
    auto attribute_holder = element->data_model();
    auto virtual_component = static_cast<RadonComponent*>(attribute_holder);
    return virtual_component->name().str();
  }
}

Element* ElementInspector::GetElementByID(Element* element, int id) {
  return element->element_manager()->node_manager()->Get(id);
}

lynx::tasm::CSSFragment* ElementInspector::GetElementCSSFragment(
    Element* element) {
  // If element is component/page, return its CSSFragment. Otherwise, return
  // nullptr.
  lynx::tasm::CSSFragment* style_sheet = nullptr;
  if (element->is_fiber_element()) {
    auto* fiber_element = static_cast<lynx::tasm::FiberElement*>(element);
    if (fiber_element->is_component()) {
      auto* component_element =
          static_cast<lynx::tasm::ComponentElement*>(fiber_element);
      return component_element->GetCSSFragment();
    }
  } else {
    AttributeHolder* attribute_holder;
    if (element->GetTag() == "page" && element->GetPageElementEnabled()) {
      attribute_holder =
          static_cast<RadonNode*>(element->data_model())->component();
    } else {
      attribute_holder = element->data_model();
    }

    if (attribute_holder) {
      style_sheet = attribute_holder->GetStyleSheet();
    }
  }
  return style_sheet;
}

std::string ElementInspector::GetComponentProperties(Element* element) {
  std::string res = "";
  auto* attribute_holder = element->data_model();
  auto* node = static_cast<RadonNode*>(attribute_holder);
  if (node->IsRadonComponent() || node->IsRadonPage()) {
    std::ostringstream s;
    static_cast<RadonComponent*>(node)->properties().PrintValue(s, false, true);
    res = s.str();
  }
  return res;
}

std::string ElementInspector::GetComponentData(Element* element) {
  std::string res = "";
  auto* attribute_holder = element->data_model();
  auto* node = static_cast<RadonNode*>(attribute_holder);
  if (node->IsRadonComponent() || node->IsRadonPage()) {
    std::ostringstream s;
    static_cast<RadonComponent*>(node)->data().PrintValue(s, false, true);
    res = s.str();
  }
  return res;
}

int ElementInspector::GetComponentId(Element* element) {
  int res = -1;
  auto* attribute_holder = element->data_model();
  auto* node = static_cast<RadonNode*>(attribute_holder);
  if (node->IsRadonComponent() || node->IsRadonPage()) {
    res = static_cast<BaseComponent*>(static_cast<RadonComponent*>(node))
              ->ComponentId();
  }
  return res;
}

std::string ElementInspector::GetLayoutTree(Element* element) {
  return element->GetLayoutTree();
}

std::unordered_map<std::string, std::string>
ElementInspector::GetInlineStylesFromAttributeHolder(Element* element,
                                                     intptr_t ptr) {
  std::unordered_map<std::string, std::string> res;
  if (ptr == kElementPtr) {
    auto& order =
        element->inspector_attribute_->inline_style_sheet_.property_order_;
    auto& map =
        element->inspector_attribute_->inline_style_sheet_.css_properties_;
    for (auto& iter : order) {
      res[iter] = map.find(iter)->second.value_;
    }
  } else {
    auto* node = reinterpret_cast<AttributeHolder*>(ptr);
    if (node == nullptr) return res;
    const StyleMap& inline_style = node->inline_styles();
    res = GetCssByStyleMap(element, inline_style);
  }
  return res;
}

std::string ElementInspector::GetSelectorIDFromAttributeHolder(Element* element,
                                                               intptr_t ptr) {
  if (ptr == kElementPtr) {
    return element->inspector_attribute_->selector_id_;
  } else {
    auto* node = reinterpret_cast<AttributeHolder*>(ptr);
    if (node == nullptr) return "";
    if (node->idSelector().str().empty()) {
      return "";
    } else {
      return "#" + node->idSelector().str();
    }
  }
}

std::vector<std::string> ElementInspector::GetClassOrderFromAttributeHolder(
    Element* element, intptr_t ptr) {
  if (ptr == kElementPtr) {
    return element->inspector_attribute_->class_order_;
  } else {
    auto* node = reinterpret_cast<AttributeHolder*>(ptr);
    std::vector<std::string> res;
    if (node == nullptr) return res;
    const auto& classes = node->classes();
    for (const auto& c : classes) {
      res.push_back("." + c.str());
    }
    return res;
  }
}

lynxdev::devtool::LynxAttributePair
ElementInspector::GetAttrFromAttributeHolder(Element* element, intptr_t ptr) {
  if (ptr == kElementPtr) {
    return std::make_pair(element->inspector_attribute_->attr_order_,
                          element->inspector_attribute_->attr_map_);
  } else {
    auto* node = reinterpret_cast<AttributeHolder*>(ptr);
    if (node == nullptr)
      return std::make_pair(std::vector<std::string>(),
                            std::unordered_map<std::string, std::string>());
    const auto& attr = node->attributes();
    std::vector<std::string> order;
    std::unordered_map<std::string, std::string> map;
    for (const auto& pair : attr) {
      const auto name = pair.first.str();
      std::string value = std::string();
      if (pair.second.first.IsNumber()) {
        std::ostringstream stm;
        stm << pair.second.first.Number();
        value += stm.str();
      } else {
        value += pair.second.first.String()->str();
      }
      order.push_back(name);
      map[name] = value;
    }
    return std::make_pair(order, map);
  }
}
lynxdev::devtool::LynxAttributePair
ElementInspector::GetDataSetFromAttributeHolder(Element* element,
                                                intptr_t ptr) {
  if (ptr == kElementPtr) {
    return std::make_pair(element->inspector_attribute_->data_order_,
                          element->inspector_attribute_->data_map_);
  } else {
    auto* node = reinterpret_cast<AttributeHolder*>(ptr);
    if (node == nullptr)
      return std::make_pair(std::vector<std::string>(),
                            std::unordered_map<std::string, std::string>());
    const auto& data = node->dataset();
    std::vector<std::string> order;
    std::unordered_map<std::string, std::string> map;
    for (const auto& pair : data) {
      constexpr const static char* kPrefix = "data-";
      const auto name = kPrefix + pair.first.str();
      std::string value = std::string();
      if (pair.second.IsNumber()) {
        std::ostringstream stm;
        stm << pair.second.Number();
        value += stm.str();
      } else {
        value += pair.second.String()->str();
      }
      order.push_back(name);
      map[name] = value;
    }
    return std::make_pair(order, map);
  }
}

lynxdev::devtool::LynxAttributePair
ElementInspector::GetEventMapFromAttributeHolder(Element* element,
                                                 intptr_t ptr) {
  if (ptr == kElementPtr) {
    return std::make_pair(element->inspector_attribute_->event_order_,
                          element->inspector_attribute_->event_map_);
  } else {
    auto* node = reinterpret_cast<AttributeHolder*>(ptr);
    if (node == nullptr)
      return std::make_pair(std::vector<std::string>(),
                            std::unordered_map<std::string, std::string>());
    std::vector<std::string> order;
    std::unordered_map<std::string, std::string> map;
    const auto& event = node->static_events();
    const auto& global_event = node->global_bind_events();
    for (const auto& pair : event) {
      auto name = pair.first.str();
      if (pair.second->type().str() == "bindEvent") {
        name = "bind" + name;
      } else if (pair.second->type().str() == "catchEvent") {
        name = "catch" + name;
      } else if (pair.second->type().str() == "capture-bindEvent") {
        name = "capture-bind" + name;
      } else if (pair.second->type().str() == "capture-catchEvent") {
        name = "capture-catch" + name;
      } else {
        name = pair.second->type().str() + name;
      }
      const auto value = pair.second->function().str() +
                         pair.second->lepus_function().ToString();
      order.push_back(name);
      map[name] = value;
    }
    for (const auto& pair : global_event) {
      auto name = "global-bind" + pair.first.str();
      const auto value = pair.second->function().str() +
                         pair.second->lepus_function().ToString();
      order.push_back(name);
      map[name] = value;
    }
    return std::make_pair(order, map);
  }
}

void ElementInspector::SetPropsAccordingToStyleSheet(
    Element* element,
    const lynxdev::devtool::InspectorStyleSheet& style_sheet) {
  StyleMap styles;
  auto configs = element->element_manager()->GetCSSParserConfigs();
  styles.reserve(style_sheet.css_properties_.size());
  for (const auto& pair : style_sheet.css_properties_) {
    if (pair.second.parsed_ok_ && !pair.second.disabled_) {
      auto id = CSSProperty::GetPropertyID(pair.second.name_);
      lynx::tasm::UnitHandler::Process(id, Value(pair.second.value_.c_str()),
                                       styles, configs);
    }
  }
  element->SetStyle(styles);
}

void ElementInspector::SetPropsForCascadedStyleSheet(Element* element,
                                                     const std::string& rule) {
  if (IsStyleRootHasCascadeStyle(element)) {
    Element* parent = element->parent();
    while (parent) {
      for (const auto& parent_name : ClassOrder(parent)) {
        auto style_sheet = GetStyleSheetByName(element, rule + parent_name);
        if (!style_sheet.empty) {
          SetPropsAccordingToStyleSheet(element, style_sheet);
        }
      }
      parent = parent->parent();
    }

    parent = element->parent();
    while (parent) {
      if (!SelectorId(parent).empty()) {
        auto style_sheet =
            GetStyleSheetByName(element, rule + SelectorId(parent));
        if (!style_sheet.empty) {
          SetPropsAccordingToStyleSheet(element, style_sheet);
        }
      }
      parent = parent->parent();
    }
  }
}

void ElementInspector::AdjustStyleSheet(Element* element) {
  int start_line = element->inspector_attribute_->inline_style_sheet_
                       .style_name_range_.start_line_;
  int property_start_column = 0;

  element->inspector_attribute_->inline_style_sheet_.style_value_range_
      .start_line_ = start_line;
  element->inspector_attribute_->inline_style_sheet_.style_value_range_
      .end_line_ = start_line;
  element->inspector_attribute_->inline_style_sheet_.style_value_range_
      .start_column_ = property_start_column;

  auto& map =
      element->inspector_attribute_->inline_style_sheet_.css_properties_;
  std::string css_text;
  for (auto& item : map) item.second.looped_ = false;
  for (const auto& style :
       element->inspector_attribute_->inline_style_sheet_.property_order_) {
    auto iter_range = map.equal_range(style);
    for (auto it = iter_range.first; it != iter_range.second; ++it) {
      auto& cur_value = it->second;
      if (cur_value.looped_) continue;
      cur_value.looped_ = true;
      cur_value.text_ = cur_value.name_ + ":" + cur_value.value_ + ";";
      css_text += cur_value.text_;
      cur_value.disabled_ = false;
      cur_value.implicit_ = false;
      cur_value.parsed_ok_ = true;
      cur_value.property_range_.start_line_ = start_line;
      cur_value.property_range_.end_line_ = start_line;
      cur_value.property_range_.start_column_ = property_start_column;
      cur_value.property_range_.end_column_ =
          property_start_column + static_cast<int>(cur_value.text_.size());
      property_start_column = cur_value.property_range_.end_column_;
      break;
    }
  }

  element->inspector_attribute_->inline_style_sheet_.css_text_ = css_text;
  element->inspector_attribute_->inline_style_sheet_.style_value_range_
      .end_column_ = property_start_column;
}

void ElementInspector::DeleteStyleFromInlineStyleSheet(
    Element* element, const std::string& name) {
  auto& order =
      element->inspector_attribute_->inline_style_sheet_.property_order_;
  auto& map =
      element->inspector_attribute_->inline_style_sheet_.css_properties_;
  for (auto iter = order.begin(); iter != order.end();) {
    if (*iter == name) {
      order.erase(iter);
    } else {
      iter++;
    }
  }
  map.erase(name);
  AdjustStyleSheet(element);
}

void ElementInspector::UpdateStyleToInlineStyleSheet(Element* element,
                                                     const std::string& name,
                                                     const std::string& value) {
  auto& order =
      element->inspector_attribute_->inline_style_sheet_.property_order_;
  auto& map =
      element->inspector_attribute_->inline_style_sheet_.css_properties_;
  auto iter_range = map.equal_range(name);
  if (iter_range.first == iter_range.second) {
    order.push_back(name);
    auto new_iter = map.insert({name, CSSPropertyDetail()});
    new_iter->second.name_ = name;
    new_iter->second.value_ = value;
  } else {
    for (auto it = iter_range.first; it != iter_range.second; ++it) {
      it->second.name_ = name;
      it->second.value_ = value;
    }
  }
  AdjustStyleSheet(element);
}

void ElementInspector::DeleteStyle(Element* element, const std::string& name) {
  DeleteStyleFromInlineStyleSheet(element, name);
}

void ElementInspector::UpdateStyle(Element* element, const std::string& name,
                                   const std::string& value) {
  UpdateStyleToInlineStyleSheet(element, name, value);
}

void ElementInspector::DeleteAttr(Element* element, const std::string& name) {
  if (element->inspector_attribute_->attr_map_.find(name) !=
      element->inspector_attribute_->attr_map_.end()) {
    element->inspector_attribute_->attr_map_.erase(name);
    for (auto iter = element->inspector_attribute_->attr_order_.begin();
         iter != element->inspector_attribute_->attr_order_.end(); ++iter) {
      if (*iter == name) {
        element->inspector_attribute_->attr_order_.erase(iter);
        break;
      }
    }
  }
}

void ElementInspector::UpdateAttr(Element* element, const std::string& name,
                                  const std::string& value) {
  if (element->inspector_attribute_->attr_map_.find(name) ==
      element->inspector_attribute_->attr_map_.end()) {
    element->inspector_attribute_->attr_order_.push_back(name);
  }
  element->inspector_attribute_->attr_map_[name] = value;
}

void ElementInspector::DeleteClasses(Element* element) {
  element->inspector_attribute_->class_order_.clear();
}
void ElementInspector::UpdateClasses(Element* element,
                                     const std::vector<std::string> classes) {
  element->inspector_attribute_->class_order_ = classes;
}

void ElementInspector::SetStyleSheetByName(
    Element* element, const std::string& name,
    const lynxdev::devtool::InspectorStyleSheet& style_sheet) {
  if (StyleRoot(element) != nullptr) {
    std::unordered_map<std::string, InspectorStyleSheet>& map =
        GetStyleSheetMap(StyleRoot(element));
    if (map.find(name) != map.end()) {
      map.at(name) = style_sheet;
    }
  }
}

bool ElementInspector::IsStyleRootHasCascadeStyle(Element* element) {
  if (element->inspector_attribute_->style_root_) {
    auto* style_root = element->inspector_attribute_->style_root_;
    return style_root->inspector_attribute_->has_cascaded_style_;
  }
  return false;
}

bool ElementInspector::IsEnableCSSSelector(Element* element) {
  if (element->inspector_attribute_->style_root_) {
    auto* style_root = element->inspector_attribute_->style_root_;
    return style_root->inspector_attribute_->enable_css_selector_;
  }
  return false;
}

double ElementInspector::GetDeviceDensity() {
  return lynx::tasm::Config::Density();
}

std::unordered_map<std::string, std::string> ElementInspector::GetDefaultCss() {
  return CSSProperty::GetComputeStyleMap();
}

std::vector<double> ElementInspector::GetOverlayNGBoxModel(Element* element) {
  std::vector<double> res;

  auto size = element->GetCaCatalyzer()->getWindowSize(element);
  res.push_back(size[0]);
  res.push_back(size[1]);

  // content/padding/border/margin box is the same
  // left_top  right_top  right_bottom  left_bottom  coordinate is :
  //  0   0 res[0](w) 0  res[0] res[1](h) 0 res[1]
  for (int i = 0; i < 4; i++) {
    res.push_back(0);
    res.push_back(0);
    res.push_back(res[0]);
    res.push_back(0);
    res.push_back(res[0]);
    res.push_back(res[1]);
    res.push_back(0);
    res.push_back(res[1]);
  }
  return res;
}

std::vector<double> ElementInspector::GetBoxModel(Element* element) {
  // x-overlay-ng node won't participate in layout, view size in android is 0
  // and won't apply any css attribute so all box model is the same
  // return window size and boxmodel directly
  if (element->GetTag() == "x-overlay-ng") {
    return GetOverlayNGBoxModel(element);
  }

  std::vector<double> res;
  if (element->is_virtual()) {
    auto temp_parent = element->parent();
    while (temp_parent && temp_parent->is_virtual()) {
      temp_parent = temp_parent->parent();
    }
    if (temp_parent) {
      res = GetBoxModel(temp_parent);
    }
  } else if ((element->CanBeLayoutOnly() &&
              element->layout_node()->slnode() != nullptr) ||
             !element->CanBeLayoutOnly()) {
    auto layout_obj = element->layout_node()->slnode();
    res.push_back(layout_obj->GetBorderBoundWidth() -
                  layout_obj->GetLayoutPaddingLeft() -
                  layout_obj->GetLayoutPaddingRight() -
                  layout_obj->GetLayoutBorderLeftWidth() -
                  layout_obj->GetLayoutBorderRightWidth());
    res.push_back(layout_obj->GetBorderBoundHeight() -
                  layout_obj->GetLayoutPaddingTop() -
                  layout_obj->GetLayoutPaddingBottom() -
                  layout_obj->GetLayoutBorderTopWidth() -
                  layout_obj->GetLayoutBorderBottomWidth());

    std::vector<float> pad_border_margin_layout = {
        layout_obj->GetLayoutPaddingLeft(),
        layout_obj->GetLayoutPaddingTop(),
        layout_obj->GetLayoutPaddingRight(),
        layout_obj->GetLayoutPaddingBottom(),
        layout_obj->GetLayoutBorderLeftWidth(),
        layout_obj->GetLayoutBorderTopWidth(),
        layout_obj->GetLayoutBorderRightWidth(),
        layout_obj->GetLayoutBorderBottomWidth(),
        layout_obj->GetLayoutMarginLeft(),
        layout_obj->GetLayoutMarginTop(),
        layout_obj->GetLayoutMarginRight(),
        layout_obj->GetLayoutMarginBottom(),
        0,
        0,
        0,
        0};
    std::vector<float> trans;
    if (element->CanBeLayoutOnly()) {
      auto current = element;
      float layout_only_x = 0;
      float layout_only_y = 0;
      while (current != nullptr && current->CanBeLayoutOnly()) {
        layout_only_x += current->layout_node()
                             ->slnode()
                             ->GetBorderBoundLeftFromParentPaddingBound();
        layout_only_y += current->layout_node()
                             ->slnode()
                             ->GetBorderBoundTopFromParentPaddingBound();
        current = current->parent();
      }
      if (current != nullptr) {
        layout_only_x +=
            current->layout_node()->slnode()->GetLayoutBorderLeftWidth();
        layout_only_y +=
            current->layout_node()->slnode()->GetLayoutBorderTopWidth();
        pad_border_margin_layout[12] = layout_only_x;
        pad_border_margin_layout[13] = layout_only_y;
        pad_border_margin_layout[14] =
            current->layout_node()->slnode()->GetBorderBoundWidth() -
            layout_only_x - layout_obj->GetBorderBoundWidth();
        pad_border_margin_layout[15] =
            current->layout_node()->slnode()->GetBorderBoundHeight() -
            layout_only_y - layout_obj->GetBorderBoundHeight();
        trans = element->GetCaCatalyzer()->getTransformValue(
            current, pad_border_margin_layout);
      }
    } else {
      trans = element->GetCaCatalyzer()->getTransformValue(
          element, pad_border_margin_layout);
    }
    for (float t : trans) {
      res.push_back(t);
    }
    return res;
  }
  return res;
}

std::vector<float> ElementInspector::GetRectToWindow(Element* element) {
  return element->GetCaCatalyzer()->GetRectToWindow(element);
}

int ElementInspector::GetCurrentIndex(Element* element) {
  return element->GetCaCatalyzer()->GetCurrentIndex(element);
}

bool ElementInspector::IsViewVisible(Element* element) {
  return element->GetCaCatalyzer()->IsViewVisible(element);
}

std::vector<int> ElementInspector::getVisibleOverlayView(Element* element) {
  return element->GetCaCatalyzer()->getVisibleOverlayView();
}

std::vector<Element*> ElementInspector::SelectElementAll(
    Element* element, const std::string& selector) {
  std::vector<Element*> res;
  if (element->is_fiber_element()) {
    return res;
  } else {
    auto attribute_holder = element->data_model();
    if (attribute_holder) {
      auto* radon_node = static_cast<RadonNode*>(attribute_holder);
      lynx::tasm::NodeSelectOptions options(
          lynx::tasm::NodeSelectOptions::IdentifierType::CSS_SELECTOR,
          selector);
      options.first_only = false;
      options.only_current_component = false;
      auto nodes =
          lynx::tasm::RadonNodeSelector::Select(radon_node, options).nodes;
      if (!nodes.empty()) {
        for (RadonNode* node : nodes) {
          res.push_back(node->element());
        }
      }
    }
  }
  return res;
}

int ElementInspector::GetNodeForLocation(Element* element, int x, int y) {
  return element->GetCaCatalyzer()->GetNodeForLocation(x, y);
}

void ElementInspector::ScrollIntoView(Element* element) {
  Element* current_element = element;
  if (current_element->is_virtual() || current_element->CanBeLayoutOnly()) {
    Element* current_element = element->parent();
    while (current_element != nullptr && (current_element->is_virtual() ||
                                          current_element->CanBeLayoutOnly())) {
      current_element = current_element->parent();
    }
  }
  if (current_element == nullptr) return;
  current_element->GetCaCatalyzer()->ScrollIntoView(current_element);
}

}  // namespace devtool
}  // namespace lynxdev
