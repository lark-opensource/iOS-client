// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_CSS_PATCHING_H_
#define LYNX_TASM_CSS_PATCHING_H_

#include <string>
#include <unordered_map>
#include <vector>

#include "base/base_export.h"
#include "css/css_fragment.h"
#include "css/css_selector_constants.h"
#include "lepus/value-inl.h"
#include "tasm/attribute_holder.h"

namespace lynx {
namespace tasm {
class FiberElement;

class CSSPatching {
 public:
  CSSPatching() = default;
  ~CSSPatching() = default;

  void GetCSSStyle(AttributeHolder* node, StyleMap& result);
  void GetCSSStyleCompatible(AttributeHolder* node, StyleMap& result,
                             CSSFragment* style_sheet);
  void GetCSSStyleNew(AttributeHolder* node, StyleMap& result,
                      CSSFragment* style_sheet);
  void GetCachedCSSStyle(AttributeHolder* node, StyleMap& result);
  void GetUpdatedCSSStyle(AttributeHolder* node, StyleMap& result);
  bool HasPseudoCSSStyle(AttributeHolder* node);
  static std::string MergeCSSSelector(const std::string& lhs,
                                      const std::string& rhs);
  static std::string GetClassSelectorRule(const lepus::String& clazz);
  BASE_EXPORT_FOR_DEVTOOL static std::vector<css::MatchedRule>
  GetCSSMatchedRule(AttributeHolder* node, CSSFragment* style_sheet);

  // for fiber
  void GetCSSStyleForFiber(FiberElement* node, CSSFragment* style_sheet,
                           StyleMap& result);

 private:
  static void MergeHigherPriorityCSSStyle(StyleMap& primary,
                                          const StyleMap& higher);
  static void SetCSSVariableToNode(AttributeHolder* holder,
                                   const CSSVariableMap& variables);

  static void MergeCSSStyleAndApplyCSSVariable(StyleMap& primary,
                                               CSSParseToken* token,
                                               AttributeHolder* node);

  static void GetCSSByRule(CSSSheet::SheetType type, CSSFragment* style_sheet,
                           AttributeHolder* node, const std::string& rule,
                           StyleMap& result);
  static void ApplyCascadeStyles(CSSFragment* style_sheet,
                                 AttributeHolder* node, const std::string& rule,
                                 StyleMap& attrs_map);
  static void ApplyCascadeStylesForFiber(CSSFragment* style_sheet,
                                         FiberElement* node,
                                         const std::string& rule,
                                         StyleMap& attrs_map);
  static void MergeHigherCascadeStyles(const std::string& current_selector,
                                       const std::string& parent_selector,
                                       StyleMap& attrs_map,
                                       AttributeHolder* node,
                                       CSSFragment* style_sheet);
  static void MergeHigherCascadeStylesForFiber(
      const std::string& current_selector, const std::string& parent_selector,
      StyleMap& attrs_map, AttributeHolder* node, CSSFragment* style_sheet);
  void PreSetGlobalPseudoNotCSS(
      CSSSheet::SheetType type, const std::string& rule, StyleMap& result,
      const std::unordered_map<int, PseudoClassStyleMap>&
          pseudo_not_global_array,
      CSSFragment* style_sheet, AttributeHolder* node);
  void ApplyPseudoNotCSSStyle(AttributeHolder* node,
                              const PseudoClassStyleMap& pseudo_not_map,
                              StyleMap& result, CSSFragment* style_sheet,
                              const std::string& selector);

  void ApplyPseudoClassChildSelectorStyle(AttributeHolder* node,
                                          StyleMap& result,
                                          CSSFragment* style_sheet,
                                          const std::string& selector_key);
  CSSFragment* page_style_sheet_ = nullptr;

  //  static std::pair<std::string, StyleMap> GetIDCSSStyle(AttributeHolder*
  //  node);
  //  static std::vector<std::pair<std::string, StyleMap> >
  //  GetClassCSSStyle(AttributeHolder* node);
  //  static std::pair<std::string, StyleMap> GetTagCSSStyle(AttributeHolder*
  //  node);

  enum class PseudoClassType { kFocus, kHover, kActive };

  const StyleMap GetPseudoClassStyle(PseudoClassType pseudo_type,
                                     CSSFragment* style_sheet,
                                     AttributeHolder* node);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_CSS_PATCHING_H_
