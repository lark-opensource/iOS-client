// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_RADON_ELEMENT_H_
#define LYNX_TASM_REACT_RADON_ELEMENT_H_

#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "tasm/react/element.h"

namespace lynx {
namespace tasm {

class RadonElement : public Element {
 public:
  RadonElement(const lepus::String& tag, AttributeHolder* node,
               ElementManager* element_manager);

  ~RadonElement();

  bool is_radon_element() const override { return true; }

  virtual ListNode* GetListNode() override;

  virtual Element* GetParentComponentElement() const override;

  bool CanBeLayoutOnly() const override {
    return config_enable_layout_only_ && has_layout_only_props_ &&
           overflow_ == OVERFLOW_XY &&
           (!is_component_ || enable_component_layout_only_);
  }

  AttributeHolder* data_model() const override { return data_model_; }

  bool InComponent() const override;

  void OnRenderFailed() override;

  void SetAttributeHolder(AttributeHolder* data_model);

  virtual void SetNativeProps(const lepus::Value& args) override;

  void onDataModelSetted(AttributeHolder* old_model,
                         AttributeHolder* new_model);

  void InsertNode(RadonElement* child);
  void InsertNode(RadonElement* child, size_t index);
  void RemoveNode(RadonElement* child, unsigned int index, bool destroy = true);
  void MoveNode(RadonElement* child, unsigned int from_index,
                unsigned int to_index);
  void DestroyNode(RadonElement* child);

  void MarkPlatformNodeDestroyedRecursively();

  void UpdateDynamicElementStyle() override;
  void FlushDynamicStyles();

  int ParentComponentId() const override;
  std::string ParentComponentIdString() const override;

  Element* Sibling(int offset) const override;
  void AddChildAt(RadonElement* child, size_t index);
  RadonElement* RemoveChildAt(size_t index);
  int IndexOf(const RadonElement* child) const;

  bool GetPageElementEnabled() override;
  Element* GetChildAt(size_t index) override;
  size_t GetChildCount() override { return children_.size(); }
  std::vector<Element*> GetChild() override { return children_; }
  size_t GetUIIndexForChild(Element* child) override;

  void SetComponentIDPropsIfNeeded();

  bool IsBeforeContent();
  bool IsAfterContent();

  void SetIsPseudoNode() { is_pseudo_ = true; }
  bool IsPseudoNode() { return is_pseudo_; }

  // Flush style and attribute to platform shadow node, platform painting node
  // will be created if has not been created,
  void FlushProps() override;
  void FlushPropsFirstTimeWithParentElement(Element* parent);

  void OnPseudoStatusChanged(PseudoState prev_status,
                             PseudoState current_status) override;

  void SetStyle(const StyleMap& styles) override;

  void OnPatchFinish(const PipelineOptions& option) override;

  virtual void ConsumeTransitionStylesInAdvanceInternal(
      CSSPropertyID css_id, const tasm::CSSValue& value) override;
  virtual void ResetTransitionStylesInAdvanceInternal(
      CSSPropertyID css_id) override;

  void ResolveStyleValue(CSSPropertyID id, const tasm::CSSValue& value,
                         bool force_update) override;
  void CheckBaseline(CSSPropertyID id, CSSValue value) override;

  void CheckAnimateProps(CSSPropertyID id) override;

  virtual CSSFragment* GetRelatedCSSFragment() override;

 private:
  size_t GetUIChildrenCount();
  AttributeHolder* data_model_{nullptr};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_RADON_ELEMENT_H_
