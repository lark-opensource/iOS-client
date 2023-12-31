// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_RELATIVE_LAYOUT_ALGORITHM_H_
#define LYNX_STARLIGHT_LAYOUT_RELATIVE_LAYOUT_ALGORITHM_H_

#include <map>
#include <set>
#include <vector>

#include "base/size.h"
#include "starlight/layout/layout_algorithm.h"

namespace lynx {
namespace starlight {
class LayoutObject;
class ComputedCSSStyle;

class RelativeLayoutAlgorithm : public LayoutAlgorithm {
 public:
  RelativeLayoutAlgorithm(LayoutObject*);
  ~RelativeLayoutAlgorithm() = default;

  void SizeDeterminationByAlgorithm() override;
  void AlignInFlowItems() override;

  BoxPositions GetAbsoluteOrFixedItemInitialPosition(
      LayoutObject* absolute_or_fixed_item) override;
  void InitializeAlgorithmEnv() override;
  void SetContainerBaseline() override{};

 private:
  void UpdateChildrenSize();

  void DetermineContainerSizeHorizontal();
  void DetermineContainerSizeVertical();

  void UpdateContainerSize();

  void GenerateIDMap();
  void Sort();

  Constraints ComputeConstraints(
      size_t idx, DirectionValue<LayoutUnit>& position_constraint,
      bool horizontal_only) const;

  LayoutUnit GetPositionConstraints(const LayoutObject& obj,
                                    Direction direction) const;
  void GetPositionConstraints(const LayoutObject& obj,
                              DirectionValue<LayoutUnit>& position_constraint,
                              bool horizontal_only) const;

  void ComputeProposedPositions(
      size_t idx, const DirectionValue<LayoutUnit>& position_constraint,
      const FloatSize& layout_result, Dimension dimension);

  void ComputePosition(const ComputedCSSStyle& css, Dimension dimension,
                       const float size_with_margin,
                       const DirectionValue<LayoutUnit>& position_constraint,
                       DirectionValue<float>& position) const;
  void ResetMinMaxPosition();

  void AddDependencyForID(size_t idx, int id,
                          std::set<size_t>& item_dependencies,
                          std::vector<std::set<size_t>>& reverse_dependencies,
                          Dimension dimension) const;

  void AddDependencyForIDVertical(
      size_t idx, const ComputedCSSStyle* style,
      std::set<size_t>& item_dependencies,
      std::vector<std::set<size_t>>& reverse_dependencies) const;

  void AddDependencyForIDHorizontal(
      size_t idx, const ComputedCSSStyle* style,
      std::set<size_t>& item_dependencies,
      std::vector<std::set<size_t>>& reverse_dependencies) const;

  void RecomputeProposedPosition(const std::vector<size_t>& orders,
                                 Dimension dimension, Direction start);

  std::vector<DirectionValue<float>> proposed_position_;
  DimensionValue<float> min_position_;
  DimensionValue<float> max_position_;
  std::map<int, size_t> id_map_;
  std::vector<size_t> horizontal_order_;
  std::vector<size_t> vertical_order_;
  std::vector<FloatSize> layout_results_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_RELATIVE_LAYOUT_ALGORITHM_H_
