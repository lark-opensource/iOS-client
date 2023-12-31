// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_NG_SELECTOR_LYNX_CSS_PARSER_SELECTOR_H_
#define LYNX_CSS_NG_SELECTOR_LYNX_CSS_PARSER_SELECTOR_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "css/ng/selector/lynx_css_selector.h"
#include "css/ng/selector/lynx_css_selector_list.h"

namespace lynx {
namespace css {

class CSSParserContext;
class LynxCSSParserSelector;

// See css_selector_parser.h.
using LynxCSSSelectorVector =
    std::vector<std::unique_ptr<LynxCSSParserSelector>>;

class LynxCSSParserSelector {
 public:
  LynxCSSParserSelector() : selector_(std::make_unique<LynxCSSSelector>()) {}

  explicit LynxCSSParserSelector(const std::string& tag_name)
      : selector_(std::make_unique<LynxCSSSelector>(tag_name)) {}
  LynxCSSParserSelector(const LynxCSSParserSelector&) = delete;
  LynxCSSParserSelector& operator=(const LynxCSSParserSelector&) = delete;
  ~LynxCSSParserSelector() {
    while (tag_history_) {
      std::unique_ptr<LynxCSSParserSelector> next =
          std::move(tag_history_->tag_history_);
      tag_history_ = std::move(next);
    }
  }

  // Note that on ReleaseSelector() or GetSelector(), you get that single
  // selector only, not its entire tag history (so TagHistory() will not
  // make sense until it's put into a LynxCSSSelectorVector).
  std::unique_ptr<LynxCSSSelector> ReleaseSelector() {
    return std::move(selector_);
  }
  void SetValue(const std::string& value) { selector_->SetValue(value); }
  void SetAttribute(const std::string& value,
                    LynxCSSSelector::AttributeMatchType match_type) {
    selector_->SetAttribute(value, match_type);
  }
  void SetArgument(const std::string& value) { selector_->SetArgument(value); }
  void SetNth(int a, int b) { selector_->SetNth(a, b); }
  void SetMatch(LynxCSSSelector::MatchType value) {
    selector_->SetMatch(value);
  }
  void SetRelation(LynxCSSSelector::RelationType value) {
    selector_->SetRelation(value);
  }

  void UpdatePseudoType(const std::u16string& value,
                        const CSSParserContext& context,
                        bool has_arguments) const;

  void SetSelectorList(std::unique_ptr<LynxCSSSelectorList> selector_list) {
    selector_->SetSelectorList(std::move(selector_list));
  }

  LynxCSSSelector::MatchType Match() const { return selector_->Match(); }
  LynxCSSSelector::PseudoType GetPseudoType() const {
    return selector_->GetPseudoType();
  }
  const LynxCSSSelectorList* SelectorList() const {
    return selector_->SelectorList();
  }

  LynxCSSParserSelector* TagHistory() const { return tag_history_.get(); }
  void SetTagHistory(std::unique_ptr<LynxCSSParserSelector> selector) {
    tag_history_ = std::move(selector);
  }
  void AppendTagHistory(LynxCSSSelector::RelationType relation,
                        std::unique_ptr<LynxCSSParserSelector> selector) {
    LynxCSSParserSelector* end = this;
    while (end->TagHistory()) end = end->TagHistory();
    end->SetRelation(relation);
    end->SetTagHistory(std::move(selector));
  }
  std::unique_ptr<LynxCSSParserSelector> ReleaseTagHistory() {
    SetRelation(LynxCSSSelector::kSubSelector);
    return std::move(tag_history_);
  }
  void PrependTagSelector(const std::string& tag_name, bool is_implicit) {
    std::unique_ptr<LynxCSSParserSelector> second =
        std::make_unique<LynxCSSParserSelector>();
    second->selector_ = std::move(selector_);
    second->tag_history_ = std::move(tag_history_);
    tag_history_ = std::move(second);
    selector_ = std::make_unique<LynxCSSSelector>(tag_name, is_implicit);
  }

 private:
  std::unique_ptr<LynxCSSSelector> selector_;
  std::unique_ptr<LynxCSSParserSelector> tag_history_;
};

}  // namespace css
}  // namespace lynx

#endif  // LYNX_CSS_NG_SELECTOR_LYNX_CSS_PARSER_SELECTOR_H_
