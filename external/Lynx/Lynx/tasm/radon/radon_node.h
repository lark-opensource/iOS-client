// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_RADON_RADON_NODE_H_
#define LYNX_TASM_RADON_RADON_NODE_H_

#include <memory>
#include <string>

#include "base/debug/lynx_assert.h"
#include "tasm/attribute_holder.h"
#include "tasm/radon/radon_base.h"
#include "tasm/radon/radon_factory.h"
#include "tasm/radon/radon_types.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"

#ifdef ENABLE_TEST_DUMP
#include "third_party/rapidjson/document.h"
#endif

namespace lynx {
namespace tasm {

class RadonComponent;
class RadonElement;
class PageProxy;

class RadonNode : public RadonBase, public AttributeHolder {
 public:
  RadonNode(PageProxy* const page_proxy_, const lepus::String& tag_name,
            uint32_t node_index);
  RadonNode(const RadonNode& node, PtrLookupMap& map);
  virtual ~RadonNode();

  void UpdateClass(const lepus::String& clazz);
  void UpdateInlineStyle(CSSPropertyID id, const CSSValue& value);
  void UpdateDynamicAttribute(const lepus::String& key,
                              const lepus::Value& value);
  void SetDynamicInlineStyles() {
    dynamic_inline_style_ = true;
    inline_style_dirty_ = true;
  }

  void DispatchSelf(const DispatchOption&) override;

  virtual bool ShouldFlush(const std::unique_ptr<RadonBase>&,
                           const DispatchOption&) RADON_DIFF_ONLY;
  bool ShouldFlushAttr(const RadonNode* old_radon_node) RADON_DIFF_ONLY;
  bool ShouldFlushDataSet(const RadonNode* old_radon_node) RADON_DIFF_ONLY;
  bool ShouldFlushStyle(RadonNode* old_radon_node,
                        const DispatchOption& option) RADON_DIFF_ONLY;

  // Collect descendant invalidation sets (e.g., if this element added or
  // removed the given class, what other types of elements need to change?).
  // Then apply style invalidation to children immediately.
  void CollectInvalidationSetsAndInvalidate(RadonNode* old_radon_node);
  void CollectInvalidationSetsForPseudoAndInvalidate(CSSFragment*, PseudoState,
                                                     PseudoState);
  // Optimized logic: use GetCachedStyleList to get new style only when
  // needed.
  // only can be used if forceCalcNewStyle is set to false by compilerOptions
  bool OptimizedShouldFlushStyle(RadonNode* old_radon_node,
                                 const DispatchOption& option) RADON_DIFF_ONLY;
  // When pseudo state changes, refresh css styles to apply new css.
  bool RefreshStyle();

  void OnPseudoStateChanged(PseudoState, PseudoState) override;

  void UpdateIdSelector(const lepus::String& id_selector);

  void UpdateDataSet(const lepus::String& key, const lepus::Value& value);

  const lepus::String& tag() const override { return RadonBase::tag_name_; }

  virtual CSSFragment* ParentStyleSheet() const override;

  CSSFragment* GetPageStyleSheet() override;

  bool GetCSSScopeEnabled() override;
  bool GetCascadePseudoEnabled() override;

  AttributeHolder* HolderParent() const override;

  AttributeHolder* NextSibling() const override;

  AttributeHolder* PreviousSibling() const override;

  virtual size_t ChildCount() const override;

  virtual void RemoveElementFromParent() override;
  virtual void ResetElementRecursively() override;

  // node add/remove/move event
  virtual void OnElementRemoved(int idx) {}
  virtual void OnElementMoved(int fromIdx, int toIdx) {}

  PageProxy* const page_proxy_;

  virtual bool NeedsElement() const override { return true; }

  void SetInvalidated(bool invalidated) { invalidated_ = invalidated; }
  bool invalidated() { return invalidated_; }

  bool InComponent() const;
  int ParentComponentId() const;
  void OnRenderFailed();
  bool IsRadonNode() const override { return true; }
  virtual RadonElement* element() const override { return element_.get(); }
  virtual int ImplId() const override;

  bool GetDevtoolFlag() override;
#if ENABLE_INSPECTOR
  void NotifyElementNodeAdded() override;
  void NotifyElementNodeRemoved();
  void NotifyElementNodeSetted();

  // Only used by devtool, remove it if needed.
  RadonPlug* GetRadonPlug() override;
  void CheckAndProcessSlotForInspector(RadonElement* element);
  void CheckAndProcessComponentRemoveViewForInspector(RadonElement* element);
#endif  // ENABLE_INSPECTOR

  RadonNode* NodeParent();
  RadonNode* FirstNodeChild();
  RadonNode* LastNodeChild();

  void SwapElement(const std::unique_ptr<RadonBase>&,
                   const DispatchOption&) override RADON_DIFF_ONLY;
  void ReApplyStyle(const DispatchOption& option) override RADON_DIFF_ONLY;

#ifdef ENABLE_TEST_DUMP
  void DumpAttributeToLepusValue(
      base::scoped_refptr<lepus::Dictionary>&) override;
  void DumpAttributeToMarkup(std::ostringstream&) override;
  virtual rapidjson::Value DumpToJSON(rapidjson::Document& doc) override;
#endif
  void InsertElementIntoParent(RadonElement* parent);
  RadonElement* GetParentWithFixed(RadonElement* parent_element);

#if LYNX_ENABLE_TRACING && !LYNX_ENABLE_TRACING_BACKEND_NATIVE
  void UpdateTraceDebugInfo(TraceEvent* event) override {
    RadonBase::UpdateTraceDebugInfo(event);
    if (!id_selector_.empty()) {
      auto* idInfo = event->add_debug_annotations();
      idInfo->set_name("idSelector");
      idInfo->set_string_value(id_selector_.str());
    }
    if (!classes_.empty()) {
      std::string class_str = "";
      for (auto& aClass : classes_) {
        class_str = class_str + " " + aClass.str();
      }
      if (!class_str.empty()) {
        auto* classInfo = event->add_debug_annotations();
        classInfo->set_name("class");
        classInfo->set_string_value(class_str);
      }
    }
  }
#endif

 protected:
  bool CreateElementIfNeeded();
  virtual void DispatchFirstTime();
  virtual bool DiffIncrementally(const DispatchOption&) RADON_ONLY;
  virtual void OnDataSetChanged(){};
  virtual void OnSelectorChanged(){};

  inline bool IsDataSetOrSelectorDirty() {
    return id_dirty_ || data_set_dirty_ || class_dirty_;
  };

  void AttachSSRPageElement(RadonPage* ssr_page);

 private:
  RadonNode* Sibling(int offset) const;
  bool DiffStyleIncrementally(const DispatchOption&) RADON_ONLY;
  bool DiffAttributeIncrementally() RADON_ONLY;
  bool DiffStyleImpl(StyleMap& old_map, StyleMap& new_map, bool check_remove);
  bool NeedsToUpdateClassDueToClassTransmit(const DispatchOption&);
  void CreateContentNode();
  void AddSingleClass(const lepus::String& clazz);
  void MoveChangedInlineStylesToInlineStyles();
  bool HydrateNode(const DispatchOption& option);

  std::unique_ptr<RadonElement> element_;
  lepus::String radon_classes_;
  lepus::Value pseudo_content_;
  StyleMap changed_inline_styles_;
  AttrMap changed_attributes_;
  StyleMap last_styles_;
  bool dynamic_inline_style_{false};
  bool has_external_class_{false};
  bool inline_style_dirty_{false};
  bool attr_dirty_{false};
  bool id_dirty_{false};
  bool class_dirty_{false};
  bool data_set_dirty_{false};
  // Layout or render process is failed due to some environment problems.
  // The node should be re-validate when next updateData action.
  bool invalidated_{false};
  bool need_transmit_class_dirty_{false};
  bool css_variables_changed_{false};
  bool force_calc_new_style_{true};
  // Used for CSS invalidation
  bool style_invalidated_ = false;
  ClassTransmitOption class_transmit_option_;
  constexpr static const char* const kTransmitClassDirty =
      "transmit-class-change";
  friend class RadonElement;
  friend class RadonForNode;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_NODE_H_
