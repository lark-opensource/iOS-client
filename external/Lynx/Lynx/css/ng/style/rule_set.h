// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_NG_STYLE_RULE_SET_H_
#define LYNX_CSS_NG_STYLE_RULE_SET_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "css/ng/style/rule_data.h"

namespace lynx {

namespace tasm {
class AttributeHolder;
class CSSParseToken;
class SharedCSSFragment;
}  // namespace tasm

namespace css {

class RuleInvalidationSet;

struct MatchedRule {
  MatchedRule(const RuleData* rule_data, unsigned index)
      : rule_data_(rule_data) {
    position_ = (static_cast<uint64_t>(index) << RuleData::kPositionBits) +
                rule_data_->Position();
  }

  const RuleData* Data() const { return rule_data_; }
  uint64_t Position() const { return position_; }
  unsigned Specificity() const { return rule_data_->Specificity(); }

 private:
  const RuleData* rule_data_;
  uint64_t position_;
};

class RuleSet {
 public:
  explicit RuleSet(tasm::SharedCSSFragment* fragment) : fragment_(fragment) {}

  void MatchStyles(lynx::tasm::AttributeHolder* node, unsigned& level,
                   std::vector<MatchedRule>& output) const;

  void AddToRuleSet(const std::string& text,
                    const std::shared_ptr<lynx::tasm::CSSParseToken>& token);

  void Merge(const RuleSet& rule_set) { deps_.push_back(rule_set); }

  void AddStyleRule(const std::shared_ptr<StyleRule>& r);

  std::shared_ptr<tasm::CSSParseToken> GetRootToken();

  std::vector<RuleData> id_rules(const std::string& key) {
    return id_rules_[key];
  }

  std::vector<RuleData> class_rules(const std::string& key) {
    return class_rules_[key];
  }

  std::vector<RuleData> attr_rules(const std::string& key) {
    return attr_rules_[key];
  }

  std::vector<RuleData> tag_rules(const std::string& key) {
    return tag_rules_[key];
  }

  std::vector<RuleData> pseudo_rules() { return pseudo_rules_; }

  std::vector<RuleData> universal_rules() { return universal_rules_; }

 private:
  bool FindBestRuleSetAndAdd(const LynxCSSSelector& component,
                             const RuleData& rule);

  static void AddToRuleSet(
      const std::string& key,
      std::unordered_map<std::string, std::vector<RuleData>>& map,
      const RuleData& rule);

  static const LynxCSSSelector* ExtractBestSelectorValues(
      const LynxCSSSelector& component, std::string& id,
      std::string& class_name, std::string& attr_name, std::string& attr_value,
      std::string& tag_name, LynxCSSSelector::PseudoType& pseudo_type);

  static void ExtractSelectorValues(const LynxCSSSelector* selector,
                                    std::string& id, std::string& class_name,
                                    std::string& attr_name,
                                    std::string& attr_value,
                                    std::string& tag_name,
                                    LynxCSSSelector::PseudoType& pseudo_type);

  std::unordered_map<std::string, std::vector<RuleData>> id_rules_;
  std::unordered_map<std::string, std::vector<RuleData>> class_rules_;
  std::unordered_map<std::string, std::vector<RuleData>> attr_rules_;
  std::unordered_map<std::string, std::vector<RuleData>> tag_rules_;
  std::vector<RuleData> pseudo_rules_;
  std::vector<RuleData> universal_rules_;

  std::vector<RuleSet> deps_;
  tasm::SharedCSSFragment* fragment_ = nullptr;
  unsigned rule_count_ = 0;
};

}  // namespace css
}  // namespace lynx

#endif  // LYNX_CSS_NG_STYLE_RULE_SET_H_
