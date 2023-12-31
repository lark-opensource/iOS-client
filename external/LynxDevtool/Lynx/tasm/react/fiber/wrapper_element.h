// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_WRAPPER_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_WRAPPER_ELEMENT_H_

#include <utility>

#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {

class WrapperElement : public FiberElement {
 public:
  WrapperElement(ElementManager* manager);
  bool is_wrapper() const override { return true; }

  void PrepareForCreateOrUpdate(ActionOption& option) override;

  void UpdateCurrentFlushOption(ActionOption& option) override {
    // do nothing for Wrapper Element UpdateCurrentFlushOption
  }

  static void AttachChildToTargetParentForWrapper(FiberElement* parent,
                                                  FiberElement* child,
                                                  FiberElement* ref_node);
  static void AttachChildToTargetContainerRecursive(FiberElement* parent,
                                                    FiberElement* child,
                                                    FiberElement* wrapper);
  /**
   *  find the Real parent for a wrapper parent
   * @param parent the parent in the Element tree
   * @param child  current child node
   * @param ref the ref node to be inserted before, null means to append to the
   * end
   * @return return the real parent and the index in LayoutNode tree
   */
  static std::pair<FiberElement*, int> FindParentForChildForWrapper(
      FiberElement* parent, FiberElement* child, FiberElement* ref);
  static int GetLayoutIndexForChildForWrapper(FiberElement* parent,
                                              FiberElement* child);
  static size_t GetLayoutChildrenCountForWrapper(FiberElement* node);

  static void RemoveFromParentForWrapperChild(FiberElement* parent,
                                              FiberElement* child);

  static FiberElement* FindFirstChildOrSiblingAsRefNode(FiberElement* ref);

  static void RemoveChildRecursively(FiberElement* parent, FiberElement* child);

  static FiberElement* FindTheRealParent(FiberElement* node);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_WRAPPER_ELEMENT_H_
