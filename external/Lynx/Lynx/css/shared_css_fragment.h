// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_SHARED_CSS_FRAGMENT_H_
#define LYNX_CSS_SHARED_CSS_FRAGMENT_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "css/css_fragment.h"
#include "css/ng/invalidation/rule_invalidation_set.h"

namespace lynx {
namespace tasm {

// A global CSSFragment implementation that gets registered in
// CSSStyleSheetManager and shallow-copied into components referencing it.
class SharedCSSFragment : public CSSFragment {
 public:
  SharedCSSFragment(int32_t id, const std::vector<int32_t>& dependent_ids,
                    CSSParserTokenMap css, CSSKeyframesTokenMap keyframes,
                    CSSFontFaceTokenMap fontfaces)
      : id_(id),
        is_baked_(false),
        dependent_ids_(dependent_ids),
        css_(std::move(css)),
        keyframes_(std::move(keyframes)),
        fontfaces_(std::move(fontfaces)) {}

  explicit SharedCSSFragment(int32_t id)
      : SharedCSSFragment(id, {}, {}, {}, {}) {}
  SharedCSSFragment() : SharedCSSFragment(-1) {}

  ~SharedCSSFragment() override;

  inline int32_t id() const { return id_; }
  inline bool is_baked() { return is_baked_; }
  inline bool enable_class_merge() { return enable_class_merge_; }
  inline bool enable_css_selector() override { return enable_css_selector_; }
  inline bool enable_css_invalidation() override {
    return enable_css_invalidation_;
  }
  inline const std::vector<int32_t>& dependent_ids() { return dependent_ids_; }
  const CSSParserTokenMap& css() override { return css_; }
  css::RuleSet* rule_set() override { return rule_set_.get(); }
  const std::vector<LynxCSSSelectorTuple>& selector_tuple() override {
    return selector_tuple_;
  }
  const CSSParserTokenMap& pseudo_map() override { return pseudo_map_; }
  const CSSParserTokenMap& child_pseudo_map() override {
    return child_pseudo_map_;
  }
  const CSSParserTokenMap& cascade_map() override { return cascade_map_; }
  const CSSKeyframesTokenMap& keyframes() override { return keyframes_; }
  const CSSFontFaceTokenMap& fontfaces() override { return fontfaces_; }
  const PseudoNotStyle& pseudo_not_style() override {
    return *pseudo_not_style_;
  }

  void MarkBaked() { is_baked_ = true; }
  void ImportOtherFragment(SharedCSSFragment* fragment);
  void SetEnableClassMerge(bool class_merge) {
    enable_class_merge_ = class_merge;
  }

  // Enabled in CSS selector only
  void SetEnableCSSInvalidation() { enable_css_invalidation_ = true; }

  // Invoked after SetEnableCSSInvalidation
  void SetEnableCSSSelector() {
    enable_css_selector_ = true;
    if (rule_set_) {
      return;
    }
    if (enable_css_invalidation_) {
      rule_invalidation_set_ = std::make_unique<css::RuleInvalidationSet>();
    }
    rule_set_ = std::make_unique<css::RuleSet>(this);
  }

  void SetSelectorTuple(std::vector<LynxCSSSelectorTuple>& selector_tuple) {
    selector_tuple_ = std::move(selector_tuple);
  }

  css::RuleInvalidationSet* GetRuleInvalidationSet() {
    return rule_invalidation_set_.get();
  }

  void CollectInvalidationSetsForId(css::InvalidationLists& lists,
                                    const std::string& id) override;

  void CollectInvalidationSetsForClass(css::InvalidationLists& lists,
                                       const std::string& class_name) override;

  void CollectInvalidationSetsForPseudoClass(
      css::InvalidationLists& lists,
      css::LynxCSSSelector::PseudoType pseudo) override;

  CSSParseToken* GetCSSStyle(const std::string& key) override;
  // The GetCSSStyle() call returns raw pointer and is thus non-ideal.
  virtual std::shared_ptr<CSSParseToken> GetSharedCSSStyle(
      const std::string& key) override;
  CSSParseToken* GetPseudoStyle(const std::string& key) override;
  CSSParseToken* GetCascadeStyle(const std::string& key) override;
  CSSParseToken* GetIdStyle(const std::string& key) override;
  CSSParseToken* GetTagStyle(const std::string& key) override;
  CSSParseToken* GetUniversalStyle(const std::string& key) override;
  CSSKeyframesToken* GetKeyframes(const std::string& key) override;
  const std::vector<std::shared_ptr<CSSFontFaceToken>>& GetCSSFontFace(
      const std::string& key) override;
  bool HasPseudoNotStyle() override { return has_pseudo_not_style_; }
  void InitPseudoNotStyle() override;
  void ReplaceByNewFragment(SharedCSSFragment* new_fragment);
  void FindSpecificMapAndAdd(const std::string& key,
                             const std::shared_ptr<CSSParseToken>& parse_token);
  void AddStyleRule(std::unique_ptr<css::LynxCSSSelector[]> selector_arr,
                    std::shared_ptr<CSSParseToken> parse_token);
  bool HasIdSelector() override { return !id_map_.empty(); }

 private:
  friend class TemplateBinaryReader;
  friend class TemplateBinaryReaderSSR;
  friend class LynxBinaryBaseCSSReader;

  int32_t id_;
  bool is_baked_;
  bool enable_class_merge_ = false;
  bool enable_css_selector_ = false;
  bool enable_css_invalidation_ = false;
  std::vector<int32_t> dependent_ids_;
  CSSParserTokenMap css_;
  std::vector<LynxCSSSelectorTuple> selector_tuple_;
  CSSKeyframesTokenMap keyframes_;
  CSSFontFaceTokenMap fontfaces_;
  // Structures for quickly rejecting the selector
  CSSParserTokenMap pseudo_map_;
  CSSParserTokenMap child_pseudo_map_;
  CSSParserTokenMap cascade_map_;
  CSSParserTokenMap id_map_;
  CSSParserTokenMap tag_map_;
  CSSParserTokenMap universal_map_;
  std::unique_ptr<css::RuleSet> rule_set_;
  // Initialize the RuleInvalidationSet only when the CSS invalidation is
  // enabled
  std::unique_ptr<css::RuleInvalidationSet> rule_invalidation_set_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_SHARED_CSS_FRAGMENT_H_
