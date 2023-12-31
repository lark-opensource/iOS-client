// Copyright 2022 The Lynx Authors. All rights reserved.

#include "css/ng/matcher/selector_matcher.h"

#include <string>

#include "base/auto_reset.h"
#include "css/ng/parser/ascii_ctype.h"
#include "tasm/attribute_holder.h"

namespace lynx {
namespace css {

static lynx::tasm::AttributeHolder* ParentElement(
    const SelectorMatcher::SelectorMatchingContext& context) {
  return context.element_->SelectorMatchingParent();
}

bool SelectorMatcher::Match(const SelectorMatchingContext& context) const {
  DCHECK(context.selector_);
  DCHECK(!in_match_);
  // "Do not re-enter Match: use MatchSelector instead";
  base::AutoReset<bool> reset_in_match(&in_match_, true);

  if (MatchSelector(context) != kSelectorMatches) return false;
  return true;
}

SelectorMatcher::MatchStatus SelectorMatcher::MatchSelector(
    const SelectorMatchingContext& context) const {
  if (!MatchSimple(context)) return kSelectorFailsLocally;

  if (context.selector_->IsLastInTagHistory()) return kSelectorMatches;

  MatchStatus match;
  if (context.selector_->Relation() != LynxCSSSelector::kSubSelector) {
    match = MatchForRelation(context);
  } else {
    match = MatchForSubSelector(context);
  }
  return match;
}

static inline SelectorMatcher::SelectorMatchingContext
PrepareNextContextForRelation(
    const SelectorMatcher::SelectorMatchingContext& context) {
  SelectorMatcher::SelectorMatchingContext next_context(context);
  DCHECK(context.selector_->TagHistory());
  next_context.selector_ = context.selector_->TagHistory();
  return next_context;
}

SelectorMatcher::MatchStatus SelectorMatcher::MatchForSubSelector(
    const SelectorMatchingContext& context) const {
  SelectorMatchingContext next_context = PrepareNextContextForRelation(context);

  next_context.is_sub_selector_ = true;
  return MatchSelector(next_context);
}

SelectorMatcher::MatchStatus SelectorMatcher::MatchForRelation(
    const SelectorMatchingContext& context) const {
  SelectorMatchingContext next_context = PrepareNextContextForRelation(context);

  LynxCSSSelector::RelationType relation = context.selector_->Relation();

  next_context.is_sub_selector_ = false;
  next_context.previous_element_ = context.element_;
  next_context.pseudo_id_ = kPseudoIdNone;

  switch (relation) {
    case LynxCSSSelector::kDescendant:
      for (next_context.element_ = ParentElement(next_context);
           next_context.element_;
           next_context.element_ = ParentElement(next_context)) {
        MatchStatus match = MatchSelector(next_context);
        if (match == kSelectorMatches || match == kSelectorFailsCompletely)
          return match;
      }
      return kSelectorFailsCompletely;
    case LynxCSSSelector::kChild: {
      next_context.element_ = ParentElement(next_context);
      if (!next_context.element_) return kSelectorFailsCompletely;
      return MatchSelector(next_context);
    }
    case LynxCSSSelector::kDirectAdjacent:
      next_context.element_ = (*context.element_).PreviousSibling();
      if (!next_context.element_) return kSelectorFailsAllSiblings;
      return MatchSelector(next_context);
    case LynxCSSSelector::kIndirectAdjacent:
      next_context.element_ = (*context.element_).PreviousSibling();
      for (; next_context.element_;
           next_context.element_ = (*next_context.element_).PreviousSibling()) {
        MatchStatus match = MatchSelector(next_context);
        if (match == kSelectorMatches || match == kSelectorFailsAllSiblings ||
            match == kSelectorFailsCompletely)
          return match;
      }
      return kSelectorFailsAllSiblings;

    case LynxCSSSelector::kUAShadow: {
      next_context.element_ = context.element_->PseudoElementOwner();
      return MatchSelector(next_context);
    }
    case LynxCSSSelector::kSubSelector:
    default:
      break;
  }
  return kSelectorFailsCompletely;
}

bool SelectorMatcher::MatchSimple(
    const SelectorMatchingContext& context) const {
  DCHECK(context.element_);
  lynx::tasm::AttributeHolder& element = *context.element_;
  DCHECK(context.selector_);
  const LynxCSSSelector& selector = *context.selector_;

  switch (selector.Match()) {
    case LynxCSSSelector::kTag:
      return selector.Value() == CSSGlobalStarString() ||
             element.ContainsTagSelector(selector.Value());
    case LynxCSSSelector::kClass:
      return element.ContainsClassSelector(selector.Value());
    case LynxCSSSelector::kId:
      return element.ContainsIdSelector(selector.Value());
    // Attribute selectors
    case LynxCSSSelector::kAttributeExact:
    case LynxCSSSelector::kAttributeSet:
    case LynxCSSSelector::kAttributeHyphen:
    case LynxCSSSelector::kAttributeList:
    case LynxCSSSelector::kAttributeContain:
    case LynxCSSSelector::kAttributeBegin:
    case LynxCSSSelector::kAttributeEnd:
      return false;
    case LynxCSSSelector::kPseudoClass:
      return MatchPseudoClass(context);
    case LynxCSSSelector::kPseudoElement:
      return MatchPseudoElement(context);
    default:
      return false;
  }
}

bool SelectorMatcher::MatchPseudoNot(
    const SelectorMatchingContext& context) const {
  const LynxCSSSelector& selector = *context.selector_;
  DCHECK(selector.SelectorList());
  SelectorMatchingContext sub_context(context);
  sub_context.is_sub_selector_ = true;
  sub_context.pseudo_id_ = kPseudoIdNone;
  for (sub_context.selector_ = selector.SelectorList()->First();
       sub_context.selector_; sub_context.selector_ = LynxCSSSelectorList::Next(
                                  *sub_context.selector_)) {
    if (MatchSelector(sub_context) == kSelectorMatches) return false;
  }
  return true;
}

bool SelectorMatcher::MatchPseudoClass(
    const SelectorMatchingContext& context) const {
  lynx::tasm::AttributeHolder& element = *context.element_;
  const LynxCSSSelector& selector = *context.selector_;

  switch (selector.GetPseudoType()) {
    case LynxCSSSelector::kPseudoNot:
      return MatchPseudoNot(context);
    case LynxCSSSelector::kPseudoHover:
      return element.HasPseudoState(tasm::kPseudoStateHover);
    case LynxCSSSelector::kPseudoActive:
      return element.HasPseudoState(tasm::kPseudoStateActive);
    case LynxCSSSelector::kPseudoFocus:
      return element.HasPseudoState(tasm::kPseudoStateFocus);
    case LynxCSSSelector::kPseudoRoot:
      return element.tag().str() == "page";
    case LynxCSSSelector::kPseudoUnknown:
    default:
      break;
  }
  return false;
}

bool SelectorMatcher::MatchPseudoElement(
    const SelectorMatchingContext& context) const {
  lynx::tasm::AttributeHolder& element = *context.element_;
  const LynxCSSSelector& selector = *context.selector_;

  switch (selector.GetPseudoType()) {
    case LynxCSSSelector::PseudoType::kPseudoPlaceholder:
      return element.HasPseudoState(tasm::kPseudoStatePlaceHolder);
    case LynxCSSSelector::PseudoType::kPseudoSelection:
      return element.HasPseudoState(tasm::kPseudoStateSelection);
    default:
      break;
  }
  return false;
}
}  // namespace css
}  // namespace lynx
