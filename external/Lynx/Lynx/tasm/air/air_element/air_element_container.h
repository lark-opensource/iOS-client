// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_AIR_ELEMENT_AIR_ELEMENT_CONTAINER_H_
#define LYNX_TASM_AIR_AIR_ELEMENT_AIR_ELEMENT_CONTAINER_H_

#include <memory>
#include <utility>
#include <vector>

#include "base/geometry/point.h"
#include "tasm/react/painting_context.h"

namespace lynx {
namespace tasm {

class AirElement;
class ElementManager;

class AirElementContainer {
 public:
  explicit AirElementContainer(AirElement* air_element);
  ~AirElementContainer() = default;

  AirElementContainer(const AirElementContainer& node) = delete;
  AirElementContainer& operator=(const AirElementContainer& node) = delete;

  AirElement* air_element() const { return air_element_; }
  AirElementContainer* parent() const { return parent_; }
  const std::vector<AirElementContainer*>& children() const {
    return children_;
  }
  PaintingContext* painting_context();
  int id() const;

  void AddChild(AirElementContainer* child, int index);
  void RemoveFromParent();
  void Destroy();
  void RemoveSelf(bool destroy);
  void InsertSelf();
  void UpdateLayout(float left, float top, bool transition_view = false);
  void UpdateLayoutWithoutChange();
  void AttachChildToTargetContainer(AirElement* child);

 private:
  // Use RemoveFromParent/Destroy
  void RemoveChild(AirElementContainer* child);
  ElementManager* element_manager();
  float last_left_{0};
  float last_top_{0};
  std::pair<AirElementContainer*, int> FindParentForChild(AirElement* child);
  AirElement* air_element_ = nullptr;
  AirElementContainer* parent_ = nullptr;

  std::vector<AirElementContainer*> children_;
  // indicate the AirElementContainer has finished first layout
  bool is_layouted_{false};
  // true if the AirElement's props has changed during this patch
  bool props_changed_{true};
  // the children size does not contain layout only nodes
  int none_layout_only_children_size_{0};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_AIR_AIR_ELEMENT_AIR_ELEMENT_CONTAINER_H_
