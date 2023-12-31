// Copyright 2023 The Lynx Authors. All rights reserved.

#include "css/ng/invalidation/rule_invalidation_set.h"

#include <algorithm>
#include <utility>

#include "base/auto_reset.h"
#include "css/ng/css_utils.h"
#include "css/ng/selector/lynx_css_selector.h"
#include "css/ng/selector/lynx_css_selector_list.h"

namespace lynx {
namespace css {

namespace {

void ExtractInvalidationSets(InvalidationSet* invalidation_set,
                             DescendantInvalidationSet*& descendants) {
  DCHECK(invalidation_set->IsAlive());
  // Convert to different subclasses according to type
  if (invalidation_set->GetType() == InvalidationType::kInvalidateDescendants) {
    descendants = static_cast<DescendantInvalidationSet*>(invalidation_set);
  }
}

}  // namespace

InvalidationSet& RuleInvalidationSet::EnsureMutableInvalidationSet(
    InvalidationType type, PositionType position,
    InvalidationSetPtr& invalidation_set) {
  if (!invalidation_set) {
    // Create a new invalidation set of the right type.
    invalidation_set =
        position == kSubject
            ? InvalidationSetPtr(InvalidationSet::SelfInvalidationSet())
            : DescendantInvalidationSet::Create();
    return *invalidation_set;
  }

  if (invalidation_set->IsSelfInvalidationSet() &&
      type == InvalidationType::kInvalidateDescendants &&
      position == kSubject) {
    // Returns the singleton for self-invalidation set with the same position
    // and type
    return *invalidation_set;
  }

  // We must copy it before changing invalidation_set is the
  // SelfInvalidationSet() singleton
  // For example, '. a' creates a SelfInvalidationSet, then '.a .b' needs to
  // change the invalidation_set
  if (invalidation_set->IsSelfInvalidationSet()) {
    invalidation_set = DescendantInvalidationSet::Create();
    invalidation_set->SetInvalidatesSelf();
  }

  // If type equals invalidation_set's type does nothing
  // if (invalidation_set->GetType() == type) {
  //   return *invalidation_set;
  // }

  return *invalidation_set;
}

InvalidationSet& RuleInvalidationSet::EnsureInvalidationSet(
    InvalidationSetMap& map, const std::string& key, InvalidationType type,
    PositionType position) {
  InvalidationSetPtr& invalidation_set = map[key];
  return EnsureMutableInvalidationSet(type, position, invalidation_set);
}

InvalidationSet& RuleInvalidationSet::EnsureInvalidationSet(
    PseudoTypeInvalidationSetMap& map, LynxCSSSelector::PseudoType key,
    InvalidationType type, PositionType position) {
  InvalidationSetPtr& invalidation_set = map[key];
  return EnsureMutableInvalidationSet(type, position, invalidation_set);
}

InvalidationSet& RuleInvalidationSet::EnsureClassInvalidationSet(
    const std::string& class_name, InvalidationType type,
    PositionType position) {
  DCHECK(!class_name.empty());
  return EnsureInvalidationSet(class_invalidation_sets_, class_name, type,
                               position);
}

// InvalidationSet& RuleInvalidationSet::EnsureAttributeInvalidationSet(
//     const std::string& attribute_name, InvalidationType type,
//     PositionType position) {
//   DCHECK(!attribute_name.empty());
//   return EnsureInvalidationSet(attribute_invalidation_sets_, attribute_name,
//                                type, position);
// }

InvalidationSet& RuleInvalidationSet::EnsureIdInvalidationSet(
    const std::string& id, InvalidationType type, PositionType position) {
  DCHECK(!id.empty());
  return EnsureInvalidationSet(id_invalidation_sets_, id, type, position);
}

InvalidationSet& RuleInvalidationSet::EnsurePseudoInvalidationSet(
    LynxCSSSelector::PseudoType pseudo_type, InvalidationType type,
    PositionType position) {
  DCHECK(pseudo_type != LynxCSSSelector::kPseudoUnknown);
  return EnsureInvalidationSet(pseudo_invalidation_sets_, pseudo_type, type,
                               position);
}

// For example, '.a.b' will return '.a', '.a#b' will return '#b', 'div.a' will
// return '.a'
void RuleInvalidationSet::ExtractInvalidationSetFeaturesFromSimpleSelector(
    const LynxCSSSelector& selector, InvalidationSetFeatures& features) {
  if (selector.Match() == LynxCSSSelector::kTag &&
      selector.Value() != CSSGlobalStarString()) {
    features.NarrowToTag(selector.Value());
    return;
  }
  if (selector.Match() == LynxCSSSelector::kId) {
    features.NarrowToId(selector.Value());
    return;
  }
  if (selector.Match() == LynxCSSSelector::kClass) {
    features.NarrowToClass(selector.Value());
    return;
  }
  // if (selector.IsAttributeSelector()) {
  //   features.NarrowToAttribute(selector.Attribute());
  //   return;
  // }
}

InvalidationSet* RuleInvalidationSet::InvalidationSetForSimpleSelector(
    const LynxCSSSelector& selector, InvalidationType type,
    PositionType position) {
  if (selector.Match() == LynxCSSSelector::kClass) {
    return &EnsureClassInvalidationSet(selector.Value(), type, position);
  }
  // if (selector.IsAttributeSelector()) {
  //   return &EnsureAttributeInvalidationSet(selector.Attribute(), type,
  //                                          position);
  // }
  if (selector.Match() == LynxCSSSelector::kId) {
    return &EnsureIdInvalidationSet(selector.Value(), type, position);
  }
  if (selector.Match() == LynxCSSSelector::kPseudoClass) {
    switch (selector.GetPseudoType()) {
      case LynxCSSSelector::kPseudoEmpty:
      case LynxCSSSelector::kPseudoFirstChild:
      case LynxCSSSelector::kPseudoFirstOfType:
      case LynxCSSSelector::kPseudoLastChild:
      case LynxCSSSelector::kPseudoLastOfType:
      case LynxCSSSelector::kPseudoOnlyChild:
      case LynxCSSSelector::kPseudoLink:
      case LynxCSSSelector::kPseudoVisited:
      case LynxCSSSelector::kPseudoHover:
      case LynxCSSSelector::kPseudoFocus:
      case LynxCSSSelector::kPseudoActive:
      case LynxCSSSelector::kPseudoChecked:
      case LynxCSSSelector::kPseudoEnabled:
      case LynxCSSSelector::kPseudoDefault:
      case LynxCSSSelector::kPseudoDisabled:
      case LynxCSSSelector::kPseudoState:
      case LynxCSSSelector::kPseudoLang:
      case LynxCSSSelector::kPseudoDir:
        return &EnsurePseudoInvalidationSet(selector.GetPseudoType(), type,
                                            position);
      default:
        break;
    }
  }
  return nullptr;
}

// Update all invalidation sets for a given CSS selector, this is usually
// called for the entire selector at top level, but can also end up calling
// itself recursively if any of the selectors contain selector lists
// (e.g. for :not()).
void RuleInvalidationSet::UpdateInvalidationSetsForComplex(
    const LynxCSSSelector& complex, InvalidationSetFeatures& features,
    PositionType position) {
  // Step 1. Note that this also, in passing, inserts self-invalidation
  // InvalidationSets for the rightmost compound selector. This probably
  // isn't the prettiest, but it's how the structure is at this point.
  // For example, '.a' will return a 'features' object with classes containing
  // 'a', and the last_in_compound is '.a' too.
  // Another example, '.a#b' will return a 'features' object with ids containing
  // 'b' because id is more important than class, and the last_in_compound is
  // '.b' too.
  const LynxCSSSelector* last_in_compound =
      ExtractInvalidationSetFeaturesFromCompound(complex, features, position);

  bool was_whole_subtree_invalid = features.WholeSubtreeInvalid();

  if (!features.HasFeatures()) features.SetWholeSubtreeInvalid(true);

  // Step 2. Add those features to the invalidation sets for the features
  // found in the other compound selectors (AddFeaturesToInvalidationSets).
  // If we find a feature in the right-most compound selector that requires a
  // subtree recalculation, next_compound will be the rightmost compound, and we
  // will AddFeaturesToInvalidationSets for that one as well.
  const LynxCSSSelector* next_compound = last_in_compound->TagHistory();
  // For example, '.a .b'
  if (next_compound) {
    // NOTE: We only support descendants
    if (SupportedRelation(last_in_compound->Relation())) {
      // Add next_compound in *_invalidation_sets_
      AddFeaturesToInvalidationSets(*next_compound, features);
    }
  }

  if (!next_compound) return;

  features.SetWholeSubtreeInvalid(was_whole_subtree_invalid);
}

void RuleInvalidationSet::ExtractInvalidationSetFeaturesFromSelectorList(
    const LynxCSSSelector& simple_selector, InvalidationSetFeatures& features,
    PositionType position) {
  const LynxCSSSelector* sub_selector = simple_selector.SelectorListSelector();
  if (!sub_selector) return;

  for (; sub_selector;
       sub_selector = LynxCSSSelectorList::Next(*sub_selector)) {
    InvalidationSetFeatures complex_features;
    UpdateInvalidationSetsForComplex(*sub_selector, complex_features, position);
  }
}

const LynxCSSSelector*
RuleInvalidationSet::ExtractInvalidationSetFeaturesFromCompound(
    const LynxCSSSelector& compound, InvalidationSetFeatures& features,
    PositionType position) {
  // NOTE: Due to the check at the bottom of the loop, this loop stops
  // once we are at the end of the compound, i.e., we see a relation that
  // is not a sub-selector. So for e.g. .a .b.c#d, we will see .b, .c, #d
  // and then stop, returning a pointer to #d.
  const LynxCSSSelector* simple_selector = &compound;
  for (;; simple_selector = simple_selector->TagHistory()) {
    ExtractInvalidationSetFeaturesFromSimpleSelector(*simple_selector,
                                                     features);
    // Create and add invalidation-set to *_invalidation_sets_
    if (InvalidationSet* invalidation_set = InvalidationSetForSimpleSelector(
            *simple_selector, InvalidationType::kInvalidateDescendants,
            position)) {
      if (position == kSubject) {
        invalidation_set->SetInvalidatesSelf();
      }
    }

    // For the :not pseudo class
    ExtractInvalidationSetFeaturesFromSelectorList(*simple_selector, features,
                                                   position);

    // Next should be another compound selector or null
    if (!simple_selector->TagHistory() ||
        simple_selector->Relation() != LynxCSSSelector::kSubSelector) {
      return simple_selector;
    }
  }
}

void RuleInvalidationSet::AddFeaturesToInvalidationSet(
    InvalidationSet& invalidation_set,
    const InvalidationSetFeatures& features) {
  if (features.WholeSubtreeInvalid()) invalidation_set.SetWholeSubtreeInvalid();
  if (features.WholeSubtreeInvalid()) {
    return;
  }

  for (const auto& id : features.ids) {
    invalidation_set.AddId(id);
  }
  for (const auto& tag_name : features.tag_names) {
    invalidation_set.AddTagName(tag_name);
  }

  for (const auto& class_name : features.classes) {
    invalidation_set.AddClass(class_name);
  }

  // for (const auto& attribute : features.attributes) {
  //   invalidation_set.AddAttribute(attribute);
  // }
}

void RuleInvalidationSet::AddFeaturesToInvalidationSetsForSimpleSelector(
    const LynxCSSSelector& simple_selector, const LynxCSSSelector& compound,
    InvalidationSetFeatures& descendant_features) {
  // Add invalidation-set to *_invalidation_sets_ with type kAncestor
  if (InvalidationSet* invalidation_set = InvalidationSetForSimpleSelector(
          simple_selector, InvalidationType::kInvalidateDescendants,
          kAncestor)) {
    // Only has descendant features
    // For example, if we have a selector, that is '.m .p', for class m we
    // only have a descendant containing class p
    AddFeaturesToInvalidationSet(*invalidation_set, descendant_features);
  }
}

const LynxCSSSelector*
RuleInvalidationSet::AddFeaturesToInvalidationSetsForCompoundSelector(
    const LynxCSSSelector& compound,
    InvalidationSetFeatures& descendant_features) {
  // NOTE: This loop is different from the one in
  // ExtractInvalidationSetFeaturesFromCompound but need to invoke
  // AddFeaturesToInvalidationSet
  // For example, for selector '.m .n.x .p' we will add features to
  // InvalidationSets, the result is '.m .p', '.n .p', '.x .p',
  // '.p'(SelfInvalidationSet).
  const LynxCSSSelector* simple_selector = &compound;
  for (; simple_selector; simple_selector = simple_selector->TagHistory()) {
    AddFeaturesToInvalidationSetsForSimpleSelector(*simple_selector, compound,
                                                   descendant_features);
    if (simple_selector->Relation() != LynxCSSSelector::kSubSelector) {
      break;
    }
    if (!simple_selector->TagHistory()) {
      break;
    }
  }

  return simple_selector;
}

void RuleInvalidationSet::AddFeaturesToInvalidationSets(
    const LynxCSSSelector& selector,
    InvalidationSetFeatures& descendant_features) {
  // The 'selector' is the selector immediately to the left of the rightmost
  // combinator. descendant_features has the features of the rightmost compound
  // selector.
  const LynxCSSSelector* compound = &selector;
  while (compound) {
    // NOTE: We only support descendants
    if (!SupportedRelation(compound->Relation())) {
      return;
    }

    // For example, for selector '.m .n.x .p' the loop is '.n' and '.m'
    const LynxCSSSelector* last_in_compound =
        AddFeaturesToInvalidationSetsForCompoundSelector(*compound,
                                                         descendant_features);
    DCHECK(last_in_compound);
    compound = last_in_compound->TagHistory();
  }
}

void RuleInvalidationSet::AddSelector(const LynxCSSSelector& selector) {
  InvalidationSetFeatures features;
  UpdateInvalidationSetsForComplex(selector, features, kSubject);
}

void RuleInvalidationSet::MergeInvalidationSet(
    InvalidationSetMap& map, const std::string& key,
    InvalidationSet* invalidation_set) {
  DCHECK(invalidation_set);
  InvalidationSetPtr& slot = map[key];
  EnsureMutableInvalidationSet(
      invalidation_set->GetType(),
      invalidation_set->IsSelfInvalidationSet() ? kSubject : kAncestor, slot)
      .Combine(*invalidation_set);
}

void RuleInvalidationSet::MergeInvalidationSet(
    PseudoTypeInvalidationSetMap& map, LynxCSSSelector::PseudoType key,
    InvalidationSet* invalidation_set) {
  DCHECK(invalidation_set);
  InvalidationSetPtr& slot = map[key];
  EnsureMutableInvalidationSet(
      invalidation_set->GetType(),
      invalidation_set->IsSelfInvalidationSet() ? kSubject : kAncestor, slot)
      .Combine(*invalidation_set);
}

bool RuleInvalidationSet::SupportedRelation(
    LynxCSSSelector::RelationType relation) {
  return relation == LynxCSSSelector::kSubSelector ||
         relation == LynxCSSSelector::kDescendant ||
         relation == LynxCSSSelector::kChild ||
         relation == LynxCSSSelector::kUAShadow;
}

void RuleInvalidationSet::Merge(const RuleInvalidationSet& other) {
  for (const auto& entry : other.class_invalidation_sets_)
    MergeInvalidationSet(class_invalidation_sets_, entry.first,
                         entry.second.get());
  // for (const auto& entry : other.attribute_invalidation_sets_)
  //   MergeInvalidationSet(attribute_invalidation_sets_, entry.first,
  //                        entry.second.get());
  for (const auto& entry : other.id_invalidation_sets_)
    MergeInvalidationSet(id_invalidation_sets_, entry.first,
                         entry.second.get());
  for (const auto& entry : other.pseudo_invalidation_sets_) {
    auto key = static_cast<LynxCSSSelector::PseudoType>(entry.first);
    MergeInvalidationSet(pseudo_invalidation_sets_, key, entry.second.get());
  }
}

void RuleInvalidationSet::Clear() {
  class_invalidation_sets_.clear();
  // attribute_invalidation_sets_.clear();
  id_invalidation_sets_.clear();
  pseudo_invalidation_sets_.clear();
}

void RuleInvalidationSet::CollectInvalidationSetsForClass(
    InvalidationLists& invalidation_lists,
    const std::string& class_name) const {
  auto it = class_invalidation_sets_.find(class_name);
  if (it == class_invalidation_sets_.end()) {
    return;
  }

  DescendantInvalidationSet* descendants;
  ExtractInvalidationSets(it->second.get(), descendants);

  if (descendants) {
    invalidation_lists.descendants.push_back(descendants);
  }
}

void RuleInvalidationSet::CollectInvalidationSetsForId(
    InvalidationLists& invalidation_lists, const std::string& id) const {
  auto it = id_invalidation_sets_.find(id);
  if (it == id_invalidation_sets_.end()) {
    return;
  }

  DescendantInvalidationSet* descendants;
  ExtractInvalidationSets(it->second.get(), descendants);

  if (descendants) {
    invalidation_lists.descendants.push_back(descendants);
  }
}

// void RuleInvalidationSet::CollectInvalidationSetsForAttribute(
//     InvalidationLists& invalidation_lists,
//     const std::string& attribute_name) const {
//   auto it = attribute_invalidation_sets_.find(attribute_name);
//   if (it == attribute_invalidation_sets_.end()) {
//     return;
//   }
//
//   DescendantInvalidationSet* descendants;
//   ExtractInvalidationSets(it->second.get(), descendants);
//
//   if (descendants) {
//     invalidation_lists.descendants.push_back(descendants);
//   }
//
// }

void RuleInvalidationSet::CollectInvalidationSetsForPseudoClass(
    InvalidationLists& invalidation_lists,
    LynxCSSSelector::PseudoType pseudo) const {
  auto it = pseudo_invalidation_sets_.find(pseudo);
  if (it == pseudo_invalidation_sets_.end()) {
    return;
  }

  DescendantInvalidationSet* descendants;
  ExtractInvalidationSets(it->second.get(), descendants);

  if (descendants) {
    invalidation_lists.descendants.push_back(descendants);
  }
}

bool RuleInvalidationSet::InvalidationSetFeatures::HasFeatures() const {
  return !classes.empty() || !ids.empty() || !tag_names.empty();
  // || !attributes.empty()
}

}  // namespace css
}  // namespace lynx
