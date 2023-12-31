// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_FRAGMENT_H_
#define LYNX_CSS_CSS_FRAGMENT_H_

#include <memory>
#include <optional>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "css/css_font_face_token.h"
#include "css/css_keyframes_token.h"
#include "css/css_parser_token.h"
#include "css/ng/invalidation/invalidation_set.h"
#include "css/ng/style/rule_set.h"

namespace lynx {
namespace tasm {

struct PseudoNotContent {
  CSSSheet::SheetType scope_type;
  std::string selector_key;
  std::string scope;
};

struct LynxCSSSelectorTuple {
  std::string selector_key;
  size_t flattened_size;
  std::unique_ptr<css::LynxCSSSelector[]> selector_arr;
  std::shared_ptr<CSSParseToken> parse_token;
};

using PseudoClassStyleMap = std::unordered_map<std::string, PseudoNotContent>;

using CSSParserTokenMap =
    std::unordered_map<std::string, std::shared_ptr<CSSParseToken>>;

using CSSKeyframesTokenMap =
    std::unordered_map<std::string, std::shared_ptr<CSSKeyframesToken>>;

using CSSFontFaceTokenMap =
    std::unordered_map<std::string,
                       std::vector<std::shared_ptr<CSSFontFaceToken>>>;

struct PseudoNotStyle {
  PseudoClassStyleMap pseudo_not_for_tag;
  PseudoClassStyleMap pseudo_not_for_class;
  PseudoClassStyleMap pseudo_not_for_id;
  std::unordered_map<int, PseudoClassStyleMap> pseudo_not_global_map;
};

class CSSFragment {
 public:
  CSSFragment() = default;
  virtual ~CSSFragment() = default;

  virtual const CSSParserTokenMap& pseudo_map() = 0;
  virtual const CSSParserTokenMap& child_pseudo_map() = 0;
  virtual const CSSParserTokenMap& cascade_map() = 0;
  virtual const CSSParserTokenMap& css() = 0;
  virtual css::RuleSet* rule_set() = 0;
  virtual const std::vector<LynxCSSSelectorTuple>& selector_tuple() = 0;
  virtual const CSSKeyframesTokenMap& keyframes() = 0;
  virtual const CSSFontFaceTokenMap& fontfaces() = 0;
  virtual const PseudoNotStyle& pseudo_not_style() = 0;

  virtual CSSParseToken* GetCSSStyle(const std::string& key) = 0;
  // The GetCSSStyle() call returns raw pointer and is thus non-ideal.
  virtual std::shared_ptr<CSSParseToken> GetSharedCSSStyle(
      const std::string& key) = 0;
  virtual CSSParseToken* GetPseudoStyle(const std::string& key) = 0;
  virtual CSSParseToken* GetCascadeStyle(const std::string& key) = 0;
  virtual CSSParseToken* GetIdStyle(const std::string& key) = 0;
  virtual CSSParseToken* GetTagStyle(const std::string& key) = 0;
  virtual CSSParseToken* GetUniversalStyle(const std::string& key) = 0;
  virtual CSSKeyframesToken* GetKeyframes(const std::string& key) = 0;
  virtual const std::vector<std::shared_ptr<CSSFontFaceToken>>& GetCSSFontFace(
      const std::string& key) = 0;
  virtual bool HasPseudoNotStyle() = 0;
  virtual void InitPseudoNotStyle() = 0;

  bool HasPseudoStyle() { return !pseudo_map().empty(); }

  bool HasCascadeStyle() { return !cascade_map().empty(); }
  void PrintStyles();

  bool HasFontFacesResolved() const { return has_font_faces_resolved_; }

  void MarkFontFacesResolved(bool resolved) {
    has_font_faces_resolved_ = resolved;
  }

  void MarkHasTouchPseudoToken() { has_touch_pseudo_token_ = true; }
  bool HasTouchPseudoToken() { return has_touch_pseudo_token_; }
  const std::vector<std::shared_ptr<CSSFontFaceToken>>&
  GetDefaultFontFaceList();

  virtual bool HasIdSelector() { return true; }

  virtual bool enable_css_selector() = 0;

  virtual bool enable_css_invalidation() = 0;

  virtual void CollectInvalidationSetsForId(css::InvalidationLists& lists,
                                            const std::string& id) = 0;

  virtual void CollectInvalidationSetsForClass(
      css::InvalidationLists& lists, const std::string& class_name) = 0;

  virtual void CollectInvalidationSetsForPseudoClass(
      css::InvalidationLists& lists,
      css::LynxCSSSelector::PseudoType pseudo) = 0;

 protected:
  std::optional<PseudoNotStyle> pseudo_not_style_;
  bool has_pseudo_not_style_ = false;
  bool has_touch_pseudo_token_{false};
  // FIXME(linxs): it's better to flush related fontface or keyframe only when
  // any element has font-family or animation indicated the font faces has been
  // resolved or not
  bool has_font_faces_resolved_{false};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_FRAGMENT_H_
