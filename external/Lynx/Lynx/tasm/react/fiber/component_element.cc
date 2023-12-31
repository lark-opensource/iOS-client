// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/component_element.h"

#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

constexpr const static char* kComponentTag = "component";
constexpr const static char* kRootCSSId = ":root";

ComponentElement::ComponentElement(ElementManager* manager,
                                   const lepus::String& component_id,
                                   int32_t component_css_id,
                                   const lepus::String& entry_name,
                                   const lepus::String& name,
                                   const lepus::String& path)
    : ComponentElement(manager, component_id, component_css_id, entry_name,
                       name, path, kComponentTag) {}
ComponentElement::ComponentElement(ElementManager* manager,
                                   const lepus::String& component_id,
                                   int32_t component_css_id,
                                   const lepus::String& entry_name,
                                   const lepus::String& name,
                                   const lepus::String& path,
                                   const lepus::String& tag_name)
    : FiberElement(manager, tag_name),
      component_id_(component_id),
      component_css_id_(component_css_id),
      entry_name_(entry_name),
      name_(name),
      path_(path) {
  manager->RecordComponent(component_id.str(), this);
  SetDefaultOverflow(element_manager_->GetDefaultOverflowVisible());
  MarkCanBeLayoutOnly(true);
}

ComponentElement::~ComponentElement() {
  if (!will_destroy_) {
    element_manager()->EraseComponentRecord(component_id().str(), this);
  }
}

CSSFragment* ComponentElement::GetCSSFragment() {
  if (!style_sheet_) {
    if (!fragment_ && css_style_sheet_manager_) {
      fragment_ = css_style_sheet_manager_->GetCSSStyleSheetForComponent(
          component_css_id_);
    }
    style_sheet_ = std::make_shared<CSSFragmentDecorator>(fragment_);
    // for css variable in `:root` css
    PrepareForRootCSSVariables();
  }
  return style_sheet_.get();
}

void ComponentElement::PrepareForRootCSSVariables() {
  auto* rule_set = style_sheet_->rule_set();
  if (rule_set) {
    const auto& root_css_token = rule_set->GetRootToken();
    if (root_css_token) {
      UpdateRootCSSVariables(data_model(), root_css_token);
    }
    return;
  }
  auto root_css = style_sheet_->css().find(kRootCSSId);
  if (root_css != style_sheet_->css().end()) {
    UpdateRootCSSVariables(data_model(), root_css->second);
  }
}

void ComponentElement::UpdateRootCSSVariables(
    AttributeHolder* holder, const std::shared_ptr<CSSParseToken>& root_token) {
  auto style_variables = root_token->GetStyleVariables();
  if (style_variables.empty()) {
    return;
  }

  for (const auto& pair : style_variables) {
    data_model()->UpdateCSSVariable(pair.first, pair.second);
  }
}

void ComponentElement::set_component_id(const lepus::String& id) {
  // In fiber mode, the component id of component element may be updated by
  // lepus runtime. If component_element_1 is updated from id1 to id2,
  // component_element_2 is updated from id2 to id1 in one data process. Then
  // according to the previous logic, delete id1 <-> component_element_1, insert
  // id2 <-> component_element_1, delete id2 <-> component_element_1, insert id1
  // <-> component_element_2. Eventually component_element_1 could not be
  // recorded. In order to solve this problem, a verification is performed
  // during the deletion operation. If the component element corresponding to
  // the deleted id is inconsistent with the current element, the deletion
  // operation will not be performed.

  element_manager()->EraseComponentRecord(component_id().str(), this);
  component_id_ = id;
  element_manager()->RecordComponent(component_id().str(), this);
}
}  // namespace tasm
}  // namespace lynx
