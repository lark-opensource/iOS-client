// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/wrapper_element.h"

#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

WrapperElement::WrapperElement(ElementManager* manager)
    : FiberElement(manager, "wrapper") {
  is_layout_only_ = true;
}

void WrapperElement::PrepareForCreateOrUpdate(ActionOption& option) {
  // do nothing for Wrapper Element CreateOrUpdate action, only
  // createElementContainer
  if (!has_painting_node_) {
    CreateElementContainer(false);
    has_painting_node_ = true;
  }
}

FiberElement* WrapperElement::FindFirstChildOrSiblingAsRefNode(
    FiberElement* ref) {
  while (ref) {
    if (!ref->is_wrapper()) {
      return ref;
    }
    auto* first_child = ref->first_render_child_;

    if (first_child) {
      if (!first_child->is_wrapper()) {
        return first_child;
      }
      auto* ret = FindFirstChildOrSiblingAsRefNode(first_child);
      if (ret && !ret->is_wrapper()) {
        return ret;
      }
    }
    ref = ref->next_render_sibling_;
  }
  return ref;
}

void WrapperElement::AttachChildToTargetParentForWrapper(
    FiberElement* parent, FiberElement* child, FiberElement* ref_node) {
  // ref is null, find the first none-wrapper ancestor's next sibling as ref!
  auto* temp_parent = parent;

  if (ref_node && ref_node->is_wrapper()) {
    // this API always return null or non-wrapper ref_node
    ref_node = FindFirstChildOrSiblingAsRefNode(ref_node);
  }
  DCHECK(!ref_node || !ref_node->is_wrapper());

  while (!ref_node && temp_parent && temp_parent->is_wrapper()) {
    ref_node = temp_parent->next_render_sibling_;

    if (ref_node && ref_node->is_wrapper()) {
      // try to find the wrapper's first non-wrapper child as ref
      ref_node = FindFirstChildOrSiblingAsRefNode(ref_node);
    }

    if (ref_node && !ref_node->is_wrapper()) {
      // break when found any non-wrapper ref_node
      break;
    }
    temp_parent = temp_parent->render_parent_;
  }

  FiberElement* real_parent = parent;
  while (real_parent->is_wrapper()) {
    auto* p = real_parent->render_parent_;
    if (!p) {
      break;
    }
    real_parent = p;
  }

  AttachChildToTargetContainerRecursive(real_parent, child, ref_node);
}

std::pair<FiberElement*, int> WrapperElement::FindParentForChildForWrapper(
    FiberElement* parent, FiberElement* child, FiberElement* ref_node) {
  FiberElement* node = parent;

  if (!ref_node && !parent->is_wrapper()) {
    // ref is null & parent is none-wrapper, layout_index:-1 is to append the
    // end
    return {parent, -1};
  }

  int in_wrapper_index = 0;
  if (!ref_node && parent->is_wrapper()) {
    // append to wrapper, use parent as ref and then add self layout index in
    // parent
    in_wrapper_index = GetLayoutIndexForChildForWrapper(parent, child);
    ref_node = parent;
  }

  int layout_index = GetLayoutIndexForChildForWrapper(node, ref_node);

  if (layout_index == -1) {
    return {nullptr, layout_index};
  }
  while (node->is_wrapper()) {
    auto* p = node->render_parent_;
    if (!p) {
      return {nullptr, -1};
    }
    layout_index += static_cast<int>(GetLayoutIndexForChildForWrapper(p, node));
    node = p;
  }
  return {node, layout_index + in_wrapper_index};
}

int WrapperElement::GetLayoutIndexForChildForWrapper(FiberElement* parent,
                                                     FiberElement* child) {
  int index = 0;
  bool found = false;
  for (const auto& it : parent->children()) {
    const auto& current = it;
    if (child == current) {
      found = true;
      break;
    }
    index +=
        (current->is_wrapper() ? GetLayoutChildrenCountForWrapper(current.Get())
                               : 1);
  }
  if (!found) {
    LOGI("fiber element can not found for wrapper:" + parent->GetTag());
    // index:-1 means the child id was not a child of parent id
    return -1;
  }
  return index;
}

size_t WrapperElement::GetLayoutChildrenCountForWrapper(FiberElement* node) {
  size_t ret = 0;
  for (auto current : node->children()) {
    if (current->is_wrapper()) {
      ret += GetLayoutChildrenCountForWrapper(current.Get());
    } else {
      ret++;
    }
  }
  return ret;
}

void WrapperElement::AttachChildToTargetContainerRecursive(FiberElement* parent,
                                                           FiberElement* child,
                                                           FiberElement* ref) {
  // in the mapped layout node tree, insert the wrapper node in front of its
  // first child real parent:
  // [node0,node1,[wrapper,wrapper-child0,wrapper-child1],node3....]

  DCHECK(!ref || !ref->is_wrapper());
  if (!child->is_wrapper()) {
    parent->InsertLayoutNode(child, ref);
    return;
  }

  // wrapper node should add subtree to parent recursively.
  auto* grand = child->first_render_child_;
  while (grand) {
    AttachChildToTargetContainerRecursive(parent, grand, ref);
    grand = grand->next_render_sibling_;
  }
}

FiberElement* WrapperElement::FindTheRealParent(FiberElement* node) {
  FiberElement* real_parent = node;
  while (real_parent->is_wrapper()) {
    auto* p = static_cast<FiberElement*>(real_parent->render_parent());
    if (!p) {
      break;
    }
    real_parent = p;
  }
  return real_parent;
}

// for layout node
void WrapperElement::RemoveChildRecursively(FiberElement* parent,
                                            FiberElement* child) {
  if (!child->is_wrapper()) {
    parent->RemoveLayoutNode(child);
  }
  auto* grand = child->first_render_child();
  while (grand) {
    RemoveChildRecursively(parent, static_cast<FiberElement*>(grand));
    grand = grand->next_render_sibling();
  }
}

void WrapperElement::RemoveFromParentForWrapperChild(FiberElement* parent,
                                                     FiberElement* child) {
  FiberElement* real_parent = FindTheRealParent(parent);
  if (real_parent->is_wrapper()) {
    LOGE(
        "[WrapperElement] parent maybe detached from the view tree, can not "
        "find real parent!");
    return;
  }

  RemoveChildRecursively(real_parent, child);
}

}  // namespace tasm
}  // namespace lynx
