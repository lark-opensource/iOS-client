// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_RADON_RADON_SLOT_H_
#define LYNX_TASM_RADON_RADON_SLOT_H_

#include <memory>
#include <unordered_map>

#include "tasm/radon/radon_base.h"

namespace lynx {
namespace tasm {

class RadonComponent;

class RadonSlot : public RadonBase {
 public:
  RadonSlot(const lepus::String& slot_name);
  RadonSlot(const RadonSlot& node, PtrLookupMap& map);

  void AdoptPlug(std::unique_ptr<RadonBase> child);
  void ReleasePlug();

  virtual void AddChild(std::unique_ptr<RadonBase> child) override;
  virtual void AddSubTree(std::unique_ptr<RadonBase> child) override;

  virtual void SetComponent(RadonComponent* c) override;

  // TODO: OnAttachToComponent need defined in RadonNode?
  void OnAttachToComponent();
  const lepus::String& name() { return name_; }

  virtual void ModifySubTreeComponent(RadonComponent* const target) override;

  virtual bool CanBeReusedBy(const RadonBase* const radon_base) const override;

  // WillRemoveNode is used to handle some special logic before
  // RemoveElementFromParent or radon's structure dtor
  // Here for a slot with plug_can_be_moved_ flag,
  // should move its plug to its component, but not delete the plug directly.
  virtual void WillRemoveNode() override;

  virtual void RadonDiffChildren(
      const std::unique_ptr<RadonBase>& old_radon_child,
      const DispatchOption& option) override RADON_DIFF_ONLY;

  bool IsPlugCanBeMoved() const { return plug_can_be_moved_; }

  void SetPlugCanBeMoved(bool plug_can_be_moved) {
    plug_can_be_moved_ = plug_can_be_moved;
  }

 private:
  lepus::String name_;
  // used to notice the slot's plug should be moved to component
  // should only be setted to true when the slot's component is updated
  // directly.
  bool plug_can_be_moved_{false};
  // used to save original plug to the plug's component
  void MovePlugToComponent();
};

class RadonPlug : public RadonBase {
 public:
  RadonPlug(const lepus::String& plug_name, RadonComponent* component);
  RadonPlug(const RadonPlug& plug, PtrLookupMap& map);
  const lepus::String& plug_name() { return plug_name_; }

  virtual void WillRemoveNode() override;

  /* Utilized only in radon compatible
   * CreateVirtualComponent doesn't provide related outer component.
   * So we need to attach outer component after the component is created.
   * Traversal the children of the plug, set radon_component_ if its
   * radon_component_ is nullptr
   */
  void SetAttachedComponent(RadonComponent*);

 private:
  lepus::String plug_name_;
};

using NameToPlugMap =
    std::unordered_map<lepus::String, std::unique_ptr<RadonBase>>;
using NameToSlotMap = lynx::lynx_ordered_map<lepus::String, RadonSlot*>;

// radon compatible slot&plug help function
class RadonSlotsHelper {
 public:
  RadonSlotsHelper(RadonComponent* radon_component);
  void FillUnattachedPlugs();
  // In multi-layer slot, or if the component has two slots with the same name,
  // the plug's element structure may be destructed.
  // Should disconnect plug element from its parent and then re-connect later.
  // Demo: https://lynx.web.bytedance.net/project/61a48cb97b48a7005c7e3408
  void DisconnectPlugElementFromParent(RadonBase* plug);
  void MovePlugsFromSlots(NameToPlugMap& plugs, NameToSlotMap& slots);
  void DiffWithPlugs(NameToPlugMap& old_plugs, const DispatchOption& option);
  void ReFillSlotsAfterChildrenDiff(NameToSlotMap& old_slots,
                                    const DispatchOption& option);
  void RemoveAllSlots();

 private:
  bool CheckPlugElementValid(RadonSlot* slot);
  RadonComponent* radon_component_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_SLOT_H_
