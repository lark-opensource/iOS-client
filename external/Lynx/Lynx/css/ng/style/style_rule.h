// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_NG_STYLE_STYLE_RULE_H_
#define LYNX_CSS_NG_STYLE_STYLE_RULE_H_

#include <limits.h>

#include <memory>
#include <string>
#include <utility>

#include "css/ng/selector/lynx_css_selector_list.h"

namespace lynx {

namespace tasm {
class CSSParseToken;
}

namespace css {

class StyleRule {
 public:
  StyleRule(std::unique_ptr<LynxCSSSelector[]> selector_array,
            const std::shared_ptr<lynx::tasm::CSSParseToken>& token)
      : selector_array_(std::move(selector_array)), token_(token) {}

  unsigned IndexOfNextSelectorAfter(size_t index) const {
    const LynxCSSSelector& current = SelectorAt(index);
    const LynxCSSSelector* next = LynxCSSSelectorList::Next(current);
    if (!next) return UINT_MAX;
    return SelectorIndex(*next);
  }

  const LynxCSSSelector* FirstSelector() const { return selector_array_.get(); }
  const LynxCSSSelector& SelectorAt(size_t index) const {
    return selector_array_[index];
  }
  unsigned SelectorIndex(const LynxCSSSelector& selector) const {
    return static_cast<unsigned>(&selector - FirstSelector());
  }

  const std::shared_ptr<lynx::tasm::CSSParseToken>& Token() { return token_; }

 private:
  std::unique_ptr<LynxCSSSelector[]> selector_array_;
  std::shared_ptr<lynx::tasm::CSSParseToken> token_;
};

}  // namespace css
}  // namespace lynx

#endif  // LYNX_CSS_NG_STYLE_STYLE_RULE_H_
