// Copyright 2023 The Lynx Authors. All rights reserved.
#ifndef LYNX_CSS_NG_INVALIDATION_RULE_INVALIDATION_SET_H_
#define LYNX_CSS_NG_INVALIDATION_RULE_INVALIDATION_SET_H_

#include <string>
#include <unordered_map>
#include <vector>

#include "css/ng/invalidation/invalidation_set.h"
#include "css/ng/selector/lynx_css_selector.h"

namespace lynx {
namespace css {

struct InvalidationLists;

// Summarizes and indexes the contents of CSS selectors. It creates
// invalidation sets from them and makes them available via several
// CollectInvalidationSetForFoo methods which use the indices to quickly gather
// the relevant InvalidationSets for a particular DOM mutation.
class RuleInvalidationSet {
 public:
  RuleInvalidationSet() = default;
  RuleInvalidationSet(const RuleInvalidationSet&) = delete;
  RuleInvalidationSet& operator=(const RuleInvalidationSet&) = delete;

  // Merge the given RuleInvalidationSet into this one, used in import rules
  void Merge(const RuleInvalidationSet& other);

  void Clear();

  // Creates invalidation sets for the given CSS selector. This is done as part
  // of creating the RuleSet for the style sheet, i.e., before matching or
  // mutation begins.
  void AddSelector(const LynxCSSSelector&);

  // Collect descendant and sibling invalidation sets, for a given type of
  // change. This is called during DOM mutations.
  // CollectInvalidationSets* govern self-invalidation and descendant
  // invalidations, while CollectSiblingInvalidationSets* govern sibling
  // invalidations.
  void CollectInvalidationSetsForClass(InvalidationLists&,
                                       const std::string& class_name) const;

  void CollectInvalidationSetsForId(InvalidationLists&,
                                    const std::string& id) const;
  // void CollectInvalidationSetsForAttribute(
  //     InvalidationLists&, const std::string& attribute_name) const;
  void CollectInvalidationSetsForPseudoClass(InvalidationLists&,
                                             LynxCSSSelector::PseudoType) const;

 private:
  enum PositionType { kSubject, kAncestor };
  InvalidationSet* InvalidationSetForSimpleSelector(const LynxCSSSelector&,
                                                    InvalidationType,
                                                    PositionType);

  using InvalidationSetMap =
      std::unordered_map<std::string, InvalidationSetPtr>;
  using PseudoTypeInvalidationSetMap =
      std::unordered_map<LynxCSSSelector::PseudoType, InvalidationSetPtr>;

  InvalidationSet& EnsureClassInvalidationSet(const std::string& class_name,
                                              InvalidationType, PositionType);
  // InvalidationSet& EnsureAttributeInvalidationSet(
  //     const std::string& attribute_name, InvalidationType, PositionType);
  InvalidationSet& EnsureIdInvalidationSet(const std::string& id,
                                           InvalidationType, PositionType);
  InvalidationSet& EnsurePseudoInvalidationSet(LynxCSSSelector::PseudoType,
                                               InvalidationType, PositionType);

  struct InvalidationSetFeatures {
    bool HasFeatures() const;

    void NarrowToClass(const std::string& class_name) {
      if (Size() == 1 && (!ids.empty() || !classes.empty())) return;
      ClearFeatures();
      classes.push_back(class_name);
    }
    // void NarrowToAttribute(const std::string& attribute) {
    //   if (Size() == 1 &&
    //       (!ids.empty() || !classes.empty() || !attributes.empty()))
    //     return;
    //   ClearFeatures();
    //   attributes.push_back(attribute);
    // }
    void NarrowToId(const std::string& id) {
      if (Size() == 1 && !ids.empty()) return;
      ClearFeatures();
      ids.push_back(id);
    }
    void NarrowToTag(const std::string& tag_name) {
      if (Size() == 1) return;
      ClearFeatures();
      tag_names.push_back(tag_name);
    }
    void ClearFeatures() {
      classes.clear();
      // attributes.clear();
      ids.clear();
      tag_names.clear();
    }
    size_t Size() const {
      return classes.size() + ids.size() + tag_names.size();
      // + attributes.size();
    }

    bool WholeSubtreeInvalid() const { return whole_subtree_invalid_; }
    void SetWholeSubtreeInvalid(bool value) { whole_subtree_invalid_ = value; }

    std::vector<std::string> classes;
    // std::vector<std::string> attributes;
    std::vector<std::string> ids;
    std::vector<std::string> tag_names;

   private:
    bool whole_subtree_invalid_{false};
  };

  void UpdateInvalidationSetsForComplex(const LynxCSSSelector&,
                                        InvalidationSetFeatures&, PositionType);

  static void ExtractInvalidationSetFeaturesFromSimpleSelector(
      const LynxCSSSelector&, InvalidationSetFeatures&);
  const LynxCSSSelector* ExtractInvalidationSetFeaturesFromCompound(
      const LynxCSSSelector&, InvalidationSetFeatures&, PositionType);
  void ExtractInvalidationSetFeaturesFromSelectorList(const LynxCSSSelector&,
                                                      InvalidationSetFeatures&,
                                                      PositionType);
  void AddFeaturesToInvalidationSet(InvalidationSet&,
                                    const InvalidationSetFeatures&);
  void AddFeaturesToInvalidationSets(
      const LynxCSSSelector&, InvalidationSetFeatures& descendant_features);
  const LynxCSSSelector* AddFeaturesToInvalidationSetsForCompoundSelector(
      const LynxCSSSelector&, InvalidationSetFeatures& descendant_features);
  void AddFeaturesToInvalidationSetsForSimpleSelector(
      const LynxCSSSelector& simple_selector, const LynxCSSSelector& compound,
      InvalidationSetFeatures& descendant_features);

  static InvalidationSet& EnsureMutableInvalidationSet(
      InvalidationType type, PositionType position,
      InvalidationSetPtr& invalidation_set);

  static InvalidationSet& EnsureInvalidationSet(InvalidationSetMap&,
                                                const std::string& key,
                                                InvalidationType, PositionType);
  static InvalidationSet& EnsureInvalidationSet(PseudoTypeInvalidationSetMap&,
                                                LynxCSSSelector::PseudoType key,
                                                InvalidationType, PositionType);

  static void MergeInvalidationSet(InvalidationSetMap&, const std::string& key,
                                   InvalidationSet*);
  static void MergeInvalidationSet(PseudoTypeInvalidationSetMap&,
                                   LynxCSSSelector::PseudoType key,
                                   InvalidationSet*);

  static bool SupportedRelation(LynxCSSSelector::RelationType);

  InvalidationSetMap class_invalidation_sets_;
  // InvalidationSetMap attribute_invalidation_sets_;
  InvalidationSetMap id_invalidation_sets_;
  PseudoTypeInvalidationSetMap pseudo_invalidation_sets_;

  friend class RuleInvalidationSetTest;
};

}  // namespace css
}  // namespace lynx

#endif  // LYNX_CSS_NG_INVALIDATION_RULE_INVALIDATION_SET_H_
