// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_HELPER_ELEMENT_INSPECTOR_H_
#define LYNX_INSPECTOR_HELPER_ELEMENT_INSPECTOR_H_

#include <tuple>

#include "base/any.h"
#include "tasm/css_patching.h"
#include "tasm/react/element.h"

using lynx::tasm::Element;

namespace lynx {
namespace tasm {

class CSSFragment;

}
}  // namespace lynx

namespace lynxdev {
namespace devtool {

class ElementInspector {
 public:
  static int NodeId(Element* element) { return element->impl_id(); }
  static int NodeType(Element* element) {
    return element->inspector_attribute_->node_type_;
  }
  static std::string LocalName(Element* element) {
    return element->inspector_attribute_->local_name_;
  }
  static std::string NodeName(Element* element) {
    return element->inspector_attribute_->node_name_;
  }
  static std::string NodeValue(Element* element) {
    return element->inspector_attribute_->node_value_;
  }
  static std::string SelectorId(Element* element) {
    return element->inspector_attribute_->selector_id_;
  }
  static std::string SelectorTag(Element* element) { return element->GetTag(); }
  static std::vector<std::string> ClassOrder(Element* element) {
    return element->inspector_attribute_->class_order_;
  }
  static lynxdev::devtool::InspectorElementType Type(Element* element) {
    return element->inspector_attribute_->type_;
  }
  static std::string ShadowRootType(Element* element) {
    return element->inspector_attribute_->shadow_root_type_;
  }
  static std::string SlotName(Element* element) {
    return element->inspector_attribute_->slot_name_;
  }
  static std::vector<std::string>& AttrOrder(Element* element) {
    return element->inspector_attribute_->attr_order_;
  }
  static std::unordered_map<std::string, std::string>& AttrMap(
      Element* element) {
    return element->inspector_attribute_->attr_map_;
  }
  static std::vector<std::string>& DataOrder(Element* element) {
    return element->inspector_attribute_->data_order_;
  }
  static std::unordered_map<std::string, std::string>& DataMap(
      Element* element) {
    return element->inspector_attribute_->data_map_;
  }
  static std::vector<std::string>& EventOrder(Element* element) {
    return element->inspector_attribute_->event_order_;
  }
  static std::unordered_map<std::string, std::string> EvenMap(
      Element* element) {
    return element->inspector_attribute_->event_map_;
  }
  static Element* StyleRoot(Element* element) {
    return element->inspector_attribute_->style_root_;
  }
  static lynxdev::devtool::InspectorStyleSheet& GetInlineStyleSheet(
      Element* element) {
    return element->inspector_attribute_->inline_style_sheet_;
  }
  static std::vector<lynxdev::devtool::InspectorCSSRule>& GetCssRules(
      Element* element) {
    return element->inspector_attribute_->css_rules_;
  }
  static const std::vector<std::string>& GetStyleSheetOrder(Element* element) {
    return element->inspector_attribute_->style_sheet_order_;
  }
  static std::unordered_map<std::string, lynxdev::devtool::InspectorStyleSheet>&
  GetStyleSheetMap(Element* element) {
    return element->inspector_attribute_->style_sheet_map_;
  }
  static const std::unordered_map<
      std::string, std::vector<lynxdev::devtool::InspectorKeyframe>>&
  GetAnimationMap(Element* element) {
    return element->inspector_attribute_->animation_map_;
  }
  static std::unordered_set<std::string>& GetStyleSheetIdSet() {
    static std::unordered_set<std::string> style_sheet_id_set_;
    return style_sheet_id_set_;
  }
  static void SetInlineStyleSheet(
      Element* element, const lynxdev::devtool::InspectorStyleSheet& style) {
    element->inspector_attribute_->inline_style_sheet_ = style;
  }
  static void SetClassOrder(Element* element,
                            const std::vector<std::string>& class_order) {
    element->inspector_attribute_->class_order_ = class_order;
  }
  static void SetSelectorId(Element* element, const std::string& selector_id) {
    element->inspector_attribute_->selector_id_ = selector_id;
  }
  static void SetAttrOrder(Element* element,
                           const std::vector<std::string>& attr_order) {
    element->inspector_attribute_->attr_order_ = attr_order;
  }
  static void SetAttrMap(
      Element* element,
      std::unordered_map<std::string, std::string>& attr_map) {
    element->inspector_attribute_->attr_map_ = attr_map;
  }
  static void SetDataOrder(Element* element,
                           const std::vector<std::string>& data_order) {
    element->inspector_attribute_->data_order_ = data_order;
  }
  static void SetDataMap(
      Element* element,
      std::unordered_map<std::string, std::string>& data_map) {
    element->inspector_attribute_->data_map_ = data_map;
  }
  static void SetEventOrder(Element* element,
                            const std::vector<std::string>& event_order) {
    element->inspector_attribute_->event_order_ = event_order;
  }
  static void SetEventMap(
      Element* element,
      std::unordered_map<std::string, std::string>& event_map) {
    element->inspector_attribute_->event_map_ = event_map;
  }
  static void SetSlotName(Element* element, const std::string& name) {
    element->inspector_attribute_->slot_name_ = name;
  }
  static Element* DocElement(Element* element) {
    return element->inspector_attribute_->doc_.get();
  }
  static Element* StyleElement(Element* element) {
    return element->inspector_attribute_->style_.get();
  }
  static Element* StyleValueElement(Element* element) {
    return element->inspector_attribute_->style_value_.get();
  }
  static Element* ShadowRootElement(Element* element) {
    return element->inspector_attribute_->shadow_root_.get();
  }
  static Element* PlugElement(Element* element) {
    return element->inspector_attribute_->plug_;
  }
  static Element* SlotComponentElement(Element* element) {
    return element->inspector_attribute_->slot_component_;
  }
  static Element* SlotElement(Element* element) {
    return element->inspector_attribute_->slot_.get();
  }
  static std::vector<Element*> SlotPlug(Element* element) {
    return element->inspector_attribute_->slot_plug_;
  }
  static void SetDocElement(const lynx::base::any& data);
  static void SetStyleElement(const lynx::base::any& data);
  static void SetStyleValueElement(const lynx::base::any& data);
  static void SetShadowRootElement(const lynx::base::any& data);
  static void SetSlotElement(const lynx::base::any& data);
  static void SetPlugElement(const lynx::base::any& data);
  static void SetSlotComponentElement(const lynx::base::any& data);
  static void InsertPlug(const lynx::base::any& data);
  static bool IsNeedEraseId(Element* element) {
    return element->inspector_attribute_->needs_erase_id_;
  }
  static void SetIsNeedEraseId(Element* element, bool needs_erase_id) {
    element->inspector_attribute_->needs_erase_id_ = needs_erase_id;
  }

  static void ErasePlug(Element* element, Element* plug);
  static bool HasDataModel(Element* element);

  static void InitForInspector(const lynx::base::any& data);
  static void InitTypeForInspector(Element* element);
  static void InitInlineStyleSheetForInspector(Element* element);
  static void InitIdForInspector(Element* element);
  static void InitClassForInspector(Element* element);
  static void InitAttrForInspector(Element* element);
  static void InitDataSetForInspector(Element* element);
  static void InitEventMapForInspector(Element* element);

  static void InitDocumentElement(Element* element);
  static void InitComponentElement(Element* element);
  static void InitShadowRootElement(Element* element);
  static void InitStyleElement(Element* element);
  static void InitStyleValueElement(const lynx::base::any& data);
  static void InitSlotElement(const lynx::base::any& data);
  static void InitNormalElement(Element* element);

  static lynxdev::devtool::InspectorStyleSheet InitStyleSheet(
      Element* element, int start_line, std::string name,
      std::unordered_map<std::string, std::string> styles);

  static Element* GetParentComponentElementFromDataModel(Element* element);
  static Element* GetParentElementForComponentRemoveView(Element* element);
  static Element* GetChildElementForComponentRemoveView(Element* element);

  static void Flush(Element* element);
  static void InitStyleRoot(const lynx::base::any& data);
  static void SetStyleRoot(const lynx::base::any& data);

  static std::unordered_map<std::string, std::string> GetCssByStyleMap(
      Element* element, const lynx::tasm::StyleMap& style_map);
  static std::unordered_map<std::string, std::string> GetCssVariableByMap(
      const lynx::tasm::CSSVariableMap& style_variables);
  static std::unordered_map<std::string, std::string> GetCSSByName(
      Element* element, std::string name);
  static std::unordered_map<std::string, std::string> GetCSSByParseToken(
      Element* element, lynx::tasm::CSSParseToken* token);
  static std::vector<lynxdev::devtool::InspectorStyleSheet>
  GetMatchedStyleSheet(Element* element);
  static lynxdev::devtool::LynxDoubleMapString GetAnimationByName(
      Element* element, std::string name);
  static lynxdev::devtool::InspectorStyleSheet GetStyleSheetByName(
      Element* element, const std::string& name);
  static std::vector<lynxdev::devtool::InspectorKeyframe>
  GetAnimationKeyframeByName(Element* element, const std::string& name);

  static std::string GetVirtualSlotName(Element* slot_plug);
  static std::string GetComponentName(Element* element);
  static Element* GetElementByID(Element* element, int id);

  /**
   * Helper function to get Element's corresponding CSSFragment. If element is
   * not component/page, return nullptr.
   * @param element component's element
   */
  static lynx::tasm::CSSFragment* GetElementCSSFragment(Element* element);

  static std::string GetComponentProperties(Element* element);
  static std::string GetComponentData(Element* element);
  static int GetComponentId(Element* element);
  static std::string GetLayoutTree(Element* element);

  static std::unordered_map<std::string, std::string>
  GetInlineStylesFromAttributeHolder(Element* element, intptr_t ptr);
  static std::string GetSelectorIDFromAttributeHolder(Element* element,
                                                      intptr_t ptr);
  static std::vector<std::string> GetClassOrderFromAttributeHolder(
      Element* element, intptr_t ptr);
  static lynxdev::devtool::LynxAttributePair GetAttrFromAttributeHolder(
      Element* element, intptr_t ptr);
  static lynxdev::devtool::LynxAttributePair GetDataSetFromAttributeHolder(
      Element* element, intptr_t ptr);
  static lynxdev::devtool::LynxAttributePair GetEventMapFromAttributeHolder(
      Element* element, intptr_t ptr);

  static void SetPropsAccordingToStyleSheet(
      Element* element,
      const lynxdev::devtool::InspectorStyleSheet& style_sheet);
  static void SetPropsForCascadedStyleSheet(Element* element,
                                            const std::string& rule);
  static void AdjustStyleSheet(Element* element);
  static void DeleteStyleFromInlineStyleSheet(Element* element,
                                              const std::string& name);
  static void UpdateStyleToInlineStyleSheet(Element* element,
                                            const std::string& name,
                                            const std::string& value);
  static void DeleteStyle(Element* element, const std::string& name);
  static void UpdateStyle(Element* element, const std::string& name,
                          const std::string& value);
  static void DeleteAttr(Element* element, const std::string& name);
  static void UpdateAttr(Element* element, const std::string& name,
                         const std::string& value);
  static void DeleteClasses(Element* element);
  static void UpdateClasses(Element* element,
                            const std::vector<std::string> classes);
  static void SetStyleSheetByName(
      Element* element, const std::string& name,
      const lynxdev::devtool::InspectorStyleSheet& style_sheet);
  static bool IsStyleRootHasCascadeStyle(Element* element);
  static bool IsEnableCSSSelector(Element* element);
  static double GetDeviceDensity();
  static std::unordered_map<std::string, std::string> GetDefaultCss();
  static std::vector<double> GetBoxModel(Element* element);
  static std::vector<double> GetOverlayNGBoxModel(Element* element);
  static std::vector<float> GetRectToWindow(Element* element);
  static std::vector<int> getVisibleOverlayView(Element* element);
  static int GetCurrentIndex(Element* element);
  static bool IsViewVisible(Element* element);

  static std::vector<Element*> SelectElementAll(Element* element,
                                                const std::string& selector);

  static int GetNodeForLocation(Element* element, int x, int y);
  static void ScrollIntoView(Element* element);
};

}  // namespace devtool
}  // namespace lynxdev

#endif
