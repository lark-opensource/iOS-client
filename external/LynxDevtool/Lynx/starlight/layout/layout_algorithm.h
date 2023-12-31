// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_LAYOUT_ALGORITHM_H_
#define LYNX_STARLIGHT_LAYOUT_LAYOUT_ALGORITHM_H_

#include <array>
#include <vector>

#include "base/size.h"
#include "starlight/layout/box_info.h"
#include "starlight/layout/direction_selector.h"
#include "starlight/layout/layout_object.h"
#include "starlight/layout/logic_direction_utils.h"
#include "starlight/types/measure_context.h"

namespace lynx {
namespace starlight {
class ComputedCSSStyle;

typedef std::vector<LayoutObject*> Items;

class LayoutAlgorithm : public DirectionSelector {
 public:
  LayoutAlgorithm(LayoutObject* container);
  virtual ~LayoutAlgorithm();

  void SetupRoot(const Constraints& root_constraints);

  LayoutUnit PercentBase(Dimension dimension) const {
    return container_constraints_[dimension].ToPercentBase();
  }

  Constraints GenerateDefaultConstraint(const LayoutObject& child) const;
  bool IsInflowSubTreeInSync() const;

  const ComputedCSSStyle* GetCSSStyle() const { return container_style_; }

  void Initialize(const Constraints& constraints);
  FloatSize SizeDetermination();
  void Alignment();

  void Update(const Constraints& constraints);

  virtual void SetContainerBaseline() = 0;

 protected:
  virtual void Reset(){};
  void UpdateAvailableSizeAndMode(const Constraints& constraints);
  FloatSize PostLayoutProcessingAndResultBorderBoxSize();
  virtual void AfterResultBorderBoxSize();
  float ScreenWidth() { return container_->ScreenWidth(); }

  virtual BoxPositions GetAbsoluteOrFixedItemInitialPosition(
      LayoutObject* absolute_or_fixed_item) = 0;

  virtual void AlignInFlowItems() = 0;

  // Initialize layout environment,init some relevant parameters
  virtual void InitializeAlgorithmEnv() = 0;

  // TODO(zzz):unified handle process
  virtual void SizeDeterminationByAlgorithm() = 0;

  LayoutObject* container_;
  const ComputedCSSStyle* container_style_;

  Constraints container_constraints_;

  Items sticky_items = {};
  Items absolute_or_fixed_items_ = {};
  Items inflow_items_ = {};

 private:
  LayoutAlgorithm();

  // relative
  void HandleRelativePosition();

  // Absolute | Fixed
  void MeasureAbsoluteAndFixed();
  void AlignAbsoluteAndFixedItems();

  void ItemsUpdateAlignment();

  void InitializeChildren();
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_LAYOUT_ALGORITHM_H_
