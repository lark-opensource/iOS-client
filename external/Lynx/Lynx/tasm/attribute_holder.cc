// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/attribute_holder.h"

#include <algorithm>
#include <map>
#include <set>
#include <string>

#include "tasm/value_utils.h"

#ifdef ENABLE_TEST_DUMP
#include <regex>
#endif

#include "lepus/table.h"
#include "tasm/radon/radon_component.h"
#include "tasm/react/element.h"

namespace lynx {
namespace tasm {

bool AttributeHolder::ContainsIdSelector(const std::string& selector) const {
  return idSelector().str() == selector;
}

bool AttributeHolder::ContainsClassSelector(const std::string& selector) const {
  for (const auto& c : classes()) {
    if (c.str() == selector) {
      return true;
    }
  }
  return false;
}

bool AttributeHolder::ContainsTagSelector(const std::string& selector) const {
  return tag().str() == selector;
}

// "[attribute]" or "[attribute=value]"
bool AttributeHolder::ContainsAttributeSelector(
    const std::string& selector) const {
  // check "[" and "]"
  if (selector.front() != '[' || selector.back() != ']') {
    return false;
  }

  // check "="
  auto pos = selector.find('=');
  std::string key;
  std::string value;
  if (pos == std::string::npos) {
    key = selector.substr(1, selector.size() - 2);
  } else {
    key = selector.substr(1, pos - 1);
    value = selector.substr(pos + 1, selector.size() - pos - 2);
  }

  if (key.substr(0, 5) == "data-") {
    key = key.substr(5);
    return data_set_.find(key) != data_set_.end() &&
           (value.empty() || data_set_.at(key).ToString() == value);
  } else {
    return attributes_.find(key) != attributes_.end() &&
           (value.empty() || attributes_.at(key).first.ToString() == value);
  }
}

bool AttributeHolder::ContainsSelector(const std::string& selector) const {
  if (selector.empty()) {
    return false;
  }

  for (auto begin = selector.cbegin(); begin != selector.cend();) {
    auto end = std::find_if(std::next(begin), selector.cend(),
                            [](char c) { return c == '.' || c == '['; });
    bool skip_first_char = *begin == '#' || *begin == '.';
    std::string single_selector;
    std::copy(std::next(begin, skip_first_char), end,
              std::back_inserter(single_selector));

    bool result;
    switch (*begin) {
      case '#': {
        result = ContainsIdSelector(single_selector);
        break;
      }
      case '.': {
        result = ContainsClassSelector(single_selector);
        break;
      }
      case '[': {
        result = ContainsAttributeSelector(single_selector);
        break;
      }
      default: {
        result = ContainsTagSelector(single_selector);
        break;
      }
    }

    if (!result) {
      return false;
    }
    begin = end;
  }

  return true;
}

void AttributeHolder::UpdateCSSVariableFromSetProperty(
    const lepus::String& key, const lepus::String& value) {
  cached_styles_.clear();
  css_variables_from_js_[key] = value;
}

void AttributeHolder::MergeWithCSSVariables(
    lepus::Value& css_variable_updated) {
  if (css_variable_updated.IsTable()) {
    auto& css_variable_updated_table = *css_variable_updated.Table();
    for (auto& pair : css_variable_updated_table) {
      auto key = pair.first.impl();
      auto it = css_variables_from_js_.find(key);
      if (it != css_variables_from_js_.end()) {
        pair.second.SetString(it->second.impl());
        continue;
      }

      it = css_variables_.find(key);
      if (it != css_variables_.end()) {
        pair.second.SetString(it->second.impl());
      }
    }
  }
};

void AttributeHolder::Reset() {
  has_dynamic_class_ = false;
  cached_styles_.clear();
  classes_.clear();
  inline_styles_.clear();
  attributes_.clear();
  data_set_.clear();
  static_events_.clear();
  lepus_events_.clear();
  has_dynamic_inline_style_ = false;
  has_dynamic_attr_ = false;
  id_selector_ = lepus::String();
}

void AttributeHolder::SetDataSet(const lepus::Value& data_set) {
  ForEachLepusValue(data_set,
                    [this](const lepus::Value& key, const lepus::Value& val) {
                      data_set_[key.String()] = val;
                    });
}

void AttributeHolder::RemoveEvent(const lepus::String& name,
                                  const lepus::String& type) {
  if (type == kGlobalBind) {
    global_bind_events_.erase(name);
  } else {
    static_events_.erase(name);
  }
}

void AttributeHolder::RemoveAllEvents() {
  static_events_.clear();
  lepus_events_.clear();
  global_bind_events_.clear();
}

AttributeHolder* AttributeHolder::SelectorMatchingParent() const {
  if (!element_) {
    // Use HolderParent when element is empty, radon mode
    return HolderParent();
  }
  if (!element_->parent()) {
    return nullptr;
  }
  DCHECK(element_->is_fiber_element());
  // We know the element is fiber element,
  // descendant selector only works in current component scope
  if (static_cast<FiberElement*>(element_->parent())->is_component() &&
      !element_->element_manager()->GetRemoveDescendantSelectorScope()) {
    return nullptr;
  }
  return element_->parent()->data_model();
}

// RadonNode override this method, so only work in fiber mode
AttributeHolder* AttributeHolder::HolderParent() const {
  if (!element_ || !element_->parent()) {
    return nullptr;
  }
  return element_->parent()->data_model();
}

AttributeHolder* AttributeHolder::NextSibling() const {
  if (!element_) {
    return nullptr;
  }
  if (auto* sibling = element_->next_sibling()) {
    return sibling->data_model();
  }
  return nullptr;
}

AttributeHolder* AttributeHolder::PreviousSibling() const {
  if (!element_) {
    return nullptr;
  }
  if (auto* sibling = element_->previous_sibling()) {
    return sibling->data_model();
  }
  return nullptr;
}

size_t AttributeHolder::ChildCount() const {
  if (!element_) {
    return 0;
  }
  return element_->GetChildCount();
}

void AttributeHolder::CollectIdChangedInvalidation(
    CSSFragment* style_sheet, css::InvalidationLists& lists,
    const std::string& old_id, const std::string& new_id) {
  // We know the style_sheet is not empty
  if (!old_id.empty()) style_sheet->CollectInvalidationSetsForId(lists, old_id);
  if (!new_id.empty()) style_sheet->CollectInvalidationSetsForId(lists, new_id);
}

void AttributeHolder::CollectClassChangedInvalidation(
    CSSFragment* style_sheet, css::InvalidationLists& lists,
    const ClassList& old_classes, const ClassList& new_classes) {
  if (old_classes.empty()) {
    for (auto& class_name : new_classes) {
      style_sheet->CollectInvalidationSetsForClass(lists, class_name.str());
    }
  } else {
    std::vector<bool> remaining_class_bits(old_classes.size());
    for (auto& class_name : new_classes) {
      bool found = false;
      for (unsigned j = 0; j < old_classes.size(); ++j) {
        if (class_name == old_classes[j]) {
          // Mark each class that is still in the newClasses, so we can skip
          // doing a n^2 search below when looking for removals. We can't
          // break from this loop early since a class can appear more than
          // once.
          remaining_class_bits[j] = true;
          found = true;
        }
      }
      // Class was added.
      if (!found) {
        style_sheet->CollectInvalidationSetsForClass(lists, class_name.str());
      }
    }

    for (unsigned i = 0; i < old_classes.size(); ++i) {
      if (remaining_class_bits[i]) continue;
      // Class was removed.
      style_sheet->CollectInvalidationSetsForClass(lists, old_classes[i].str());
    }
  }
}

void AttributeHolder::CollectPseudoChangedInvalidation(
    CSSFragment* style_sheet, css::InvalidationLists& lists, PseudoState prev,
    PseudoState curr) {
  if ((prev ^ curr) & kPseudoStateFocus) {
    style_sheet->CollectInvalidationSetsForPseudoClass(
        lists, css::LynxCSSSelector::kPseudoFocus);
  }
  if ((prev ^ curr) & kPseudoStateActive) {
    style_sheet->CollectInvalidationSetsForPseudoClass(
        lists, css::LynxCSSSelector::kPseudoActive);
  }
  if ((prev ^ curr) & kPseudoStateHover) {
    style_sheet->CollectInvalidationSetsForPseudoClass(
        lists, css::LynxCSSSelector::kPseudoHover);
  }
}

#ifdef ENABLE_TEST_DUMP
rapidjson::Value AttributeHolder::DumpAttributeToJSON(
    rapidjson::Document& doc) {
  rapidjson::Document::AllocatorType& allocator = doc.GetAllocator();
  rapidjson::Value value;
  value.SetObject();

  value.AddMember("IdSelector", id_selector_.str(), allocator);

  if (classes_.size() > 0) {
    rapidjson::Value class_array;
    class_array.SetArray();
    rapidjson::Value value_str(rapidjson::kStringType);
    for (const auto& clazz : classes_) {
      auto size = static_cast<uint32_t>(clazz.str().size());
      value_str.SetString(clazz.str().c_str(), size, allocator);
      class_array.GetArray().PushBack(value_str, allocator);
    }
    value.AddMember("Classes", class_array, allocator);
  }

  if (inline_styles_.size() > 0) {
    std::map<CSSPropertyID, CSSValue> ordered_inline_styles_map(
        inline_styles_.begin(), inline_styles_.end());
    rapidjson::Value inline_styles_value;
    inline_styles_value.SetObject();
    for (auto it = ordered_inline_styles_map.begin();
         it != ordered_inline_styles_map.end(); ++it) {
      rapidjson::Value key(CSSProperty::GetPropertyName(it->first).str(),
                           allocator);
      rapidjson::Value val(
          tasm::CSSDecoder::CSSValueToString(it->first, it->second), allocator);
      inline_styles_value.AddMember(key, val, allocator);
    }
    value.AddMember("Inline Styles", inline_styles_value, allocator);
  }

  if (cached_styles_.size() > 0) {
    std::map<CSSPropertyID, CSSValue> ordered_cached_styles_map(
        cached_styles_.begin(), cached_styles_.end());
    rapidjson::Value cached_styles_value;
    cached_styles_value.SetObject();
    for (auto it = ordered_cached_styles_map.begin();
         it != ordered_cached_styles_map.end(); ++it) {
      rapidjson::Value key(CSSProperty::GetPropertyName(it->first).str(),
                           allocator);
      rapidjson::Value val(
          tasm::CSSDecoder::CSSValueToString(it->first, it->second), allocator);
      cached_styles_value.AddMember(key, val, allocator);
    }
    value.AddMember("Cached Styles", cached_styles_value, allocator);
  }

  if (attributes_.size() > 0) {
    auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
      return lhs.str() < rhs.str();
    };
    std::map<lepus::String, std::pair<lepus::Value, IsDynamic>, decltype(comp)>
        ordered_attributes_map(attributes_.begin(), attributes_.end(), comp);
    rapidjson::Value attributes_value;
    attributes_value.SetObject();
    for (auto it = ordered_attributes_map.begin();
         it != ordered_attributes_map.end(); ++it) {
      rapidjson::Value key((it->first).str(), allocator);
      lepus::Value lepus_val = it->second.first;
      if (lepus_val.IsString()) {
        rapidjson::Value val(lepus_val.String()->str(), allocator);
        attributes_value.AddMember(key, val, allocator);
      } else if (lepus_val.IsNumber()) {
        attributes_value.AddMember(key, lepus_val.Number(), allocator);
      }
    }
    value.AddMember("Attributes", attributes_value, allocator);
  }

  if (data_set_.size() > 0) {
    auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
      return lhs.str() < rhs.str();
    };
    std::map<lepus::String, lepus::Value, decltype(comp)> ordered_data_set(
        data_set_.begin(), data_set_.end(), comp);
    rapidjson::Value data_set_value;
    data_set_value.SetObject();
    for (auto it = ordered_data_set.begin(); it != ordered_data_set.end();
         ++it) {
      rapidjson::Value key((it->first).str(), allocator);
      lepus::Value lepus_val = it->second;
      if (lepus_val.IsString()) {
        rapidjson::Value val(lepus_val.String()->str(), allocator);
        data_set_value.AddMember(key, val, allocator);
      } else if (lepus_val.IsNumber()) {
        data_set_value.AddMember(key, lepus_val.Number(), allocator);
      }
    }
    value.AddMember("Data Set", data_set_value, allocator);
  }

  if (static_events_.size() > 0) {
    auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
      return lhs.str() < rhs.str();
    };
    std::set<lepus::String, decltype(comp)> keys(comp);
    for (auto it = static_events_.begin(); it != static_events_.end(); ++it) {
      keys.insert(it->first);
    }
    rapidjson::Value static_events_value;
    static_events_value.SetObject();
    for (auto it = keys.begin(); it != keys.end(); ++it) {
      EventHandler* handler = static_events_[*it].get();
      rapidjson::Value event_value;
      event_value.SetObject();
      event_value.AddMember("name", handler->name().str(), allocator);
      event_value.AddMember("type", handler->type().str(), allocator);
      event_value.AddMember("function", handler->function().str(), allocator);
      rapidjson::Value key((*it).str(), allocator);
      rapidjson::Value val(event_value, allocator);
      static_events_value.AddMember(key, val, allocator);
    }
    value.AddMember("Static Events", static_events_value, allocator);
  }

  return value;
}

void AttributeHolder::DumpAttributeToLepusValue(
    base::scoped_refptr<lepus::Dictionary>& props) {
  if (!id_selector_.str().empty()) {
    props->SetValue("id", lepus::Value(id_selector_.impl()));
  }

  if (inline_styles_.size() > 0) {
    std::map<CSSPropertyID, CSSValue> ordered_inline_styles_map(
        inline_styles_.begin(), inline_styles_.end());

    auto inline_styles = lepus::Dictionary::Create();
    for (auto& it : ordered_inline_styles_map) {
      inline_styles->SetValue(
          CSSProperty::GetPropertyName(it.first).str(),
          lepus::Value(lepus::StringImpl::Create(
              tasm::CSSDecoder::CSSValueToString(it.first, it.second))));
    }

    props->SetValue("style", lepus::Value(inline_styles));
  }

  if (classes_.size() > 0) {
    std::ostringstream cls;
    for (const auto& clazz : classes_) {
      cls << clazz.str() << " ";
    }

    props->SetValue("class",
                    lepus::Value(lepus::StringImpl::Create(cls.str())));
  }

  if (attributes_.size() > 0) {
    auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
      return lhs.str() < rhs.str();
    };
    std::map<lepus::String, std::pair<lepus::Value, IsDynamic>, decltype(comp)>
        ordered_attributes_map(attributes_.begin(), attributes_.end(), comp);

    for (auto& it : ordered_attributes_map) {
      props->SetValue(it.first.str(), it.second.first);
    }
  }

  if (data_set_.size() > 0) {
    auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
      return lhs.str() < rhs.str();
    };
    std::map<lepus::String, lepus::Value, decltype(comp)> ordered_data_set(
        data_set_.begin(), data_set_.end(), comp);

    for (auto& it : ordered_data_set) {
      props->SetValue("data-" + it.first.str(), it.second);
    }
  }

  if (static_events_.size() > 0) {
    auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
      return lhs.str() < rhs.str();
    };
    std::set<lepus::String, decltype(comp)> keys(comp);
    for (auto& static_event : static_events_) {
      keys.insert(static_event.first);
    }

    for (const auto& key : keys) {
      EventHandler* handler = static_events_[key].get();

      if (handler->IsBindEvent()) {
        props->SetValue(
            "bind" + handler->name().str(),
            lepus::Value(lepus::StringImpl::Create(handler->function().str())));
      } else if (handler->IsCatchEvent()) {
        props->SetValue(
            "catch" + handler->name().str(),
            lepus::Value(lepus::StringImpl::Create(handler->function().str())));
      } else if (handler->IsCaptureBindEvent()) {
        props->SetValue(
            "capture-bind" + handler->name().str(),
            lepus::Value(lepus::StringImpl::Create(handler->function().str())));
      } else if (handler->IsCaptureCatchEvent()) {
        props->SetValue(
            "capture-catch" + handler->name().str(),
            lepus::Value(lepus::StringImpl::Create(handler->function().str())));
      } else if (handler->IsGlobalBindEvent()) {
        props->SetValue(
            "global-bind" + handler->name().str(),
            lepus::Value(lepus::StringImpl::Create(handler->function().str())));
      }
    }
  }
}

void AttributeHolder::DumpAttributeToMarkup(std::ostringstream& ss) {
  if (!id_selector_.str().empty()) {
    ss << " id=\"" << id_selector_.str() << "\"";
  }

  if (inline_styles_.size() > 0) {
    std::map<CSSPropertyID, CSSValue> ordered_inline_styles_map(
        inline_styles_.begin(), inline_styles_.end());

    ss << " style=\"";
    for (auto& it : ordered_inline_styles_map) {
      ss << CSSProperty::GetPropertyName(it.first).str() << ": "
         << tasm::CSSDecoder::CSSValueToString(it.first, it.second) << "; ";
    }
    ss << "\"";
  }

  if (classes_.size() > 0) {
    ss << " class=\"";
    for (const auto& clazz : classes_) {
      ss << clazz.str() << " ";
    }
    ss << "\"";
  }

  if (attributes_.size() > 0) {
    auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
      return lhs.str() < rhs.str();
    };
    std::map<lepus::String, std::pair<lepus::Value, IsDynamic>, decltype(comp)>
        ordered_attributes_map(attributes_.begin(), attributes_.end(), comp);

    for (auto& it : ordered_attributes_map) {
      ss << " " << it.first.str();
      lepus::Value lepus_val = it.second.first;
      if (lepus_val.IsString()) {
        auto lepus_val_str = lepus_val.String()->str();
        // check if lepus_val_str contains "
        if (lepus_val_str.find("\"") != std::string::npos) {
          // Allow syntax like <svg content={"<path d=\"...\"></path>"}></svg>
          auto s = std::regex_replace(lepus_val_str, std::regex("\""), "\\\"");
          ss << "={\"" << s << "\"}";
        } else {
          ss << "=\"" << lepus_val_str << "\"";
        }
      } else if (lepus_val.IsNumber()) {
        ss << "=\"" << lepus_val.Number() << "\"";
      }
    }
  }

  if (data_set_.size() > 0) {
    auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
      return lhs.str() < rhs.str();
    };
    std::map<lepus::String, lepus::Value, decltype(comp)> ordered_data_set(
        data_set_.begin(), data_set_.end(), comp);

    for (auto& it : ordered_data_set) {
      ss << " data-" << it.first.str() << "=\"" << it.second.String()->str()
         << "\"";
    }
  }

  if (static_events_.size() > 0) {
    auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
      return lhs.str() < rhs.str();
    };
    std::set<lepus::String, decltype(comp)> keys(comp);
    for (auto& static_event : static_events_) {
      keys.insert(static_event.first);
    }

    for (const auto& key : keys) {
      EventHandler* handler = static_events_[key].get();

      if (handler->IsBindEvent()) {
        ss << " bind" << handler->name().str() << "=\""
           << handler->function().str() << "\"";
      } else if (handler->IsCatchEvent()) {
        ss << " catch" << handler->name().str() << "=\""
           << handler->function().str() << "\"";
      } else if (handler->IsCaptureBindEvent()) {
        ss << " capture-bind" << handler->name().str() << "=\""
           << handler->function().str() << "\"";
      } else if (handler->IsCaptureCatchEvent()) {
        ss << " capture-catch" << handler->name().str() << "=\""
           << handler->function().str() << "\"";
      }
    }
  }
}
#endif

}  // namespace tasm
}  // namespace lynx
