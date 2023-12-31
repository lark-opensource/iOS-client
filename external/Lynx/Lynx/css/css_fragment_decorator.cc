// Copyright 2021 The Lynx Authors. All rights reserved.

#include "css/css_fragment_decorator.h"

#include "base/no_destructor.h"
#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace tasm {

CSSFragmentDecorator::~CSSFragmentDecorator() = default;

const CSSParserTokenMap& CSSFragmentDecorator::pseudo_map() {
  if (!intrinsic_style_sheets_) {
    static base::NoDestructor<CSSParserTokenMap> fake_pseudo{};
    return *fake_pseudo;
  }
  return intrinsic_style_sheets_->pseudo_map();
}

const CSSParserTokenMap& CSSFragmentDecorator::child_pseudo_map() {
  if (!intrinsic_style_sheets_) {
    static base::NoDestructor<CSSParserTokenMap> fake_child_pseudo{};
    return *fake_child_pseudo;
  }
  return intrinsic_style_sheets_->child_pseudo_map();
}

const PseudoNotStyle& CSSFragmentDecorator::pseudo_not_style() {
  if (!intrinsic_style_sheets_) {
    static base::NoDestructor<PseudoNotStyle> fake_pseudo_not_style{};
    return *fake_pseudo_not_style;
  }
  return intrinsic_style_sheets_->pseudo_not_style();
}

const CSSParserTokenMap& CSSFragmentDecorator::css() {
  PopulateCacheIfNeeded();
  if (!css_cache_.empty()) {
    return css_cache_;
  } else if (intrinsic_style_sheets_) {
    return intrinsic_style_sheets_->css();
  }
  return css_cache_;
}

const CSSParserTokenMap& CSSFragmentDecorator::cascade_map() {
  if (!intrinsic_style_sheets_) {
    static base::NoDestructor<CSSParserTokenMap> fake_cascade{};
    return *fake_cascade;
  }
  return intrinsic_style_sheets_->cascade_map();
}

const CSSKeyframesTokenMap& CSSFragmentDecorator::keyframes() {
  if (!intrinsic_style_sheets_) {
    static base::NoDestructor<CSSKeyframesTokenMap> fake_keyframes{};
    return *fake_keyframes;
  }
  return intrinsic_style_sheets_->keyframes();
}

css::RuleSet* CSSFragmentDecorator::rule_set() {
  if (!intrinsic_style_sheets_) {
    return nullptr;
  }
  return intrinsic_style_sheets_->rule_set();
}

const std::vector<LynxCSSSelectorTuple>&
CSSFragmentDecorator::selector_tuple() {
  if (!intrinsic_style_sheets_) {
    static base::NoDestructor<std::vector<LynxCSSSelectorTuple>>
        fake_selector_tuple{};
    return *fake_selector_tuple;
  }
  return intrinsic_style_sheets_->selector_tuple();
}

const CSSFontFaceTokenMap& CSSFragmentDecorator::fontfaces() {
  if (!intrinsic_style_sheets_) {
    static base::NoDestructor<CSSFontFaceTokenMap> fake_fontfaces{};
    return *fake_fontfaces;
  }
  return intrinsic_style_sheets_->fontfaces();
}

CSSParseToken* CSSFragmentDecorator::GetCSSStyle(const std::string& key) {
  PopulateCacheIfNeeded();
  if (!css_cache_.empty()) {
    auto it = css_cache_.find(key);
    if (it != css_cache_.end()) {
      return it->second.get();
    }
  } else if (intrinsic_style_sheets_) {
    return intrinsic_style_sheets_->GetCSSStyle(key);
  }
  return nullptr;
}

CSSKeyframesToken* CSSFragmentDecorator::GetKeyframes(const std::string& key) {
  if (!intrinsic_style_sheets_) {
    return nullptr;
  }
  return intrinsic_style_sheets_->GetKeyframes(key);
}

const std::vector<std::shared_ptr<CSSFontFaceToken>>&
CSSFragmentDecorator::GetCSSFontFace(const std::string& key) {
  if (!intrinsic_style_sheets_) {
    return GetDefaultFontFaceList();
  }
  return intrinsic_style_sheets_->GetCSSFontFace(key);
}

void CSSFragmentDecorator::PopulateCacheIfNeeded() {
  if (external_css_.empty()) {
    // External styles is empty, no need to cache.
    return;
  }
  if (!css_cache_.empty()) {
    // css_ has already been cached
    return;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "CSSFragmentDecorator::PopulateCacheIfNeeded");
  // External styles overrides component intrinsic styles.
  css_cache_ = external_css_;
  if (intrinsic_style_sheets_) {
    css_cache_.insert(intrinsic_style_sheets_->css().begin(),
                      intrinsic_style_sheets_->css().end());
    if (intrinsic_style_sheets_->enable_css_selector()) {
      for (auto& ext_css : external_css_) {
        intrinsic_style_sheets_->rule_set()->AddToRuleSet(ext_css.first,
                                                          ext_css.second);
      }
    }
  }
}

std::shared_ptr<CSSParseToken> CSSFragmentDecorator::GetSharedCSSStyle(
    const std::string& key) {
  PopulateCacheIfNeeded();

  if (!css_cache_.empty()) {
    auto it = css_cache_.find(key);
    if (it != css_cache_.end()) {
      return it->second;
    }
  } else if (intrinsic_style_sheets_) {
    return intrinsic_style_sheets_->GetSharedCSSStyle(key);
  }
  return nullptr;
}

void CSSFragmentDecorator::AddExternalStyle(
    const std::string& key, std::shared_ptr<CSSParseToken> value) {
  // A new independent attribute map is needed for each component instance, as
  // multiple external tokens may merge to become the new token.
  if (external_css_.find(key) == external_css_.end()) {
    external_css_[key] =
        std::shared_ptr<CSSParseToken>(new CSSParseToken(*value));
    return;
  }

  for (auto it : value->GetAttribute()) {
    external_css_[key]->SetAttribute(it.first, it.second);
  }
}

bool CSSFragmentDecorator::HasPseudoNotStyle() {
  if (intrinsic_style_sheets_) {
    return intrinsic_style_sheets_->HasPseudoNotStyle();
  }
  return false;
}

void CSSFragmentDecorator::InitPseudoNotStyle() {
  if (intrinsic_style_sheets_) {
    intrinsic_style_sheets_->InitPseudoNotStyle();
  }
}

#define GET_PARSER_TOKEN_STYLE(name)                         \
  CSSParseToken* CSSFragmentDecorator::Get##name##Style(     \
      const std::string& key) {                              \
    if (intrinsic_style_sheets_) {                           \
      return intrinsic_style_sheets_->Get##name##Style(key); \
    }                                                        \
    return nullptr;                                          \
  }

GET_PARSER_TOKEN_STYLE(Pseudo)
GET_PARSER_TOKEN_STYLE(Cascade)
GET_PARSER_TOKEN_STYLE(Id)
GET_PARSER_TOKEN_STYLE(Tag)
GET_PARSER_TOKEN_STYLE(Universal)
#undef GET_PARSER_TOKEN_STYLE

}  // namespace tasm
}  // namespace lynx
