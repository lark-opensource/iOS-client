// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_FLEX_LAYOUT_ALGORITHM_H_
#define LYNX_STARLIGHT_LAYOUT_FLEX_LAYOUT_ALGORITHM_H_

#include <memory>

#include "base/size.h"
#include "starlight/layout/flex_info.h"
#include "starlight/layout/layout_algorithm.h"

namespace lynx {
namespace starlight {
class LayoutObject;

class ComputedCSSStyle;

class FlexLayoutAlgorithm : public LayoutAlgorithm {
 public:
  FlexLayoutAlgorithm(LayoutObject*);

  // TODO(zzz):unified handle process
  void SizeDeterminationByAlgorithm() override;
  void AlignInFlowItems() override;

  BoxPositions GetAbsoluteOrFixedItemInitialPosition(
      LayoutObject* absolute_or_fixed_item) override;

  void InitializeAlgorithmEnv() override;
  void Reset() override;
  void SetContainerBaseline() override;

 private:
  /*Algorithm-3
   * Determine the flex base size and hypothetical main size of each item:*/
  float DetermineFlexBaseSizeAndHypotheticalMainSize();
  float ChildCalculateFlexBasis(LayoutObject* child);

  // Algorithm-4 Calculate the main size of the flex container and collect flex
  // items into flex lines
  float CalculateFlexContainerMainSize(float total_hypothetical_main_size);

  // Algorithm-5 Determine the main size of the flex container
  void DetermineFlexContainerMainSize(float flex_container_main_size);

  // Algorithm-6 Resolve the flexible lengths of all the flex items to find
  // their used main size.
  void ResolveFlexibleLengths(LineInfo* line_info);

  // Algorithm-7 Determine the hypothetical cross size of each item
  void DetermineHypotheticalCrossSize();

  // Algorithm-8 Calculate the cross size of each flex line.
  void CalculateCrossSizeOfEachFlexLine();

  // Algorithm-11 Determine the used cross size of each flex item
  bool ShouldApplyStretchAndLayoutLater(int idx);
  void DetermineUsedCrossSizeOfEachFlexItem();
  bool IsCrossSizeAutoAndMarginNonAuto(int idx);

  // Algorithm-12 Distribute any remaining free space
  void DistributeRemainingFreeSpace(LineInfo* line_info);
  bool CalculateAndSetAutoMargins(Items& line_items,
                                  float remaining_free_space);
  void CalculateJustifyContent(LineInfo* line_info, float& main_axis_start,
                               float& main_axis_interval);
  void MainAxisAlignment(Items line_items, float main_axis_start,
                         float main_axis_interval);
  void CalculateAlignContent(float& cross_axis_start,
                             float& cross_axis_interval);
  void CrossAxisAlignment(LineInfo* line_info, float& line_cross_offset);

  // Algorithm-14 Align all flex items along the cross-axis per align-self
  void AlignItems(int idx, float line_cross_size, float line_cross_offset,
                  float line_baseline);

  void CalculateWrapReverse();

  // Algorithm-15 Determine the flex container’s used cross size:
  void DetermineContainerCrossSize();

  // SOME UPDATE FUNCTIONS

  void UpdateContainerMainSize(float container_main_size);
  void UpdateCrossSize(float container_cross_size);

  float GetOuterHypotheticalMainSize(int idx);
  float GetOuterFlexBaseMainSIze(int idx);
  float GetOuterHypotheticalCrossSize(int idx);

  Position GetAbsoluteOrFixedItemCrossAxisPosition(
      LayoutObject* absolute_or_fixed_item);
  Position GetAbsoluteOrFixedItemMainAxisPosition(
      LayoutObject* absolute_or_fixed_item);

  std::unique_ptr<FlexInfo> flex_info_;
};
}  // namespace starlight
}  // namespace lynx
#endif  // LYNX_STARLIGHT_LAYOUT_FLEX_LAYOUT_ALGORITHM_H_
