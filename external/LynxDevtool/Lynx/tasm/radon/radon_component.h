// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RADON_RADON_COMPONENT_H_
#define LYNX_TASM_RADON_RADON_COMPONENT_H_

#include <memory>
#include <string>

#include "config/config.h"
#include "css/css_fragment.h"
#include "css/css_fragment_decorator.h"
#include "lepus/context.h"
#include "lepus/vm_context.h"
#include "tasm/generator/ttml_constant.h"
#include "tasm/radon/base_component.h"
#include "tasm/radon/radon_node.h"
#include "tasm/radon/radon_slot.h"

namespace lynx {
namespace tasm {

class RadonPage;

struct RenderOption {
  bool recursively = false;
};

class RadonComponent : public RadonNode, public BaseComponent {
 public:
  RadonComponent(PageProxy* client, int tid, CSSFragment* style_sheet,
                 std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
                 ComponentMould* mould, lepus::Context* context,
                 uint32_t node_index,
                 const lepus::String& tag_name = "component");
  RadonComponent(const RadonComponent& node, PtrLookupMap& map);

  virtual ~RadonComponent();

  virtual int ImplId() const override;

  /* Recursively call Component removed lifecycle in post order.
   * But save the original radon tree structure.
   */
  virtual void OnComponentRemovedInPostOrder() final;

  virtual CSSFragment* GetStyleSheet() override;
  void OnStyleSheetReady(CSSFragment* fragment);

  inline const lepus::Value& GetRadonComponentData() const { return data_; }
  virtual void AddChild(std::unique_ptr<RadonBase> child) override;
  virtual void AddSubTree(std::unique_ptr<RadonBase> child) override;

  const NameToSlotMap& slots() { return slots_; }

  AttributeHolder* GetAttributeHolder() override {
    return static_cast<AttributeHolder*>(this);
  }

  virtual void SetComponent(RadonComponent* component) override;

  void AddRadonPlug(const lepus::String& name, std::unique_ptr<RadonBase> plug);
  void RemovePlugByName(const lepus::String& name);

  void AddRadonSlot(const lepus::String& name, RadonSlot* slot);

  // for remove component element
  virtual bool NeedsElement() const override;
  bool NeedsExtraData() const override;
  RadonElement* TopLevelViewElement() const;

  void Dispatch(const DispatchOption&) override;
  void DispatchSelf(const DispatchOption&) override;

  void DispatchForDiff(const DispatchOption&) override RADON_DIFF_ONLY;

  virtual void DispatchChildren(const DispatchOption&) override;
  virtual void DispatchChildrenForDiff(const DispatchOption&) override
      RADON_DIFF_ONLY;

  virtual void ResetElementRecursively() override;

  void OnElementRemoved(int idx) override;
  void OnElementMoved(int from_idx, int to_idx) override;

  virtual void UpdateComponentInLepus() RADON_ONLY;

  void UpdateRadonComponent(RenderType render_type,
                            lepus::Value incoming_property,
                            lepus::Value incoming_data,
                            const DispatchOption& option);

  void SetCSSVariables(const std::string& id_selector,
                       const lepus::Value& properties);

  bool UpdateRadonComponentWithoutDispatch(RenderType render_type,
                                           lepus::Value incoming_property,
                                           lepus::Value incoming_data);

  void RenderRadonComponentIfNeeded(RenderOption&) RADON_DIFF_ONLY;
  virtual void CreateComponentInLepus() RADON_ONLY;
  void SetGlobalPropsFromTasm();

  int ComponentId() override;
  BaseComponent* GetParentComponent() override;
  BaseComponent* GetComponentOfThisComponent() override { return component(); }

  const lepus::Value& component_info_map() const override;

  const lepus::Value& component_path_map() const override;

  void OnReactComponentRenderBase(lepus::Value& new_data,
                                  bool should_component_update) override;

  void RadonDiffChildren(const std::unique_ptr<RadonBase>&,
                         const DispatchOption&) override RADON_DIFF_ONLY;
  virtual void OnComponentUpdate(const DispatchOption& option);
  virtual void OnReactComponentDidUpdate(const DispatchOption& option);
  void ResetDispatchedStatus();

#if LYNX_ENABLE_TRACING && !LYNX_ENABLE_TRACING_BACKEND_NATIVE
  void UpdateTraceDebugInfo(TraceEvent* event) override {
    RadonNode::UpdateTraceDebugInfo(event);
    auto* nameInfo = event->add_debug_annotations();
    nameInfo->set_name("componentName");
    nameInfo->set_string_value(name_.str());
  }
#endif

  void OnDataSetChanged() override;
  void OnSelectorChanged() override;

  // should only be used in render_functions:ProcessComponentData now.
  bool PreRenderForRadonComponent() { return PreRender(render_type_); }

  // render_type_ should be updated every time we re-render the radon tree.
  // render_type_ should only be used in PreRenderForComponent or PrePageRender.
  // This method utilizes the render_type_ last time we set when the tree was
  // updated to prerender the component.
  RenderType render_type_;
  void SetRenderType(RenderType type) { render_type_ = type; }

  // a component may be in a dynamic component, which has its own entry
  // same as virtual component
  virtual const std::string& GetEntryName() const override;

  virtual bool CanBeReusedBy(const RadonBase* const radon_base) const override;

  virtual void Refresh(const DispatchOption&);
  virtual void RefreshWithNewStyle(const DispatchOption&);

  void GenerateAndSetComponentId();

  // methods to check properties undefined.
  // it's result will differ according to pageConfig `enableComponentNullProps`
  bool IsPropertiesUndefined(const lepus::Value& value) const override;

  virtual void ModifySubTreeComponent(RadonComponent* const target) override;
  virtual bool ShouldBlockEmptyProperty() override;

  // WillRemoveNode is used to handle some special logic before
  // RemoveElementFromParent or radon's structure dtor
  virtual void WillRemoveNode() override;

  bool need_reset_data_{false};

  // component should be removed from parent in list
  bool list_need_remove_{false};

  // component should be removed from parent after being reused in list
  bool list_need_remove_after_reused_{false};

  // Used to set some special attribute for a component,
  // like lynx-key and removeComponentElement.
  // If the key is a special attribute key, it should not
  // be a property.
  bool SetSpecialComponentAttribute(const lepus::String& key,
                                    const lepus::Value& value);

  void ClearStyleSheetAndVariables();
  void SetIntrinsicStyleSheet(CSSFragment* style_sheet);

 protected:
  bool update_function_called_{false};
  void PreHandlerCSSVariable();
  // used to set one component's `RemoveComponentElement` config.
  // If the component's `RemoveComponentElement` config has been set,
  // it will override the page_config's global `RemoveComponentElement`
  // This config shouldn't be updated. Otherwise the updating may cause a
  // re-rendering.
  constexpr static const char* const kRemoveComponentElement =
      "removeComponentElement";
  BooleanProp remove_component_element_{BooleanProp::NotSet};
  bool SetRemoveComponentElement(const lepus::String& key,
                                 const lepus::Value& value);

  // update __golbalProps and SystemInfo to data_
  void UpdateLepusTopLevelVariableToData();

  void AdoptPlugToSlot(RadonSlot* slot, std::unique_ptr<RadonBase> plug);

 private:
  virtual void RenderRadonComponent(RenderOption&) RADON_DIFF_ONLY;
  bool IsInList() override;
  NameToSlotMap slots_;
  void DisableCallOnElementRemovedInDestructor() RADON_DIFF_ONLY;
  uint32_t component_id_{0};
  bool compile_render_{false};
  bool NeedSavePreState(const RenderType& render_type) {
    return should_component_update_function_.IsCallable() &&
           !(IsReact() && render_type == RenderType::UpdateFromJSBySelf);
  }
  NameToPlugMap plugs_;
  std::unique_ptr<RadonSlotsHelper> radon_slots_helper_;
  friend class RadonSlot;
  friend class RadonSlotsHelper;

  /*
   * RadonReusableDiffChildren is only used in radon diff list new arch.
   * This function will diff a complete and determined radon component (reuser)
   * without element with an old radon component with element (reused element).
   * If the reuser is a new created component, should call related component's
   * lifecycle and continually diff its children.
   * If the reuser is a component dispatched and updated before, should just
   * continually diff its children, because its lifecycle has been called when
   * it updated using component info's data and properties.
   */
  void RadonReusableDiffChildren(RadonComponent* old_radon_component,
                                 const DispatchOption& option) RADON_DIFF_ONLY;
};

class RadonListComponent : public RadonComponent {
 public:
  RadonListComponent(PageProxy* page_proxy, int tid, CSSFragment* style_sheet,
                     std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
                     ComponentMould* mould, lepus::Context* context,
                     uint32_t node_index, int distance_from_root,
                     const lepus::String& tag_name = "component");

  void SetComponent(RadonComponent* component) override;
  virtual void ModifySubTreeComponent(RadonComponent* const target) override;
  int distance_from_root_{0};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_COMPONENT_H_
