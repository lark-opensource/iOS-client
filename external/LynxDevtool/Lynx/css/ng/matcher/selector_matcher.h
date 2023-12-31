// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_NG_MATCHER_SELECTOR_MATCHER_H_
#define LYNX_CSS_NG_MATCHER_SELECTOR_MATCHER_H_

#include <limits>

#include "css/ng/selector/lynx_css_selector.h"
#include "tasm/attribute_holder.h"

namespace lynx {
namespace css {
class LynxCSSSelector;

class SelectorMatcher {
 public:
  explicit inline SelectorMatcher() {}

  SelectorMatcher(const SelectorMatcher&) = delete;
  SelectorMatcher& operator=(const SelectorMatcher&) = delete;

  // Wraps the current element and a LynxCSSSelector and stores some other state
  // of the selector matching process.
  struct SelectorMatchingContext {
   public:
    // Initial selector constructor
    explicit SelectorMatchingContext(lynx::tasm::AttributeHolder* element)
        : element_(element) {}

    // Group fields by type to avoid perf test regression.
    const LynxCSSSelector* selector_ = nullptr;

    lynx::tasm::AttributeHolder* element_ = nullptr;
    lynx::tasm::AttributeHolder* previous_element_ = nullptr;

    PseudoId pseudo_id_ = kPseudoIdNone;

    bool is_sub_selector_ = false;
  };

  bool Match(const SelectorMatchingContext& context) const;

 private:
  bool MatchSimple(const SelectorMatchingContext&) const;

  enum MatchStatus {
    kSelectorMatches,
    kSelectorFailsLocally,
    kSelectorFailsAllSiblings,
    kSelectorFailsCompletely
  };

  MatchStatus MatchSelector(const SelectorMatchingContext&) const;
  MatchStatus MatchForSubSelector(const SelectorMatchingContext&) const;
  MatchStatus MatchForRelation(const SelectorMatchingContext&) const;
  bool MatchPseudoClass(const SelectorMatchingContext&) const;
  bool MatchPseudoElement(const SelectorMatchingContext&) const;
  bool MatchPseudoNot(const SelectorMatchingContext&) const;

  mutable bool in_match_ = false;
};
}  // namespace css
}  // namespace lynx

#endif  // LYNX_CSS_NG_MATCHER_SELECTOR_MATCHER_H_
