// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/shared_css_fragment.h"

#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace tasm {

SharedCSSFragment::~SharedCSSFragment() = default;

CSSParseToken* SharedCSSFragment::GetCSSStyle(const std::string& key) {
  auto it = css_.find(key);
  if (it != css_.end()) {
    return it->second.get();
  }
  return nullptr;
}

std::shared_ptr<CSSParseToken> SharedCSSFragment::GetSharedCSSStyle(
    const std::string& key) {
  auto it = css_.find(key);
  if (it != css_.end()) {
    return it->second;
  }
  return nullptr;
}

CSSKeyframesToken* SharedCSSFragment::GetKeyframes(const std::string& key) {
  auto it = keyframes_.find(key);
  if (it != keyframes_.end()) {
    return it->second.get();
  }
  return nullptr;
}

const std::vector<std::shared_ptr<CSSFontFaceToken>>&
SharedCSSFragment::GetCSSFontFace(const std::string& key) {
  auto it = fontfaces_.find(key);
  if (it != fontfaces_.end()) {
    return it->second;
  }
  return GetDefaultFontFaceList();
}

#define SHARED_CSS_FRAGMENT_GET_STYLE(field, name)                             \
  CSSParseToken* SharedCSSFragment::Get##name##Style(const std::string& key) { \
    auto it = field.find(key);                                                 \
    if (it != field.end()) {                                                   \
      return it->second.get();                                                 \
    }                                                                          \
    return nullptr;                                                            \
  }

SHARED_CSS_FRAGMENT_GET_STYLE(pseudo_map_, Pseudo)
SHARED_CSS_FRAGMENT_GET_STYLE(cascade_map_, Cascade)
SHARED_CSS_FRAGMENT_GET_STYLE(id_map_, Id)
SHARED_CSS_FRAGMENT_GET_STYLE(tag_map_, Tag)
SHARED_CSS_FRAGMENT_GET_STYLE(universal_map_, Universal)
#undef SHARED_CSS_FRAGMENT_GET_STYLE

void SharedCSSFragment::ImportOtherFragment(SharedCSSFragment* fragment) {
  if (fragment == nullptr) return;
  if (fragment->HasTouchPseudoToken()) {
    // When ImportOtherFragment, if the previous fragment contains a touch
    // pseudo, mark the current fragment also has a touch pseudo. So that the
    // platform layer can judge whether to execute the pseudo related functions
    // according to whether it has a touch state pseudo-class
    MarkHasTouchPseudoToken();
  }
  for (auto& css : fragment->css_) {
    if (!enable_class_merge_) {
      css_[css.first] = css.second;
      continue;
    }
    const auto& selector = css.first;
    if (css_.find(selector) != css_.end()) {
      auto& depent_attribute = css.second->GetAttribute();
      StyleMap cur_attribute = css_[selector]->GetAttribute();
      for (auto& it : depent_attribute) {
        if (cur_attribute.find(it.first) == cur_attribute.end()) {
          cur_attribute[it.first] = std::move(it.second);
        }
      }
      css_[selector]->SetAttribute(cur_attribute);
    } else {
      css_[css.first] = css.second;
    }
  }
  for (auto& pseudo : fragment->pseudo_map_) {
    pseudo_map_[pseudo.first] = pseudo.second;
  }
  for (auto& child_pseudo : fragment->child_pseudo_map_) {
    child_pseudo_map_[child_pseudo.first] = child_pseudo.second;
  }
  for (auto& cascade : fragment->cascade_map_) {
    cascade_map_[cascade.first] = cascade.second;
  }
  for (auto& id : fragment->id_map_) {
    id_map_[id.first] = id.second;
  }
  for (auto& tag : fragment->tag_map_) {
    tag_map_[tag.first] = tag.second;
  }
  for (auto& universal : fragment->universal_map_) {
    universal_map_[universal.first] = universal.second;
  }
  for (auto& frame : fragment->keyframes_) {
    keyframes_[frame.first] = frame.second;
  }
  for (auto& face : fragment->fontfaces_) {
    fontfaces_[face.first] = face.second;
  }

  if (rule_set_ && fragment->rule_set_) {
    rule_set_->Merge(*fragment->rule_set_);
    if (rule_invalidation_set_ && fragment->rule_invalidation_set_)
      rule_invalidation_set_->Merge(*fragment->rule_invalidation_set_);
  }
}

void SharedCSSFragment::InitPseudoNotStyle() {
  if (pseudo_map_.empty()) {
    return;
  }
  if (pseudo_not_style_) {
    return;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY, INIT_PSEUDO_NOT_STYLE);
  pseudo_not_style_ = PseudoNotStyle();
  PseudoClassStyleMap global_pseudo_not_tag, global_pseudo_not_class,
      global_pseudo_not_id;

  for (auto& it : pseudo_map_) {
    const std::string& key_name = it.first;

    // mark if has pseudo style
    if (!it.second || !it.second->IsPseudoStyleToken()) {
      // if :not is not used, do not run the code bellow
      continue;
    }

    size_t pseudo_not_loc = key_name.find(":not(");
    if (pseudo_not_loc != std::string::npos) {
      has_pseudo_not_style_ = true;
      size_t loc = key_name.find_first_of("(");

      // 找出 :not() 括号里的 scope 作用范围以及 selector 的类型
      std::string scope_for_pseudo_not =
          key_name.substr(loc + 1, key_name.size() - loc - 2);
      std::string selector_key = key_name.substr(0, pseudo_not_loc);

      PseudoNotContent content;
      content.selector_key = selector_key;
      content.scope = scope_for_pseudo_not;
      std::string selector_key_type = selector_key.substr(0, 1);
      std::string scope_value_type = scope_for_pseudo_not.substr(0, 1);
      bool is_global_pseudo_not_css = selector_key.compare("") == 0;
      if (selector_key.compare(scope_for_pseudo_not) == 0) {
        // 当出现类似于.class:not(.class)这种情况时，:not失效
        continue;
      }

      if (scope_value_type.compare(".") == 0) {
        content.scope_type = CSSSheet::CLASS_SELECT;
        if (is_global_pseudo_not_css) {
          global_pseudo_not_class.insert({key_name, content});
        }
      } else if (scope_value_type.compare("#") == 0) {
        content.scope_type = CSSSheet::ID_SELECT;
        if (is_global_pseudo_not_css) {
          global_pseudo_not_id.insert({key_name, content});
        }
      } else {
        content.scope_type = CSSSheet::NAME_SELECT;
        if (is_global_pseudo_not_css) {
          global_pseudo_not_tag.insert({key_name, content});
        }
      }

      if (is_global_pseudo_not_css) {
        // 存储解析后 global :not() 里的内容
        pseudo_not_style_->pseudo_not_global_map.insert(
            {CSSSheet::NAME_SELECT, global_pseudo_not_tag});
        pseudo_not_style_->pseudo_not_global_map.insert(
            {CSSSheet::CLASS_SELECT, global_pseudo_not_class});
        pseudo_not_style_->pseudo_not_global_map.insert(
            {CSSSheet::ID_SELECT, global_pseudo_not_id});
      } else if (selector_key_type.compare(".") == 0) {
        pseudo_not_style_->pseudo_not_for_class.insert({key_name, content});
      } else if (selector_key_type.compare("#") == 0) {
        pseudo_not_style_->pseudo_not_for_id.insert({key_name, content});
      } else {
        pseudo_not_style_->pseudo_not_for_tag.insert({key_name, content});
      }
    }
  }
}

// replace all member variable with new SharedCSSFragment
void SharedCSSFragment::ReplaceByNewFragment(SharedCSSFragment* new_fragment) {
#if ENABLE_HMR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, REPLACE_VARIABLE_BY_NEW_FRAGMENT);
  is_baked_ = false;
  enable_class_merge_ = new_fragment->enable_class_merge();
  dependent_ids_ = new_fragment->dependent_ids();
  id_ = new_fragment->id_;
  css_ = new_fragment->css_;
  id_map_ = new_fragment->id_map_;
  tag_map_ = new_fragment->tag_map_;
  universal_map_ = new_fragment->universal_map_;
  pseudo_map_ = new_fragment->pseudo_map_;
  cascade_map_ = new_fragment->cascade_map_;
  keyframes_ = new_fragment->keyframes();
  fontfaces_ = new_fragment->fontfaces();
  if (new_fragment->HasPseudoNotStyle()) {
    pseudo_not_style_ = std::make_optional(new_fragment->pseudo_not_style());
  }
  enable_css_selector_ = new_fragment->enable_css_selector_;
  if (new_fragment->rule_set_) {
    rule_set_ = std::make_unique<css::RuleSet>(*new_fragment->rule_set_);
  }
  if (new_fragment->rule_invalidation_set_) {
    rule_invalidation_set_ = std::make_unique<css::RuleInvalidationSet>();
    rule_invalidation_set_->Merge(*new_fragment->rule_invalidation_set_);
  }
  has_pseudo_not_style_ = new_fragment->HasPseudoNotStyle();
#endif
}

void SharedCSSFragment::FindSpecificMapAndAdd(
    const std::string& key, const std::shared_ptr<CSSParseToken>& parse_token) {
  if (parse_token->IsCascadeSelectorStyleToken()) {
    cascade_map_.emplace(key, parse_token);
  }
  int type = parse_token->GetStyleTokenType();
  if (type > CSSSheet::NAME_SELECT && type != CSSSheet::ALL_SELECT) {
    pseudo_map_.emplace(key, parse_token);
    if ((type & CSSSheet::FIRST_CHILD_SELECT) ||
        (type & CSSSheet::LAST_CHILD_SELECT)) {
      child_pseudo_map_.emplace(key, parse_token);
    }
  } else if (type == CSSSheet::ID_SELECT) {
    id_map_.emplace(key, parse_token);
  } else if (type == CSSSheet::NAME_SELECT) {
    tag_map_.emplace(key, parse_token);
  } else if (type == CSSSheet::ALL_SELECT) {
    universal_map_.emplace(key, parse_token);
  }
}

void SharedCSSFragment::AddStyleRule(
    std::unique_ptr<css::LynxCSSSelector[]> selector_arr,
    std::shared_ptr<CSSParseToken> parse_token) {
#ifndef BUILD_LEPUS
  // We know the pointer is not empty
  rule_set_->AddStyleRule(std::make_unique<css::StyleRule>(
      std::move(selector_arr), std::move(parse_token)));
#endif
}

void SharedCSSFragment::CollectInvalidationSetsForId(
    css::InvalidationLists& lists, const std::string& id) {
#ifndef BUILD_LEPUS
  if (rule_invalidation_set_) {
    rule_invalidation_set_->CollectInvalidationSetsForId(lists, id);
  }
#endif
}

void SharedCSSFragment::CollectInvalidationSetsForClass(
    css::InvalidationLists& lists, const std::string& class_name) {
#ifndef BUILD_LEPUS
  if (rule_invalidation_set_) {
    rule_invalidation_set_->CollectInvalidationSetsForClass(lists, class_name);
  }
#endif
}

void SharedCSSFragment::CollectInvalidationSetsForPseudoClass(
    css::InvalidationLists& lists, css::LynxCSSSelector::PseudoType pseudo) {
#ifndef BUILD_LEPUS
  if (rule_invalidation_set_) {
    rule_invalidation_set_->CollectInvalidationSetsForPseudoClass(lists,
                                                                  pseudo);
  }
#endif
}

}  // namespace tasm
}  // namespace lynx
