// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RADON_RADON_BASE_H_
#define LYNX_TASM_RADON_RADON_BASE_H_

#include <functional>
#include <memory>
#include <unordered_set>
#include <vector>

#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/lepus_string.h"
#include "tasm/base/base_def.h"
#include "tasm/radon/radon_dispatch_option.h"
#include "tasm/radon/radon_factory.h"
#include "tasm/radon/radon_types.h"
#include "tasm/react/radon_element.h"
#include "tasm/selector/selector_item.h"

#ifdef ENABLE_TEST_DUMP
#include "third_party/rapidjson/document.h"
#endif

#define RADON_ONLY
#define RADON_DIFF_ONLY

namespace lynx {
namespace tasm {

class RadonPage;
class RadonElement;
class RadonComponent;
class RadonPlug;

using RadonNodeIndexType = uint32_t;
using RadonBaseVector = std::vector<std::unique_ptr<RadonBase>>;
constexpr RadonNodeIndexType kRadonInvalidNodeIndex = 0;

class RadonBase : public SelectorItem {
 public:
  RadonBase(RadonNodeType node_type, const lepus::String& tag_name,
            RadonNodeIndexType node_index);
  RadonBase(const RadonBase& node, PtrLookupMap& map);
  virtual ~RadonBase() = default;
  virtual void SetComponent(RadonComponent* component);
  void NeedModifySubTreeComponent(RadonComponent* const target);
  virtual void ModifySubTreeComponent(RadonComponent* const target);
  RadonComponent* component() const { return radon_component_; }
  RadonComponent* radon_component_ = nullptr;

  void PushDynamicNode(RadonBase* node) RADON_ONLY;
  RadonBase* GetDynamicNode(RadonNodeIndexType index,
                            RadonNodeIndexType node_index) RADON_ONLY;

  virtual void Dispatch(const DispatchOption&);
  virtual void DispatchSelf(const DispatchOption&);
  void DispatchSubTree(const DispatchOption&);
  void DispatchDynamicChildren(const DispatchOption&) RADON_ONLY;
  virtual void DispatchChildren(const DispatchOption&);

  virtual void DispatchForDiff(const DispatchOption&) RADON_DIFF_ONLY;
  virtual void DispatchChildrenForDiff(const DispatchOption&) RADON_DIFF_ONLY;
  virtual void RadonDiffChildren(
      const std::unique_ptr<RadonBase>& old_radon_child,
      const DispatchOption& option) RADON_DIFF_ONLY;

  /* Radon Element Struct */
  virtual bool NeedsElement() const { return false; }
  virtual RadonElement* element() const { return nullptr; }
  virtual RadonElement* LastNoFixedElement() const;
  RadonElement* ParentElement();
  RadonElement* PreviousSiblingElement();
  // WillRemoveNode is used to handle some special logic before
  // RemoveElementFromParent or radon's structure dtor
  virtual void WillRemoveNode();
  virtual void RemoveElementFromParent();
  virtual int ImplId() const { return kInvalidImplId; }

  /*devtool notify element added*/
  virtual bool GetDevtoolFlag();

  virtual void NotifyElementNodeAdded() {}
  virtual RadonPlug* GetRadonPlug() { return nullptr; }

  RadonPage* root_node();

  // used to get page's root element
  // taking page element feature in consideration
  RadonElement* GetRootElement();

  RadonBase* Parent() { return radon_parent_; }
  const RadonBase* Parent() const { return radon_parent_; }

  int32_t IndexInSiblings() const;

  /* getter and setters */
  RadonNodeType NodeType() const { return node_type_; }
  RadonNodeIndexType NodeIndex() const { return node_index_; }
  const lepus::String& TagName() const { return tag_name_; }

  virtual bool IsRadonNode() const { return false; }

  bool dispatched() { return dispatched_; }

  // Used to clear sub-node's element tree structure,
  // but remain Radon Tree structure
  // Should call RemoveElementFromParent before
  // calling ResetElementRecursively.
  virtual void ResetElementRecursively();

  // return true if lynx-key is setted successfully
  bool SetLynxKey(const lepus::String& key,
                  const lepus::Value& value) RADON_DIFF_ONLY;

  /* Radon Tree Struct */
  virtual void AddChild(std::unique_ptr<RadonBase> child);
  void AddChildWithoutSetComponent(std::unique_ptr<RadonBase> child);
  virtual void AddSubTree(std::unique_ptr<RadonBase> child);
  /* Be careful:
   * If you want to destruct one radon node, please use
   * ClearChildrenRecursivelyInPostOrder before RemoveChild.
   * See ClearChildrenRecursivelyInPostOrder comment for more info.
   */
  std::unique_ptr<RadonBase> RemoveChild(RadonBase* child);
  RadonBase* LastChild();
  void Visit(bool including_self,
             const base::MoveOnlyClosure<bool, RadonBase*>& visitor);
  RadonBase* radon_parent_ = nullptr;
  RadonBase* radon_previous_ = nullptr;
  RadonBase* radon_next_ = nullptr;

  /* Recursively clear children.
   * We need to call this function before one radon node is about to destruct.
   * In this case the radon node will destruct in the order of its children to
   * itself.
   */
  /* Reason: Sometimes the radon node may call its parent's function
   * when destruct, so we need to retain this node while its children is
   * destructing.
   */
  /* Example: When one radon component is destructing, it may call
   * component->GetParentComponent() in FireComponentLifecycleEvent. If its
   * parent component has been destructed yet, the program will crash. So we
   * need to destruct the child component before destructing the parent
   * component.
   */
  void ClearChildrenRecursivelyInPostOrder() RADON_DIFF_ONLY;

  /* Recursively call Component removed lifecycle in post order.
   * But save the original radon tree structure.
   */
  virtual void OnComponentRemovedInPostOrder();

  /* a dynamic node of a RadonBase must be a descendant of it
   * but it might not be a direct child of it
   * Reason about the safety of hold raw ptrs of its descendant
   * if a ptr becomes a wild ptr, it must be released at some point
   * if a ptr could be released, it must be a descendant of a if/for node
   * if a ptr is a descendant of a if/for node:
   *    if the ptr is a direct child of the if/for node, it will not execute
   * lepus function 'PushDynamicNode' if the ptr is not a direct child of the
   * if/for node, its subroot must be a direct descendant of the if/for node
   * Therefore, the path from 'this' to one of nodes in dynamic_nodes_ will not
   * contain any if/for node. Thus, it is safe to hold the raw ptrs for
   * dynamic_nodes_;
   */
  std::vector<RadonBase*> dynamic_nodes_ = {};
  RadonBaseVector radon_children_ = {};

#ifdef ENABLE_TEST_DUMP
  virtual rapidjson::Value DumpToJSON(rapidjson::Document& doc);
#endif

  // component item_key_ in list new arch;
  lepus::String list_item_key_;
  void SetListItemKey(const lepus::String& list_item_key) {
    list_item_key_ = list_item_key;
  }
  const lepus::String& GetListItemKey() const { return list_item_key_; }

  bool IsRadonComponent() const {
    return kRadonComponent == node_type_ ||
           kRadonDynamicComponent == node_type_;
  }

  bool IsRadonDynamicComponent() const {
    return kRadonDynamicComponent == node_type_;
  }

  bool IsRadonPage() const { return kRadonPage == node_type_; }

  virtual bool CanBeReusedBy(const RadonBase* const radon_base) const;

#if LYNX_ENABLE_TRACING && !LYNX_ENABLE_TRACING_BACKEND_NATIVE
  virtual void UpdateTraceDebugInfo(TraceEvent* event) {
    auto* tagInfo = event->add_debug_annotations();
    tagInfo->set_name("tagName");
    tagInfo->set_string_value(tag_name_.str());
  }
#endif

 protected:
  bool will_remove_node_has_been_called_{false};
  bool dispatched_ = false;
  bool create_plug_element_ = false;

  /* node_index_ is generated by radon_parser.cc. Each <tag> has a different
   * node_index_. Two RadonNode in by RadonForNode will has same node_index_. In
   * other case, every RadonNode has different node_index_.
   */
  RadonNodeType node_type_ = kRadonUnknown;
  const RadonNodeIndexType node_index_ = kRadonInvalidNodeIndex;
  const lepus::String tag_name_ = "";

  void RadonMyersDiff(RadonBaseVector& old_radon_children,
                      const DispatchOption& option) RADON_DIFF_ONLY;
  void LightDiffForStyle(RadonBaseVector& origin_radon_children,
                         const DispatchOption& option) RADON_DIFF_ONLY;

  virtual void SwapElement(const std::unique_ptr<RadonBase>& old_radon_base,
                           const DispatchOption& option) RADON_DIFF_ONLY{};
  virtual void ReApplyStyle(const DispatchOption& option) RADON_DIFF_ONLY{};

 private:
  constexpr static const char* const kLynxKey = "lynx-key";
  lepus::Value lynx_key_;
  RadonPage* root_node_{nullptr};
  RadonElement* root_element_{nullptr};
#if ENABLE_INSPECTOR
  friend class DispatchOptionObserverForInspector;
#endif  // ENABLE_INSPECTOR
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_BASE_H_
