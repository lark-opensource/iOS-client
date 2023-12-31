// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/react/element_container.h"

#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

ElementContainer::ElementContainer(Element* element) : element_(element) {
  was_stacking_context_ = IsStackingContextNode();
  old_index_ = ZIndex();
}

ElementContainer::~ElementContainer() {
  if (!element_->will_destroy()) {
    element_manager()->RemoveDirtyContext(this);
  }
  // Remove self from parent's children.
  if (parent_) {
    auto it =
        std::find(parent_->children_.begin(), parent_->children_.end(), this);
    if (it != parent_->children_.end()) parent_->children_.erase(it);
    parent_ = nullptr;
  }
  // Set children's parent to null.
  for (auto child : children_) {
    if (child) {
      child->parent_ = nullptr;
    }
  }
}

int ElementContainer::id() const { return element_->impl_id(); }

void ElementContainer::AddChild(ElementContainer* child, int index) {
  if (child->parent()) child->RemoveFromParent();
  children_.push_back(child);

  if (!child->element()->IsLayoutOnly()) {
    none_layout_only_children_size_++;
  }
  // If the index is equal to -1 should add to the last
  if (index != -1) {
    index = index + static_cast<int>(negative_z_children_.size());
  }

  child->parent_ = this;
  if ((child->ZIndex() != 0 || child->IsSticky()) && need_update_) {
    MarkDirty();
  }
  if (!child->element()->IsLayoutOnly()) {
    painting_context()->InsertPaintingNode(id(), child->id(), index);
  }
}

void ElementContainer::RemoveChild(ElementContainer* child) {
  auto it = std::find(children_.begin(), children_.end(), child);
  if (it != children_.end()) {
    children_.erase(it);
    if (child->element_->ZIndex() < 0) {
      auto z_it = std::find(negative_z_children_.begin(),
                            negative_z_children_.end(), child);
      if (z_it != negative_z_children_.end()) {
        negative_z_children_.erase(z_it);
      }
    }
    if (!child->element_->IsLayoutOnly()) {
      none_layout_only_children_size_--;
    }
  }

  child->parent_ = nullptr;
  if (!need_update_) {
    return;
  }
  if (child->ZIndex() != 0) {
    // The stacking context need update
    MarkDirty();
  }
  if (child->IsStackingContextNode()) {
    // Avoid the unnecessary sort
    element_manager()->RemoveDirtyContext(child);
  }
}

void ElementContainer::RemoveFromParent() {
  if (!parent_) return;
  if (!element()->IsLayoutOnly()) {
    painting_context()->RemovePaintingNode(parent_->id(), id(), 0);
  } else {
    // Layout only node remove children from parent recursively.
    if (element_->is_radon_element()) {
      for (int i = static_cast<int>(element_->GetChildCount()) - 1; i >= 0;
           --i) {
        Element* child = element_->GetChildAt(i);
        child->element_container()->RemoveFromParent();
      }
    } else {
      // fiber element;
      auto* child = static_cast<FiberElement*>(element())->first_render_child();
      while (child) {
        child->element_container()->RemoveFromParent();
        child = child->next_render_sibling();
      }
    }
  }
  parent_->RemoveChild(this);
}

void ElementContainer::Destroy() {
  // Layout only destroy recursively, the z-index child may has been destroyed
  if (!element()->IsLayoutOnly()) {
    painting_context()->DestroyPaintingNode(parent() ? parent()->id() : -1,
                                            id(), 0);
  } else {
    if (element_->is_radon_element()) {
      // fiber element's layout only children handle Destroy in self Destructor
      for (int i = static_cast<int>(element_->GetChildCount()) - 1; i >= 0;
           --i) {
        element_->GetChildAt(i)->element_container()->Destroy();
      }
    }
  }
  if (parent()) {
    parent()->RemoveChild(this);
  }
}

void ElementContainer::RemoveSelf(bool destroy) {
  if (!parent_) return;

  if (destroy) {
    Destroy();
  } else {
    RemoveFromParent();
  }
}

void ElementContainer::InsertSelf() {
  if (!parent_ && element()->parent()) {
    element()->parent()->element_container()->AttachChildToTargetContainer(
        element(), element()->next_render_sibling());
  }
}

PaintingContext* ElementContainer::painting_context() {
  return element()->painting_context();
}

std::pair<ElementContainer*, int> ElementContainer::FindParentForChild(
    Element* child) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, FIND_PARENT_FOR_CHILD);
  Element* node = element_;
  size_t ui_index = element_->GetUIIndexForChild(child);
  while (node->IsLayoutOnly()) {
    Element* parent = node->parent();
    if (!parent) {
      return {nullptr, -1};
    }
    ui_index += static_cast<int>(parent->GetUIIndexForChild(node));
    node = parent;
  }
  return {node->element_container(), ui_index};
}

void AttachChildToTargetContainerRecursive(ElementContainer* parent,
                                           Element* child, int& index) {
  if (child->ZIndex() != 0) {
    auto ui_parent = parent->EnclosingStackingContextNode();
    ui_parent->AddChild(child->element_container(), -1);
    return;
  }
  if (!parent->element()->CanHasLayoutOnlyChildren() && child->IsLayoutOnly() &&
      !child->is_virtual()) {
    child->element_container()->TransitionToNativeView();
  }
  parent->AddChild(child->element_container(), index);
  if (!child->IsLayoutOnly()) {
    ++index;
    return;
  }
  // Layout only node should add subtree to parent recursively.
  if (parent->element()->is_radon_element()) {
    for (size_t i = 0; i < child->GetChildCount(); ++i) {
      Element* grand_child = child->GetChildAt(i);
      AttachChildToTargetContainerRecursive(parent, grand_child, index);
    }
  } else {
    auto* grand = static_cast<FiberElement*>(child)->first_render_child();
    while (grand) {
      AttachChildToTargetContainerRecursive(parent, grand, index);
      grand = grand->next_render_sibling();
    }
  }
}

void ElementContainer::AttachChildToTargetContainer(Element* child,
                                                    Element* ref) {
  if (child->ZIndex() != 0) {
    EnclosingStackingContextNode()->AddChild(child->element_container(), -1);
    return;
  }
  std::pair<ElementContainer*, int> result;
  if (element_->is_radon_element()) {
    result = FindParentForChild(child);
  } else {
    result = FindParentAndIndexForChildForFiber(element_, child, ref);
  }
  if (result.first) {
    int index = result.second;
    AttachChildToTargetContainerRecursive(result.first, child, index);
  }
}

// Calculate position for element and update it to impl layer.
void ElementContainer::UpdateLayout(float left, float top,
                                    bool transition_view) {
  // Self is updated or self position is changed because of parent's frame
  // changing.

  // The z-index child's parent may be different from ui parent,
  // and need to add the offset of the position
  if (element_->ZIndex() != 0) {
    left = element_->left();
    top = element_->top();
    auto* ui_parent = parent();
    auto* parent = element_->parent();
    while (parent && ui_parent && ui_parent->element() != parent) {
      left += parent->left();
      top += parent->top();
      parent = parent->parent();
    }
  }
  bool need_update_impl =
      (!transition_view || is_layouted_) &&
      (element_->frame_changed() || left != last_left_ || top != last_top_);

  last_left_ = left;
  last_top_ = top;

  // The offset of child's position in its real parent's coordinator.
  float dx = left, dy = top;

  if (!element_->IsLayoutOnly()) {
    dx = 0;
    dy = 0;

    if (need_update_impl) {  // Update to impl layer

      element_->painting_context()->UpdateLayout(
          element_->impl_id(), left, top, element_->width(), element_->height(),
          element_->paddings().data(), element_->margins().data(),
          element_->borders().data(), nullptr,
          element_->is_sticky_ ? element_->sticky_positions_.data() : nullptr,
          element_->max_height());
    }
    if (need_update_impl || props_changed_) {
      element_->painting_context()->OnNodeReady(element_->impl_id());
      props_changed_ = false;
    }
  }

  // Layout children
  for (size_t i = 0; i < element_->GetChildCount(); ++i) {
    Element* child = element_->GetChildAt(i);
    child->element_container()->UpdateLayout(
        child->left() + dx, child->top() + dy, transition_view);
  }
  element_->MarkUpdated();

  is_layouted_ = true;
}

void ElementContainer::UpdateLayoutWithoutChange() {
  if (props_changed_) {
    element_->painting_context()->OnNodeReady(element_->impl_id());
    props_changed_ = false;
  }
  for (size_t i = 0; i < element_->GetChildCount(); ++i) {
    Element* child = element_->GetChildAt(i);
    if (child->element_container()) {
      child->element_container()->UpdateLayoutWithoutChange();
    }
  }
}

void ElementContainer::TransitionToNativeView() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementContainer::TransitionToNativeView");
  if (!element_->IsLayoutOnly() || element_->is_virtual()) {
    return;
  }
  bool need_release_prop_bundle = false;

  LOGI("[ElementContainer] TransitionToNativeView tag:"
       << element_->tag_.c_str() << ",id:" << element_->id_);
  // Remove from current parent.
  RemoveFromParent();

  // Create LynxUI in impl layer.
  element_->set_is_layout_only(false);
  // Push painting related props into prop_bundle.
  if (!element_->prop_bundle_) {
    element_->prop_bundle_ = PropBundle::Create();
    element_->prop_bundle_->set_tag(element_->tag_);
    need_release_prop_bundle = true;
  }
  element_->PushToBundle(kPropertyIDOverflow);
  element_->painting_context()->CreatePaintingNode(
      element_->id_, element_->prop_bundle_.get(), element_->TendToFlatten());

  // Insert children to this.
  InsertSelf();

  // Mark need update layout value to impl layer.
  element_->frame_changed_ = true;

  UpdateLayout(last_left_, last_top_, true);

  int ui_index = 0;
  for (size_t i = 0; i < element_->GetChildCount(); ++i) {
    Element* child = element_->GetChildAt(i);
    AttachChildToTargetContainerRecursive(this, child, ui_index);
    child->frame_changed_ = true;
    child->element_container()->UpdateLayout(child->left(), child->top(), true);
  }

  // the updateLayout is not in LayoutContext flow, just flush patching
  // immediately. otherwise, the updateLayout may execute after followed
  // operation,such as Destroy.
  painting_context()->UpdateLayoutPatching();
  if (need_release_prop_bundle) {
    element_->prop_bundle_ = nullptr;
  }
}

void ElementContainer::MoveContainers(ElementContainer* old_parent,
                                      ElementContainer* new_parent) {
  if (!new_parent) return;
  if (old_parent == new_parent) return;

  RemoveFromParent();
  new_parent->AddChild(this, -1);
}

ElementContainer* ElementContainer::EnclosingStackingContextNode() {
  Element* current = element();
  for (; current != nullptr; current = current->parent()) {
    if (current->IsStackingContextNode()) return current->element_container();
  }
  // Unreachable code
  return nullptr;
}

void ElementContainer::MoveAllZChildren(ElementContainer* parent) {
  if (!parent) return;
  // Need to move all z-index containers recursively
  auto* node = parent->EnclosingStackingContextNode();
  for (const auto& child : children_) {
    if (child->ZIndex() != 0) {
      child->MoveContainers(child->parent(), node);
    }
  }
}

void ElementContainer::StyleChanged() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ElementContainer::StyleChanged");
  props_changed_ = true;
  if (element()->GetEnableZIndex()) {
    ZIndexChanged();
  }
}

void ElementContainer::ZIndexChanged() {
  if (!parent() || !element()->parent() || element()->IsLayoutOnly()) return;
  TRACE_EVENT(LYNX_TRACE_CATEGORY, Z_INDEX_CHANGED);
  auto* element_parent = element()->parent();
  bool is_stacking_context = IsStackingContextNode();
  auto* parent_stacking_context = parent()->EnclosingStackingContextNode();
  auto z = ZIndex();
  // The stacking context changed, need to move the z-index children
  if (was_stacking_context_ != is_stacking_context) {
    ElementContainer* new_parent =
        is_stacking_context ? this : parent_stacking_context;
    // The z-index elements may add to another stacking context
    for (size_t i = 0; i < element()->GetChildCount(); i++) {
      auto* child = element()->GetChildAt(i);
      if (child->ZIndex() != 0) {
        child->element_container()->MoveContainers(
            child->element_container()->parent(), new_parent);
      }
    }
    MoveAllZChildren(new_parent);
  }
  // If the state of z-index is 0 has changed, need to remount
  // Choose the parent container in the attach function
  if ((z == 0 && old_index_ != 0) || (old_index_ == 0 && z != 0)) {
    RemoveFromParent();
    // Use the parent of element to find the ui parent
    element_parent->element_container()->AttachChildToTargetContainer(
        element(), element()->next_render_sibling());
    parent_stacking_context->MarkDirty();
  } else if (old_index_ != z) {  // Just mark the stacking context is dirty
    parent_stacking_context->MarkDirty();
  }
  old_index_ = z;
  was_stacking_context_ = is_stacking_context;
}

int ElementContainer::ZIndex() { return element_->ZIndex(); }

void ElementContainer::MarkDirty() {
  if (dirty_) return;

  element_manager()->InsertDirtyContext(this);
}

void ElementContainer::UpdateZIndexList() {
  dirty_ = false;
  negative_z_children_.clear();
  std::vector<ElementContainer*> z_list;
  for (const auto& child : children_) {
    if (child->ZIndex() != 0 || child->IsSticky()) {
      z_list.push_back(child);
    }
  }

  if (z_list.empty()) return;

  TRACE_EVENT(LYNX_TRACE_CATEGORY, UPDATE_Z_INDEX_LIST);
  std::stable_sort(z_list.begin(), z_list.end(),
                   [](const auto& first, const auto& second) {
                     return first->ZIndex() < second->ZIndex();
                   });

  // Doesn't insert to dirty list again
  SetNeedUpdate(false);
  for (const auto& child : z_list) {
    // Append to the front of the children if the z-index is negative
    if (child->ZIndex() < 0) {
      AddChild(child, 0);
      negative_z_children_.push_back(child);
    } else {
      // Append to the end of the children
      AddChild(child, -1);
    }
  }
  SetNeedUpdate(true);
}

ElementManager* ElementContainer::element_manager() {
  return element()->element_manager();
}

bool ElementContainer::IsStackingContextNode() {
  return element()->IsStackingContextNode();
}

bool ElementContainer::IsSticky() { return element()->is_sticky_; }

//========helper function for get index for fiber ========
// static
std::pair<ElementContainer*, int>
ElementContainer::FindParentAndIndexForChildForFiber(Element* parent,
                                                     Element* child,
                                                     Element* ref) {
  auto* real_parent = parent;
  int index = 0;
  if (ref) {
    // insert to the middle, child is already inserted in Element, just use
    // child to get index
    index = GetUIIndexForChildForFiber(real_parent, child);
    while (real_parent->IsLayoutOnly()) {
      auto* up_parent = real_parent->render_parent();
      if (!up_parent) {
        return {nullptr, -1};
      }
      index += GetUIIndexForChildForFiber(up_parent, real_parent);
      real_parent = up_parent;
    }
  } else {
    while (real_parent->IsLayoutOnly()) {
      real_parent = real_parent->render_parent();
      if (!real_parent) {
        break;
      }
    }
    index = real_parent->element_container()->none_layout_only_children_size_;
  }

  return {real_parent->element_container(), index};
}

// static
int ElementContainer::GetUIIndexForChildForFiber(Element* parent,
                                                 Element* child) {
  auto* node = parent->first_render_child();
  int index = 0;
  bool found = false;

  while (node) {
    if (child == node) {
      found = true;
      break;
    }
    if (node->ZIndex() != 0) {
      node = node->next_render_sibling();
      continue;
    }
    index += (node->IsLayoutOnly() ? GetUIChildrenCountForFiber(node) : 1);
    node = node->next_render_sibling();
  }
  if (!found) {
    LOGE("element can not found:");
    DCHECK(false);
  }
  return index;
}

// static
int ElementContainer::GetUIChildrenCountForFiber(Element* parent) {
  int ret = 0;
  auto* child = parent->first_render_child();
  while (child) {
    if (child->IsLayoutOnly()) {
      ret += GetUIChildrenCountForFiber(child);
    } else if (child->ZIndex() == 0) {
      ret++;
    }
    child = child->next_render_sibling();
  }
  return ret;
}

}  // namespace tasm
}  // namespace lynx
