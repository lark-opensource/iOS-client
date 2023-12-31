// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/css_patching.h"

#include <algorithm>
#include <utility>
#include <vector>

#include "base/algorithm.h"
#include "base/log/logging.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "css/css_sheet.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/radon/radon_node.h"
#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {

void CSSPatching::MergeHigherPriorityCSSStyle(StyleMap& primary,
                                              const StyleMap& higher) {
  for (const auto& it : higher) {
    primary[it.first] = it.second;
  }
}

void CSSPatching::SetCSSVariableToNode(AttributeHolder* holder,
                                       const CSSVariableMap& variables) {
  for (const auto& it : variables) {
    holder->UpdateCSSVariable(it.first, it.second);
  }
}

void CSSPatching::MergeCSSStyleAndApplyCSSVariable(StyleMap& primary,
                                                   CSSParseToken* token,
                                                   AttributeHolder* node) {
  MergeHigherPriorityCSSStyle(primary, token->GetAttribute());
  SetCSSVariableToNode(node, token->GetStyleVariables());
}

void CSSPatching::GetCSSStyleCompatible(AttributeHolder* node, StyleMap& result,
                                        CSSFragment* style_sheet) {
  // absort the selector styles in :not(), then store the correspond selector
  // and scope the InitPseudoNotStyle function only judge once
  style_sheet->InitPseudoNotStyle();
  // If has_pseudo_not_style means the pseudo_not_style is not empty
  const bool has_pseudo_not_style = style_sheet->HasPseudoNotStyle();

  StyleMap value;
  GetCSSByRule(CSSSheet::ALL_SELECT, style_sheet, node, "*", value);
  MergeHigherPriorityCSSStyle(result, value);

  // first, handle the tag selector
  const lepus::String& tag_node = node->tag();
  if (!tag_node.empty()) {
    std::string rule_tag_selector = tag_node.str();
    if (has_pseudo_not_style) {
      PreSetGlobalPseudoNotCSS(
          CSSSheet::NAME_SELECT, rule_tag_selector, result,
          style_sheet->pseudo_not_style().pseudo_not_global_map, style_sheet,
          node);
    }

    value.clear();
    GetCSSByRule(CSSSheet::NAME_SELECT, style_sheet, node, rule_tag_selector,
                 value);
    MergeHigherPriorityCSSStyle(result, value);
    if (has_pseudo_not_style) {
      ApplyPseudoNotCSSStyle(node,
                             style_sheet->pseudo_not_style().pseudo_not_for_tag,
                             result, style_sheet, rule_tag_selector);
    }
    ApplyPseudoClassChildSelectorStyle(node, result, style_sheet,
                                       rule_tag_selector);
  }
  // Class selector
  if (has_pseudo_not_style) {
    // if the node doesnt contains andy class selectors，then apply the class
    // selectors from global :not() selector
    PreSetGlobalPseudoNotCSS(
        CSSSheet::CLASS_SELECT, "", result,
        style_sheet->pseudo_not_style().pseudo_not_global_map, style_sheet,
        node);
  }

  for (const auto& cls : node->classes()) {
    const auto rule_class_selector = GetClassSelectorRule(cls);
    value.clear();
    GetCSSByRule(CSSSheet::CLASS_SELECT, style_sheet, node, rule_class_selector,
                 value);
    MergeHigherPriorityCSSStyle(result, value);
    if (has_pseudo_not_style) {
      ApplyPseudoNotCSSStyle(
          node, style_sheet->pseudo_not_style().pseudo_not_for_class, result,
          style_sheet, rule_class_selector);
    }
    ApplyPseudoClassChildSelectorStyle(node, result, style_sheet,
                                       rule_class_selector);
  }

  if (node->HasPseudoState(kPseudoStateFocus)) {
    MergeHigherPriorityCSSStyle(
        result,
        GetPseudoClassStyle(PseudoClassType::kFocus, style_sheet, node));
  }

  if (node->HasPseudoState(kPseudoStateHover)) {
    MergeHigherPriorityCSSStyle(
        result,
        GetPseudoClassStyle(PseudoClassType::kHover, style_sheet, node));
  }

  if (node->HasPseudoState(kPseudoStateActive)) {
    MergeHigherPriorityCSSStyle(
        result,
        GetPseudoClassStyle(PseudoClassType::kActive, style_sheet, node));
  }

  // ID selector
  const lepus::String& id_node = node->idSelector();
  if (!id_node.empty()) {
    const std::string rule_id_selector = std::string("#") + id_node.c_str();
    if (has_pseudo_not_style) {
      PreSetGlobalPseudoNotCSS(
          CSSSheet::ID_SELECT, rule_id_selector, result,
          style_sheet->pseudo_not_style().pseudo_not_global_map, style_sheet,
          node);
    }
    value.clear();
    GetCSSByRule(CSSSheet::ID_SELECT, style_sheet, node, rule_id_selector,
                 value);
    MergeHigherPriorityCSSStyle(result, value);
    if (has_pseudo_not_style) {
      ApplyPseudoNotCSSStyle(node,
                             style_sheet->pseudo_not_style().pseudo_not_for_id,
                             result, style_sheet, rule_id_selector);
    }
    ApplyPseudoClassChildSelectorStyle(node, result, style_sheet,
                                       rule_id_selector);
  } else if (has_pseudo_not_style) {
    // if the node doesnt contains the id selector，then try to apply the id
    // selecotr form global :not() selector
    PreSetGlobalPseudoNotCSS(
        CSSSheet::ID_SELECT, "", result,
        style_sheet->pseudo_not_style().pseudo_not_global_map, style_sheet,
        node);
  }
}

static bool CompareRules(const css::MatchedRule& matched_rule1,
                         const css::MatchedRule& matched_rule2) {
  unsigned specificity1 = matched_rule1.Specificity();
  unsigned specificity2 = matched_rule2.Specificity();
  if (specificity1 != specificity2) return specificity1 < specificity2;

  return matched_rule1.Position() < matched_rule2.Position();
}

std::vector<css::MatchedRule> CSSPatching::GetCSSMatchedRule(
    AttributeHolder* node, CSSFragment* style_sheet) {
  std::vector<css::MatchedRule> matched_rules;
  if (style_sheet && style_sheet->rule_set()) {
    unsigned level = 0;
    style_sheet->rule_set()->MatchStyles(node, level, matched_rules);
  }

  base::InsertionSort(matched_rules.data(), matched_rules.size(), CompareRules);
  return matched_rules;
}

void CSSPatching::GetCSSStyleNew(AttributeHolder* node, StyleMap& result,
                                 CSSFragment* style_sheet) {
  std::vector<css::MatchedRule> matched_rules =
      GetCSSMatchedRule(node, style_sheet);

  for (const auto& matched : matched_rules) {
    if (matched.Data()->Rule()->Token() != nullptr) {
      MergeCSSStyleAndApplyCSSVariable(
          result, matched.Data()->Rule()->Token().get(), node);
    }
  }
}

/**
  css 选择器优先级关系
  ID 选择器 > 类选择器 > 标签选择器
  :not()选择器的优先级和括号里的内容有关，详见 W3C 规范
  https://www.w3.org/TR/selectors/#specificity-rules
 */
void CSSPatching::GetCSSStyle(AttributeHolder* node, StyleMap& result) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, CSS_PATCHING_GET_STYLE);
  // raw-text was created in lynx only, while raw-text doesnt need to get css
  // style, add this judgement to avoid unnecessary function calling
  if (node == nullptr || node->tag().str() == "raw-text") {
    return;
  }

  CSSFragment* style_sheet = nullptr;
  if (node->GetCSSScopeEnabled()) {
    if (page_style_sheet_ == nullptr) {
      page_style_sheet_ = node->GetPageStyleSheet();
    }
    style_sheet = page_style_sheet_;
  } else {
    style_sheet = node->ParentStyleSheet();
  }

  if (style_sheet != nullptr) {
    if (style_sheet->enable_css_selector()) {
      GetCSSStyleNew(node, result, style_sheet);
    } else {
      GetCSSStyleCompatible(node, result, style_sheet);
    }
  }
  for (const auto& style : node->inline_styles()) {
    result[style.first] = style.second;
  }
}

void CSSPatching::GetCachedCSSStyle(AttributeHolder* node, StyleMap& result) {
  if (!node) {
    return;
  }
  const auto& cached_result = node->cached_styles();
  if (!cached_result.empty()) {
    result = cached_result;
    return;
  }
  GetCSSStyle(node, result);
  node->set_cached_styles(result);
}

// force using updated style
void CSSPatching::GetUpdatedCSSStyle(AttributeHolder* node, StyleMap& result) {
#if ENABLE_HMR
  if (!node) {
    return;
  }
  GetCSSStyle(node, result);
  node->set_cached_styles(result);
#endif
}

/**
   预设全局的 :not() 样式
 */
void CSSPatching::PreSetGlobalPseudoNotCSS(
    CSSSheet::SheetType type, const std::string& rule, StyleMap& result,
    const std::unordered_map<int, PseudoClassStyleMap>& pseudo_not_global_map,
    CSSFragment* style_sheet, AttributeHolder* node) {
  // 判断是否存在全局 :not() 样式
  if (pseudo_not_global_map.size() > 0) {
    PseudoClassStyleMap pseudo_not_global;

    auto it = pseudo_not_global_map.find(type);
    if (it != pseudo_not_global_map.end()) {
      pseudo_not_global = it->second;
    }

    const CSSParserTokenMap& pseudo = style_sheet->pseudo_map();
    for (auto& it : pseudo_not_global) {
      bool is_need_use_pseudo_not_style = false;

      if (type == CSSSheet::CLASS_SELECT) {
        const auto& class_vector = node->classes();

        if (class_vector.size() == 0) {
          // 若元素没有class，则直接preset 全局的:not()下的class选择器的内容
          is_need_use_pseudo_not_style = true;
        } else {
          // 当全局:not的范围是class时，遍历class进行查找，查看是否命中目标class
          bool is_match_class = false;
          for (const auto& cls : class_vector) {
            const auto class_name = GetClassSelectorRule(cls);
            if (class_name.compare(it.second.scope) == 0) {
              is_match_class = true;
              break;
            }
          }
          is_need_use_pseudo_not_style = !is_match_class;
        }
      } else {
        // 当全局 :not 的范围是标签 / id 选择选择器时，判断是否要应用全局 :not
        // 样式
        if (it.second.scope.compare(rule) != 0 || rule.compare("") == 0) {
          is_need_use_pseudo_not_style = true;
        }
      }

      if (is_need_use_pseudo_not_style) {
        auto it_pseudo_not = pseudo.find(it.first);
        if (it_pseudo_not != pseudo.end()) {
          MergeCSSStyleAndApplyCSSVariable(result, it_pseudo_not->second.get(),
                                           node);
        }
      }
    }
  }
}

void CSSPatching::ApplyPseudoNotCSSStyle(
    AttributeHolder* node, const PseudoClassStyleMap& pseudo_not_map,
    StyleMap& result, CSSFragment* style_sheet,
    const std::string& selector_key) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, CSS_PATCHING_APPLY_PSEUDO_STYLE);
  for (const auto& it : pseudo_not_map) {
    auto pseudo_key = it.second.selector_key;
    if (selector_key.compare(pseudo_key) == 0 ||
        (std::string(".") + selector_key).compare(pseudo_key) == 0 ||
        (std::string("#") + selector_key).compare(pseudo_key) == 0) {
      bool is_need_use_pseudo_not_style = false;
      if (it.second.scope_type == CSSSheet::NAME_SELECT) {
        if (it.second.scope.compare(node->tag().str()) != 0) {
          is_need_use_pseudo_not_style = true;
        }
      } else if (it.second.scope_type == CSSSheet::CLASS_SELECT) {
        const auto& class_vector = node->classes();
        if (class_vector.size() == 0) {
          // 当节点没有class且:not的作用范围是class选择器的时候，需要应用样式
          is_need_use_pseudo_not_style = true;
        }
        // 处理下.class1:not(.class2)的情况
        bool is_match_class = false;
        for (const auto& cls : class_vector) {
          const auto class_name = GetClassSelectorRule(cls);
          if (class_name.compare(it.second.scope) == 0 &&
              class_name.compare(pseudo_key) != 0) {
            is_match_class = true;
            break;
          }
        }

        is_need_use_pseudo_not_style = !is_match_class;
      } else if (it.second.scope_type == CSSSheet::ID_SELECT) {
        if (it.second.scope.compare("#" + node->idSelector().str()) != 0) {
          is_need_use_pseudo_not_style = true;
        }
      }

      if (is_need_use_pseudo_not_style) {
        std::string full_pseudo_key = it.first;
        auto it_pseudo_not = style_sheet->pseudo_map().find(full_pseudo_key);
        if (it_pseudo_not != style_sheet->pseudo_map().end()) {
          MergeCSSStyleAndApplyCSSVariable(result, it_pseudo_not->second.get(),
                                           node);
        }
      }
    }
  }
}

void CSSPatching::ApplyPseudoClassChildSelectorStyle(
    AttributeHolder* node, StyleMap& result, CSSFragment* style_sheet,
    const std::string& selector_key) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, CSS_PATCHING_APPLY_PSEUDO_CHILD);
  const CSSParserTokenMap& child_pseudo = style_sheet->child_pseudo_map();
  RadonNode* current_node = static_cast<RadonNode*>(node);
  if (!current_node->NodeParent()) {
    return;
  }
  for (const auto& it : child_pseudo) {
    if (it.second && it.second->IsPseudoStyleToken() &&
        it.first.compare(0, selector_key.size(), selector_key) == 0) {
      if (it.first.find(kCSSSelectorFirstChild) != std::string::npos) {
        if (current_node == current_node->NodeParent()->FirstNodeChild()) {
          MergeCSSStyleAndApplyCSSVariable(result, it.second.get(), node);
        }
      }
      if (it.first.find(kCSSSelectorLastChild) != std::string::npos) {
        if (current_node == current_node->NodeParent()->LastNodeChild()) {
          MergeCSSStyleAndApplyCSSVariable(result, it.second.get(), node);
        }
      }
    }
  }
}

bool CSSPatching::HasPseudoCSSStyle(AttributeHolder* node) {
  if (node == nullptr) {
    return false;
  }
  CSSFragment* fragment = node->ParentStyleSheet();
  return fragment && fragment->HasPseudoStyle();
}

std::string CSSPatching::MergeCSSSelector(const std::string& lhs,
                                          const std::string& rhs) {
  return lhs + rhs;
}

std::string CSSPatching::GetClassSelectorRule(const lepus::String& clazz) {
  return std::string(".") + clazz.str();
}

/*
 * 匹配算法：
 *    1. 根据key，确定是否有css特性
 *    2. 根据css sheet从右到左的顺序去匹配node节点的parent，看node
 * class是否满足条件 例如 .a .text_hello {"font-size":"10px"} css
 * style以.text_hello存在map里，先找text_hello再找node
 * parent是否为a，若满足返回css style
 *       选择器以链表的形式存在css_parse_token里面sheets_
 */
void CSSPatching::GetCSSByRule(CSSSheet::SheetType type,
                               CSSFragment* style_sheet, AttributeHolder* node,
                               const std::string& rule, StyleMap& attrs_map) {
  TRACE_EVENT(
      LYNX_TRACE_CATEGORY, nullptr, [&](lynx::perfetto::EventContext ctx) {
        ctx.event()->set_name(std::string(CSS_PATCHING_GET_CSS_BY_RULE) + "." +
                              rule);
      });
  CSSParseToken* token;
  switch (type) {
    case CSSSheet::ID_SELECT:
      token = style_sheet->GetIdStyle(rule);
      break;
    case CSSSheet::NAME_SELECT:
      token = style_sheet->GetTagStyle(rule);
      break;
    case CSSSheet::ALL_SELECT:
      token = style_sheet->GetUniversalStyle(rule);
      break;
    case CSSSheet::PLACEHOLDER_SELECT:
    case CSSSheet::FIRST_CHILD_SELECT:
    case CSSSheet::LAST_CHILD_SELECT:
    case CSSSheet::PSEUDO_FOCUS_SELECT:
    case CSSSheet::SELECTION_SELECT:
    case CSSSheet::PSEUDO_ACTIVE_SELECT:
    case CSSSheet::PSEUDO_HOVER_SELECT:
      token = style_sheet->GetPseudoStyle(rule);
      break;
    default:
      token = style_sheet->GetCSSStyle(rule);
  }

  if (token != nullptr) {
    MergeCSSStyleAndApplyCSSVariable(attrs_map, token, node);
  }

  if ((type == CSSSheet::CLASS_SELECT || type == CSSSheet::ID_SELECT) &&
      style_sheet->HasCascadeStyle()) {
    ApplyCascadeStyles(style_sheet, node, rule, attrs_map);
  }
}

void CSSPatching::MergeHigherCascadeStyles(const std::string& current_selector,
                                           const std::string& parent_selector,
                                           StyleMap& attrs_map,
                                           AttributeHolder* node,
                                           CSSFragment* style_sheet) {
  std::string integrated_selector =
      MergeCSSSelector(current_selector, parent_selector);
  CSSParseToken* token_parent =
      style_sheet->GetCascadeStyle(integrated_selector);
  if (token_parent != nullptr) {
    MergeCSSStyleAndApplyCSSVariable(attrs_map, token_parent, node);
  }
}

void CSSPatching::ApplyCascadeStyles(CSSFragment* style_sheet,
                                     AttributeHolder* node,
                                     const std::string& rule,
                                     StyleMap& attrs_map) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, CSS_PATCHING_HANDLE_CASCADE);
  if (node == nullptr) {
    return;
  }
  const AttributeHolder* node_parent = node->HolderParent();
  while (node_parent != nullptr) {
    for (const auto& cls : node_parent->classes()) {
      MergeHigherCascadeStyles(rule, GetClassSelectorRule(cls), attrs_map, node,
                               style_sheet);
      // Support for nested focus pseudo class. This is a naive implementation
      // and should be replaced in the future.
      if (node->GetCascadePseudoEnabled() &&
          node_parent->HasPseudoState(kPseudoStateFocus)) {
        MergeHigherCascadeStyles(rule, GetClassSelectorRule(cls) + ":focus",
                                 attrs_map, node, style_sheet);
      }
    }
    node_parent = node_parent->HolderParent();
  }

  node_parent = node->HolderParent();
  while (node_parent != nullptr) {
    const lepus::String& id_node = node_parent->idSelector();
    if (!id_node.empty()) {
      const std::string rule_id_selector = std::string("#") + id_node.c_str();
      MergeHigherCascadeStyles(rule, rule_id_selector, attrs_map, node,
                               style_sheet);
      if (node->GetCascadePseudoEnabled() &&
          node_parent->HasPseudoState(kPseudoStateFocus)) {
        MergeHigherCascadeStyles(rule, rule_id_selector + ":focus", attrs_map,
                                 node, style_sheet);
      }
    }
    node_parent = node_parent->HolderParent();
  }
}

const StyleMap CSSPatching::GetPseudoClassStyle(PseudoClassType pseudo_type,
                                                CSSFragment* style_sheet,
                                                AttributeHolder* node) {
  StyleMap result;
  std::string pseudo_class_name;
  switch (pseudo_type) {
    case PseudoClassType::kFocus:
      pseudo_class_name = ":focus";
      break;
    case PseudoClassType::kHover:
      pseudo_class_name = ":hover";
      break;
    case PseudoClassType::kActive:
      pseudo_class_name = ":active";
      break;
    default:
      return result;
  }

  StyleMap value;
  GetCSSByRule(CSSSheet::PSEUDO_FOCUS_SELECT, style_sheet, node,
               pseudo_class_name, value);
  MergeHigherPriorityCSSStyle(result, value);
  value.clear();
  GetCSSByRule(CSSSheet::PSEUDO_FOCUS_SELECT, style_sheet, node,
               std::string("*") + pseudo_class_name, value);
  MergeHigherPriorityCSSStyle(result, value);

  const lepus::String& tag_node = node->tag();
  if (!tag_node.empty()) {
    value.clear();
    GetCSSByRule(CSSSheet::PSEUDO_FOCUS_SELECT, style_sheet, node,
                 tag_node.str() + pseudo_class_name, value);
    MergeHigherPriorityCSSStyle(result, value);
  }

  for (const auto& cls : node->classes()) {
    const auto rule_class_selector = GetClassSelectorRule(cls);
    value.clear();
    GetCSSByRule(CSSSheet::PSEUDO_FOCUS_SELECT, style_sheet, node,
                 rule_class_selector + pseudo_class_name, value);
    MergeHigherPriorityCSSStyle(result, value);
  }

  if (!node->idSelector().empty()) {
    auto rule_name =
        std::string("#") + node->idSelector().c_str() + pseudo_class_name;
    value.clear();
    GetCSSByRule(CSSSheet::PSEUDO_FOCUS_SELECT, style_sheet, node, rule_name,
                 value);
    MergeHigherPriorityCSSStyle(result, value);
  }

  return result;
}

void CSSPatching::GetCSSStyleForFiber(FiberElement* node,
                                      CSSFragment* style_sheet,
                                      StyleMap& result) {
  auto* holder = node->data_model();
  if (!holder || !style_sheet) {
    return;
  }

  if (style_sheet->enable_css_selector()) {
    GetCSSStyleNew(node->data_model(), result, style_sheet);
    // No longer need to merge inline style, just return directly.
    return;
  }

  if (!style_sheet->css().empty()) {
    // process "*" first
    CSSParseToken* token = style_sheet->GetCSSStyle("*");
    if (token) {
      MergeCSSStyleAndApplyCSSVariable(result, token, holder);
    }

    // 首先开始处理标签选择器
    const lepus::String& tag_node = holder->tag();
    if (!tag_node.empty()) {
      const std::string& rule_tag_selector = tag_node.str();
      token = style_sheet->GetCSSStyle(rule_tag_selector);
      if (token) {
        MergeCSSStyleAndApplyCSSVariable(result, token, holder);
      }
    }

    // Class 选择器
    for (const auto& cls : holder->classes()) {
      const std::string rule_class_selector = "." + cls.str();
      token = style_sheet->GetCSSStyle(rule_class_selector);
      if (token) {
        MergeCSSStyleAndApplyCSSVariable(result, token, holder);
      }
      ApplyCascadeStylesForFiber(style_sheet, node, rule_class_selector,
                                 result);
    }

    // handle pseudo state
    if (holder->HasPseudoState(kPseudoStateFocus)) {
      MergeHigherPriorityCSSStyle(
          result,
          GetPseudoClassStyle(PseudoClassType::kFocus, style_sheet, holder));
    }

    if (holder->HasPseudoState(kPseudoStateHover)) {
      MergeHigherPriorityCSSStyle(
          result,
          GetPseudoClassStyle(PseudoClassType::kHover, style_sheet, holder));
    }

    if (holder->HasPseudoState(kPseudoStateActive)) {
      MergeHigherPriorityCSSStyle(
          result,
          GetPseudoClassStyle(PseudoClassType::kActive, style_sheet, holder));
    }

    // ID 选择器
    const lepus::String& id_node = holder->idSelector();
    if (!id_node.empty()) {
      const std::string rule_id_selector = std::string("#") + id_node.c_str();
      token = style_sheet->GetCSSStyle(rule_id_selector);
      if (token) {
        MergeCSSStyleAndApplyCSSVariable(result, token, holder);
      }
      ApplyCascadeStylesForFiber(style_sheet, node, rule_id_selector, result);
    }
  }
}

void CSSPatching::ApplyCascadeStylesForFiber(CSSFragment* style_sheet,
                                             FiberElement* node,
                                             const std::string& rule,
                                             StyleMap& attrs_map) {
  // for descendant selector, we just find the parent class in current
  // component scope!
  if (style_sheet->HasCascadeStyle()) {
    FiberElement* node_parent = static_cast<FiberElement*>(node->parent());
    while (node_parent) {
      // TTML: all the element in the same scope
      // React:  decided by react runtime
      if (node->IsInSameCSSScope(node_parent)) {
        for (const auto& clazz : node_parent->data_model()->classes()) {
          MergeHigherCascadeStylesForFiber(rule, GetClassSelectorRule(clazz),
                                           attrs_map, node->data_model(),
                                           style_sheet);

          // NOTE: Support for nested focus pseudo class. This is a naive
          // implementation and should be replaced in the future.
          if (node->element_manager()->GetEnableCascadePseudo() &&
              node_parent->data_model()->HasPseudoState(kPseudoStateFocus)) {
            MergeHigherCascadeStylesForFiber(
                rule, GetClassSelectorRule(clazz) + ":focus", attrs_map,
                node->data_model(), style_sheet);
          }
        }
      }

      if (!node->element_manager()->GetRemoveDescendantSelectorScope() &&
          node_parent->is_component()) {
        // descendant selector only works in current component scope!
        break;
      }
      node_parent = static_cast<FiberElement*>(node_parent->parent());
    }
  }
}

void CSSPatching::MergeHigherCascadeStylesForFiber(
    const std::string& current_selector, const std::string& parent_selector,
    StyleMap& attrs_map, AttributeHolder* node, CSSFragment* style_sheet) {
  std::string integrated_selector =
      MergeCSSSelector(current_selector, parent_selector);
  CSSParseToken* token_parent =
      style_sheet->GetCascadeStyle(integrated_selector);
  if (token_parent != nullptr) {
    MergeCSSStyleAndApplyCSSVariable(attrs_map, token_parent, node);
  }
}

}  // namespace tasm
}  // namespace lynx
