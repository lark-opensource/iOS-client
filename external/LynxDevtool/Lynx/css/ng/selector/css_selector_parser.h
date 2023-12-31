// Copyright 2022 The Lynx Authors. All rights reserved.
// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_CSS_NG_SELECTOR_CSS_SELECTOR_PARSER_H_
#define LYNX_CSS_NG_SELECTOR_CSS_SELECTOR_PARSER_H_

#include <memory>
#include <optional>
#include <utility>
#include <vector>

#include "css/ng/parser/css_parser_token_range.h"
#include "css/ng/selector/lynx_css_parser_selector.h"

namespace lynx {
namespace css {

class CSSParserContext;
class CSSParserTokenStream;
class LynxCSSSelectorList;
class StyleSheetContents;
class CSSParserObserver;

// SelectorVector is the list of CSS selectors as it is parsed,
// where each selector can contain others (in a tree). Typically,
// before actual use, you would convert it into a flattened list using
// LynxCSSParserSelector::AdoptSelectorVector(), but it can be useful to have
// this temporary form to find out e.g. how many bytes it will occupy (e.g. in
// StyleRule::Create) before you actually make that allocation.
using LynxCSSSelectorVector =
    std::vector<std::unique_ptr<LynxCSSParserSelector>>;

// FIXME: We should consider building CSSSelectors directly instead of using
// the intermediate LynxCSSParserSelector.
class CSSSelectorParser {
 public:
  // Both ParseSelector() and ConsumeSelector() return an empty list
  // on error.
  static LynxCSSSelectorVector ParseSelector(CSSParserTokenRange,
                                             const CSSParserContext*,
                                             StyleSheetContents* = nullptr);
  static LynxCSSSelectorVector ConsumeSelector(CSSParserTokenStream&,
                                               const CSSParserContext*,
                                               StyleSheetContents*,
                                               CSSParserObserver* = nullptr);

  static bool ConsumeANPlusB(CSSParserTokenRange&, std::pair<int, int>&);

  static LynxCSSSelector::PseudoType ParsePseudoType(const std::u16string&,
                                                     bool has_arguments);
  // Finds out how many elements one would need to allocate for
  // AdoptSelectorVector(), ie., storing the selector tree as a flattened list.
  // The returned count is in LynxCSSSelector elements, not bytes.
  static size_t FlattenedSize(const LynxCSSSelectorVector& selector_vector);
  static LynxCSSSelectorList AdoptSelectorVector(
      LynxCSSSelectorVector& selector_vector);
  static void AdoptSelectorVector(LynxCSSSelectorVector& selector_vector,
                                  LynxCSSSelector* selector_array,
                                  size_t flattened_size);

 private:
  CSSSelectorParser(const CSSParserContext*, StyleSheetContents* = nullptr);

  // These will all consume trailing comments if successful

  LynxCSSSelectorVector ConsumeComplexSelectorList(CSSParserTokenRange&);
  LynxCSSSelectorVector ConsumeComplexSelectorList(CSSParserTokenStream&,
                                                   CSSParserObserver*);
  LynxCSSSelectorList ConsumeCompoundSelectorList(CSSParserTokenRange&);
  // Consumes a complex selector list if inside_compound_pseudo_ is false,
  // otherwise consumes a compound selector list.
  LynxCSSSelectorList ConsumeNestedSelectorList(CSSParserTokenRange&);
  LynxCSSSelectorList ConsumeForgivingNestedSelectorList(CSSParserTokenRange&);
  // https://drafts.csswg.org/selectors/#typedef-forgiving-selector-list
  LynxCSSSelectorList ConsumeForgivingComplexSelectorList(CSSParserTokenRange&);
  LynxCSSSelectorList ConsumeForgivingCompoundSelectorList(
      CSSParserTokenRange&);
  // https://drafts.csswg.org/selectors/#typedef-relative-selector-list
  LynxCSSSelectorList ConsumeForgivingRelativeSelectorList(
      CSSParserTokenRange&);

  std::unique_ptr<LynxCSSParserSelector> ConsumeRelativeSelector(
      CSSParserTokenRange&);
  std::unique_ptr<LynxCSSParserSelector> ConsumeComplexSelector(
      CSSParserTokenRange&);

  // ConsumePartialComplexSelector() method provides the common logic of
  // consuming a complex selector and consuming a relative selector.
  //
  // After consuming the left-most combinator of a relative selector, we can
  // consume the remaining selectors with the common logic.
  // For example, after consuming the left-most combinator '~' of the relative
  // selector '~ .a ~ .b', we can consume remaining selectors '.a ~ .b'
  // with this method.
  //
  // After consuming the left-most compound selector and a combinator of a
  // complex selector, we can also use this method to consume the remaining
  // selectors of the complex selector.
  std::unique_ptr<LynxCSSParserSelector> ConsumePartialComplexSelector(
      CSSParserTokenRange&,
      LynxCSSSelector::RelationType& /* current combinator */,
      std::unique_ptr<LynxCSSParserSelector> /* previous compound selector */,
      unsigned& /* previous compound flags */);

  std::unique_ptr<LynxCSSParserSelector> ConsumeCompoundSelector(
      CSSParserTokenRange&);
  // This doesn't include element names, since they're handled specially
  std::unique_ptr<LynxCSSParserSelector> ConsumeSimpleSelector(
      CSSParserTokenRange&);

  bool ConsumeName(CSSParserTokenRange&, std::u16string& name,
                   std::u16string& namespace_prefix);

  // These will return nullptr when the selector is invalid
  std::unique_ptr<LynxCSSParserSelector> ConsumeId(CSSParserTokenRange&);
  std::unique_ptr<LynxCSSParserSelector> ConsumeClass(CSSParserTokenRange&);
  std::unique_ptr<LynxCSSParserSelector> ConsumePseudo(CSSParserTokenRange&);
  std::unique_ptr<LynxCSSParserSelector> ConsumeAttribute(CSSParserTokenRange&);

  LynxCSSSelector::RelationType ConsumeCombinator(CSSParserTokenRange&);
  LynxCSSSelector::MatchType ConsumeAttributeMatch(CSSParserTokenRange&);
  LynxCSSSelector::AttributeMatchType ConsumeAttributeFlags(
      CSSParserTokenRange&);

  const std::u16string& DefaultNamespace() const;
  const std::u16string& DetermineNamespace(const std::u16string& prefix);
  void PrependTypeSelectorIfNeeded(const std::u16string& namespace_prefix,
                                   bool has_element_name,
                                   const std::u16string& element_name,
                                   LynxCSSParserSelector*);
  static std::unique_ptr<LynxCSSParserSelector> AddSimpleSelectorToCompound(
      std::unique_ptr<LynxCSSParserSelector> compound_selector,
      std::unique_ptr<LynxCSSParserSelector> simple_selector);
  static std::unique_ptr<LynxCSSParserSelector>
  SplitCompoundAtImplicitShadowCrossingCombinator(
      std::unique_ptr<LynxCSSParserSelector> compound_selector);
  void RecordUsageAndDeprecations(const LynxCSSSelectorVector&) {}

  const CSSParserContext* context_;

  bool failed_parsing_ = false;
  bool disallow_pseudo_elements_ = false;
  // If we're inside a pseudo class that only accepts compound selectors,
  // for example :host, inner :is()/:where() pseudo classes are also only
  // allowed to contain compound selectors.
  bool inside_compound_pseudo_ = false;
  // When parsing a compound which includes a pseudo-element, the simple
  // selectors permitted to follow that pseudo-element may be restricted.
  // If this is the case, then restricting_pseudo_element_ will be set to the
  // PseudoType of the pseudo-element causing the restriction.
  LynxCSSSelector::PseudoType restricting_pseudo_element_ =
      LynxCSSSelector::kPseudoUnknown;
  // If we're _resisting_ the default namespace, it means that we are inside
  // a nested selector (:is(), :where(), etc) where we should _consider_
  // ignoring the default namespace (depending on circumstance). See the
  // relevant spec text [1] regarding default namespaces for information about
  // those circumstances.
  //
  // [1] https://drafts.csswg.org/selectors/#matches
  bool resist_default_namespace_ = false;
  // While this flag is true, the default namespace is ignored. In other words,
  // the default namespace is '*' while this flag is true.
  bool ignore_default_namespace_ = false;

  // The 'found_pseudo_in_has_argument_' flag is true when we found any pseudo
  // in :has() argument while parsing.
  bool found_pseudo_in_has_argument_ = false;
  bool is_inside_has_argument_ = false;

  // The 'found_complex_logical_combinations_in_has_argument_' flag is true when
  // we found any logical combinations (:is(), :where(), :not()) containing
  // complex selector in :has() argument while parsing.
  bool found_complex_logical_combinations_in_has_argument_ = false;
  bool is_inside_logical_combination_in_has_argument_ = false;

  class DisallowPseudoElementsScope {
   public:
    DisallowPseudoElementsScope(CSSSelectorParser* parser)
        : parser_(parser), was_disallowed_(parser_->disallow_pseudo_elements_) {
      parser_->disallow_pseudo_elements_ = true;
    }
    DisallowPseudoElementsScope(const DisallowPseudoElementsScope&) = delete;
    DisallowPseudoElementsScope& operator=(const DisallowPseudoElementsScope&) =
        delete;

    ~DisallowPseudoElementsScope() {
      parser_->disallow_pseudo_elements_ = was_disallowed_;
    }

   private:
    CSSSelectorParser* parser_;
    bool was_disallowed_;
  };
};

}  // namespace css
}  // namespace lynx

#endif  // LYNX_CSS_NG_SELECTOR_CSS_SELECTOR_PARSER_H_
