// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_LINEAR_LAYOUT_ALGORITHM_H_
#define LYNX_STARLIGHT_LAYOUT_LINEAR_LAYOUT_ALGORITHM_H_

#include <vector>

#include "base/size.h"
#include "starlight/layout/layout_algorithm.h"

namespace lynx {
namespace starlight {
class LayoutObject;
typedef std::vector<LayoutObject*> Items;
class ComputedCSSStyle;

class LinearLayoutAlgorithm : public LayoutAlgorithm {
 public:
  LinearLayoutAlgorithm(LayoutObject*);

  void SizeDeterminationByAlgorithm() override;
  void AlignInFlowItems() override;

  BoxPositions GetAbsoluteOrFixedItemInitialPosition(
      LayoutObject* absolute_or_fixed_item) override;

  Position GetAbsoluteOrFixedItemCrossAxisPosition(
      LayoutObject* absolute_or_fixed_item);
  Position GetAbsoluteOrFixedItemMainAxisPosition(
      LayoutObject* absolute_or_fixed_item);
  void SetContainerBaseline() override;

 protected:
  void Reset() override;
  // Algorithm-1
  void DetermineItemSize();
  // Algorithm-2
  virtual void DetermineContainerSize();
  // Algorithm-3
  virtual void UpdateChildSize(const size_t idx);
  void UpdateChildSizeInternal(const size_t idx,
                               const Constraints& used_container_constraints);
  void CrossAxisAlignment(LayoutObject* item);

  void LayoutWeightedChildren(const std::vector<float>& base_sizes);

  void InitializeAlgorithmEnv() override;

  virtual void UpdateContainerSize();

  void AfterResultBorderBoxSize() override;

  LinearLayoutGravityType GetComputedLinearLayoutGravity(
      const ComputedCSSStyle& style) const;
  LinearGravityType GetLogicLinearGravityType() const;

  bool IsLayoutGravityDefault(LinearLayoutGravityType layout_gravity) const;

  bool IsLayoutGravityAfter(LinearLayoutGravityType layout_gravity) const;

  bool IsLayoutGravityCenter(LinearLayoutGravityType layout_gravity) const;

  bool IsLayoutGravityFill(LinearLayoutGravityType layout_gravity) const;

  bool IsGravityAfter(LinearGravityType gravity) const;

  bool IsGravityCenter(LinearGravityType gravity) const;

  bool IsGravityPhysical(LinearGravityType gravity) const;

  void HandleScrollView();

  std::vector<float> main_size_;
  std::vector<float> cross_size_;
  float total_main_size_;
  float total_cross_size_;
  float remaining_size_;
  float baseline_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_LINEAR_LAYOUT_ALGORITHM_H_
