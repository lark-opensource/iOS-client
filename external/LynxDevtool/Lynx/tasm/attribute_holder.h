// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_ATTRIBUTE_HOLDER_H_
#define LYNX_TASM_ATTRIBUTE_HOLDER_H_

#include <memory>
#include <sstream>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "css/css_fragment.h"
#include "css/css_property.h"
#include "css/unit_handler.h"
#include "lepus/value-inl.h"
#include "tasm/base/base_def.h"
#include "tasm/observer/ui_impl_observer.h"
#include "tasm/react/event.h"

#ifdef ENABLE_TEST_DUMP
#include "css/css_decoder.h"
#include "third_party/rapidjson/document.h"
#endif

namespace lynx {
namespace tasm {
class Element;

class AttributeHolder {
 public:
  AttributeHolder(Element* element = nullptr)
      : has_dynamic_class_(false),
        has_dynamic_inline_style_(false),
        has_dynamic_attr_(false),
        has_css_variables_{false},
        pseudo_element_owner_(nullptr),
        element_(element) {}

  AttributeHolder(const AttributeHolder& holder)
      : has_dynamic_class_{holder.has_dynamic_class_},
        classes_{holder.classes_},
        inline_styles_{holder.inline_styles_},
        attributes_{holder.attributes_},
        data_set_{holder.data_set_},
        has_dynamic_inline_style_{holder.has_dynamic_inline_style_},
        has_dynamic_attr_{holder.has_dynamic_attr_},
        id_selector_{holder.id_selector_},
        has_css_variables_{holder.has_css_variables_},
        pseudo_state_{holder.pseudo_state_},
        pseudo_element_owner_{holder.pseudo_element_owner_},
        element_(holder.element_) {
    for (auto& static_event : holder.static_events_) {
      SetStaticEvent(static_event.second->type(), static_event.second->name(),
                     static_event.second->function());
    }
  }

  virtual ~AttributeHolder() = default;

  void AddClass(const lepus::String& clazz) {
    has_dynamic_class_ = true;
    cached_styles_.clear();
    classes_.push_back(clazz);
  }

  // Compatible code, using AttributeHolder::AddClass instead
  void SetClass(const lepus::String& clazz) { AddClass(clazz); }

  void RemoveAllClass() { classes_.clear(); }

  inline void SetInlineStyle(CSSPropertyID id, const lepus::String& value,
                             const CSSParserConfigs& configs) {
    has_dynamic_inline_style_ = true;
    cached_styles_.clear();
    UnitHandler::Process(id, lepus::Value(value.impl()), inline_styles_,
                         configs);
  }

  inline void SetInlineStyle(CSSPropertyID id, const tasm::CSSValue& value) {
    has_dynamic_inline_style_ = true;
    cached_styles_.clear();
    inline_styles_[id] = value;
  }

  inline void SetDynamicAttribute(const lepus::String& key,
                                  const lepus::Value& value) {
    has_dynamic_attr_ = true;
    attributes_[key] = {value, true};
  }

  inline void SetHasCssVariables(bool has_css_variables) {
    has_css_variables_ = has_css_variables;
  }

  inline void SetStaticClass(const lepus::String& clazz) {
    cached_styles_.clear();
    classes_.push_back(clazz);
  }

  inline void SetStaticInlineStyle(CSSPropertyID id, const lepus::String& value,
                                   const CSSParserConfigs& configs) {
    cached_styles_.clear();
    UnitHandler::Process(id, lepus::Value(value.impl()), inline_styles_,
                         configs);
  }

  inline void SetStaticInlineStyle(CSSPropertyID id,
                                   const tasm::CSSValue& value) {
    cached_styles_.clear();
    inline_styles_[id] = value;
  }
  inline void SetStaticAttribute(const lepus::String& key,
                                 const lepus::Value& value) {
    attributes_[key] = {value, false};
  }

  void RemoveAttribute(const lepus::String& key) { attributes_.erase(key); }

  inline void SetDataSet(const lepus::String& key, const lepus::Value& value) {
    data_set_[key] = value;
  }

  void SetDataSet(const lepus::Value& data_set);

  // Update CSSVariable From Render.
  inline void UpdateCSSVariable(const lepus::String& key,
                                const lepus::String& value) {
    cached_styles_.clear();
    auto it = css_variables_.find(key);
    if (it == css_variables_.end() || !it->second.IsEqual(value)) {
      css_variables_[key] = value;
    }
  }

  // Update CSSVariable From JS SetProperty.
  void UpdateCSSVariableFromSetProperty(const lepus::String& key,
                                        const lepus::String& value);

  // For Element Api
  void MergeWithCSSVariables(lepus::Value& css_variable_updated);

  inline void SetStaticEvent(const lepus::String& type,
                             const lepus::String& name,
                             const lepus::String& value) {
    if (type == kGlobalBind) {
      global_bind_events_[name] =
          std::make_unique<EventHandler>(type, name, value);
    } else {
      static_events_[name] = std::make_unique<EventHandler>(type, name, value);
    }
  }

  // constructor for ssr server events
  inline void SetStaticEvent(
      const lepus::String& type, const lepus::String& name,
      const std::vector<std::pair<lepus::String, lepus::Value>>& vec) {
    std::vector<PiperEventContent> piper_event_vec;
    for (auto& iter : vec) {
      auto an_event = PiperEventContent(iter.first, iter.second);
      piper_event_vec.push_back(an_event);
    }
    if (type == kGlobalBind) {
      global_bind_events_[name] =
          std::make_unique<EventHandler>(type, name, piper_event_vec);
    } else {
      static_events_[name] =
          std::make_unique<EventHandler>(type, name, piper_event_vec);
    }
  }

  inline void SetLepusEvent(const lepus::String& type,
                            const lepus::String& name,
                            const lepus::Value& script,
                            const lepus::Value& func) {
    if (type == kGlobalBind) {
      global_bind_events_[name] =
          std::make_unique<EventHandler>(type, name, script, func);
    } else {
      static_events_[name] =
          std::make_unique<EventHandler>(type, name, script, func);
    }
  }

  void RemoveEvent(const lepus::String& name, const lepus::String& type);
  void RemoveAllEvents();

  inline void SetIdSelector(const lepus::String& idSelector) {
    id_selector_ = idSelector;
    attributes_[lepus::String(kIdSelectorAttrName)] = {
        lepus::Value(idSelector.impl()), true};
  }

  inline const lepus::String& idSelector() const { return id_selector_; }

  inline const StyleMap& inline_styles() const { return inline_styles_; }

  StyleMap& MutableInlineStyles() { return inline_styles_; }

  inline const AttrMap& attributes() const { return attributes_; }

  inline const DataMap& dataset() const { return data_set_; }

  inline void set_css_variables_map(const CSSVariableMap& css_variables) {
    css_variables_ = css_variables;
  }

  inline const CSSVariableMap& css_variables_map() const {
    return css_variables_;
  }

  inline void AddCSSVariableRelated(const lepus::String& key,
                                    const lepus::String& value) {
    css_variable_related_[key] = value;
  }

  inline const CSSVariableMap& css_variable_related() {
    return css_variable_related_;
  }

  // GetCSSVariableValue.
  // variable_from_js first. css_variable_ from comes second.
  inline lepus::String GetCSSVariableValue(const lepus::String& key) const {
    auto it = css_variables_from_js_.find(key);
    if (it != css_variables_from_js_.end()) {
      return it->second;
    }
    it = css_variables_.find(key);
    if (it != css_variables_.end()) {
      return it->second;
    }
    return lepus::String();
  }

  inline const ClassList& classes() const { return classes_; }

  inline bool HasClass(const std::string& cls) const {
    return std::find_if(classes_.begin(), classes_.end(), [&cls](auto& s) {
             return s.str() == cls;
           }) != std::end(classes_);
  }

  inline const EventMap& static_events() const { return static_events_; }
  inline const EventMap& lepus_events() const { return lepus_events_; }
  inline const EventMap& global_bind_events() const {
    return global_bind_events_;
  }

  inline bool has_dynamic_inline_style() const {
    return has_dynamic_inline_style_;
  }

  inline bool has_dynamic_class() const { return has_dynamic_class_; }

  inline bool has_dynamic_attr() const { return has_dynamic_attr_; }

  inline bool has_css_variables() const { return has_css_variables_; }

  const StyleMap& cached_styles() const { return cached_styles_; }

  void set_cached_styles(const StyleMap& styles) { cached_styles_ = styles; }

  void ClearCachedStyles() { cached_styles_.clear(); }

  bool ContainsSelector(const std::string& selector) const;

  void Reset();

  void set_tag(const lepus::String& name) { tag_ = name; }

  inline virtual const lepus::String& tag() const { return tag_; }
  AttributeHolder* SelectorMatchingParent() const;
  virtual AttributeHolder* HolderParent() const;
  virtual AttributeHolder* NextSibling() const;
  virtual AttributeHolder* PreviousSibling() const;
  virtual size_t ChildCount() const;
  inline virtual CSSFragment* ParentStyleSheet() const { return nullptr; }
  AttributeHolder* PseudoElementOwner() const { return pseudo_element_owner_; }
  void SetPseudoElementOwner(AttributeHolder* owner) {
    pseudo_element_owner_ = owner;
  }

  virtual CSSFragment* GetStyleSheet() { return nullptr; }

  virtual CSSFragment* GetPageStyleSheet() { return nullptr; }

  virtual bool GetCSSScopeEnabled() { return false; }
  virtual bool GetCascadePseudoEnabled() { return false; }

  void CloneAttributes(const AttributeHolder& src) {
    this->has_dynamic_class_ = src.has_dynamic_class_;
    this->classes_ = src.classes_;
    this->inline_styles_ = src.inline_styles_;
    this->attributes_ = src.attributes_;
    this->data_set_ = src.data_set_;
    this->has_dynamic_inline_style_ = src.has_dynamic_inline_style_;
    this->has_dynamic_attr_ = src.has_dynamic_attr_;
    this->id_selector_ = src.id_selector_;
    this->css_variables_ = src.css_variables_;
  }

  inline void MarkAllDynamic() {
    has_dynamic_class_ = true;
    has_dynamic_attr_ = true;
    has_dynamic_inline_style_ = true;
  }

  static constexpr const char* const kIdSelectorAttrName = "idSelector";

#ifdef ENABLE_TEST_DUMP
  rapidjson::Value DumpAttributeToJSON(rapidjson::Document& doc);
  virtual void DumpAttributeToLepusValue(
      base::scoped_refptr<lepus::Dictionary>& table);
  virtual void DumpAttributeToMarkup(std::ostringstream& ss);
#endif

  virtual void OnPseudoStateChanged(PseudoState, PseudoState) {}

  void SetPseudoState(PseudoState state) {
    // If pseudo_state_ == state, which means the
    // PseudoState not change, return.
    if (pseudo_state_ == state) return;
    PseudoState old = pseudo_state_;
    pseudo_state_ = state;
    OnPseudoStateChanged(old, pseudo_state_);
  }

  void AddPseudoState(PseudoState state) {
    PseudoState old = pseudo_state_;
    pseudo_state_ |= state;
    OnPseudoStateChanged(old, pseudo_state_);
  }

  void RemovePseudoState(PseudoState state) {
    PseudoState old = pseudo_state_;
    pseudo_state_ ^= state;
    OnPseudoStateChanged(old, pseudo_state_);
  }

  PseudoState GetPseudoState() { return pseudo_state_; }

  bool HasPseudoState(PseudoState type) const { return pseudo_state_ & type; }

  bool HasID() const { return !id_selector_.empty(); };

  bool HasClass() const { return !classes_.empty(); }

  static void CollectIdChangedInvalidation(CSSFragment*,
                                           css::InvalidationLists&,
                                           const std::string&,
                                           const std::string&);

  static void CollectClassChangedInvalidation(CSSFragment*,
                                              css::InvalidationLists&,
                                              const ClassList&,
                                              const ClassList&);

  static void CollectPseudoChangedInvalidation(CSSFragment*,
                                               css::InvalidationLists&,
                                               PseudoState, PseudoState);

 protected:
  bool has_dynamic_class_;
  ClassList classes_;
  StyleMap inline_styles_;
  StyleMap cached_styles_;
  AttrMap attributes_;
  DataMap data_set_;
  EventMap static_events_;
  EventMap lepus_events_;
  EventMap global_bind_events_;
  bool has_dynamic_inline_style_;
  bool has_dynamic_attr_;
  // Should be unique in component
  lepus::String id_selector_;

  // css variable definition on this node. such as:
  // `--bg-color: red`
  CSSVariableMap css_variables_;

  // css variable definition on this node that updated from JS. such as:
  // `background-color: var(--bg-color)`
  // this map will hold value like this:
  // `key: --bg-color value: red`
  CSSVariableMap css_variables_from_js_;

  // css variable related on this node, such as:
  // `background-color: var(--bg-color)`
  // this map will hold value like this:
  // `key: --bg-color value: red`
  CSSVariableMap css_variable_related_;

  bool has_css_variables_;
  // Record if is focused / hovered ...
  PseudoState pseudo_state_{kPseudoStateNone};
  lepus::String tag_;
  AttributeHolder* pseudo_element_owner_;
  // Reference the element for sibling and parent
  Element* element_;

  friend class BaseComponent;

 public:
  bool ContainsIdSelector(const std::string& selector) const;
  bool ContainsClassSelector(const std::string& selector) const;
  bool ContainsTagSelector(const std::string& selector) const;
  bool ContainsAttributeSelector(const std::string& selector) const;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_ATTRIBUTE_HOLDER_H_
