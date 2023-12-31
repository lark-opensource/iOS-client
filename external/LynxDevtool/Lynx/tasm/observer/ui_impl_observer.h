// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_OBSERVER_UI_IMPL_OBSERVER_H_
#define LYNX_TASM_OBSERVER_UI_IMPL_OBSERVER_H_

namespace lynx {
namespace tasm {
class AttributeHolder;
class VirtualNode;
class Element;

class UIImplObserver {
 public:
  UIImplObserver() {}
  virtual ~UIImplObserver() {}
  virtual void OnElementDataModelSetted(Element* ptr,
                                        AttributeHolder* new_node_ptr) = 0;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_OBSERVER_UI_IMPL_OBSERVER_H_
