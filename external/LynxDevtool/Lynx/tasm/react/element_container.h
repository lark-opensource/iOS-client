// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_ELEMENT_CONTAINER_H_
#define LYNX_TASM_REACT_ELEMENT_CONTAINER_H_

#include <memory>
#include <utility>
#include <vector>

#include "base/geometry/point.h"
#include "tasm/react/painting_context.h"

namespace lynx {
namespace tasm {

class Element;
class ElementManager;

class ElementContainer {
 public:
  explicit ElementContainer(Element* element);
  ~ElementContainer();

  Element* element() const { return element_; }
  ElementContainer* parent() const { return parent_; }
  const std::vector<ElementContainer*>& children() const { return children_; }
  PaintingContext* painting_context();
  int id() const;

  void AddChild(ElementContainer* child, int index);
  void RemoveFromParent();
  void Destroy();
  void RemoveSelf(bool destroy);
  void InsertSelf();
  void UpdateLayout(float left, float top, bool transition_view = false);
  void UpdateLayoutWithoutChange();
  /**
   * Add element container to correct parent(if layout_only contained)
   * @param child the child to be added
   * @param ref the ref node ,which the child will be inserted before(currently
   * only for fiber)
   */
  void AttachChildToTargetContainer(Element* child, Element* ref = nullptr);
  void TransitionToNativeView();
  void StyleChanged();
  void UpdateZIndexList();
  ElementContainer* EnclosingStackingContextNode();
  bool IsStackingContextNode();

 private:
  void ZIndexChanged();
  // Use RemoveFromParent/Destroy
  void RemoveChild(ElementContainer* child);
  // below helper functions to calculate the correct parent and UI index for
  // fiber element
  static std::pair<ElementContainer*, int> FindParentAndIndexForChildForFiber(
      Element* parent, Element* child, Element* ref);
  static int GetUIIndexForChildForFiber(Element* parent, Element* child);
  static int GetUIChildrenCountForFiber(Element* parent);

  ElementManager* element_manager();
  float last_left_{0};
  float last_top_{0};
  std::pair<ElementContainer*, int> FindParentForChild(Element* child);
  void MoveAllZChildren(ElementContainer* parent);
  void MoveContainers(ElementContainer* old_parent,
                      ElementContainer* new_parent);
  int ZIndex();
  void SetNeedUpdate(bool update) { need_update_ = update; }
  void MarkDirty();
  bool IsSticky();
  Element* element_ = nullptr;
  ElementContainer* parent_ = nullptr;

  std::vector<ElementContainer*> children_;
  // the children size does not contain layout only nodes
  int none_layout_only_children_size_{0};

  bool was_stacking_context_ = false;
  int old_index_ = 0;
  bool need_update_ = true;
  bool dirty_ = false;
  // children with zIndex<0, negative zIndex child will be re-inserted to the
  // beginning after onPatchFinish
  std::vector<ElementContainer*> negative_z_children_;
  // indicate the ElementContainer has finished first layout
  bool is_layouted_{false};
  // true if the Element's props has changed during this patch
  bool props_changed_{true};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_ELEMENT_CONTAINER_H_
