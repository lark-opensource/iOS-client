// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/layout/layout_algorithm.h"

#include <algorithm>

#include "starlight/layout/box_info.h"
#include "starlight/layout/layout_object.h"
#include "starlight/layout/position_layout_utils.h"
#include "starlight/layout/property_resolving_utils.h"
#include "starlight/layout/relative_layout_algorithm.h"

namespace lynx {
namespace starlight {

LayoutAlgorithm::LayoutAlgorithm(LayoutObject* container)
    : DirectionSelector(
          container->GetCSSStyle()->IsRow(container->GetLayoutConfigs(),
                                          container->attr_map()),
          container->GetCSSStyle()->DirectionIsReverse(
              container->GetLayoutConfigs(), container->attr_map()),
          container->GetCSSStyle()->IsAnyRtl()),
      container_(container),
      container_style_(container->GetCSSStyle()) {}

LayoutAlgorithm::~LayoutAlgorithm() {
  container_ = nullptr;
  container_style_ = nullptr;
}

void LayoutAlgorithm::Update(const Constraints& constraints) {
  UpdateAvailableSizeAndMode(constraints);
  Reset();
}

void LayoutAlgorithm::Initialize(const Constraints& constraints) {
  UpdateAvailableSizeAndMode(constraints);
  InitializeChildren();
  InitializeAlgorithmEnv();
}

void LayoutAlgorithm::InitializeChildren() {
  bool need_order = false;
  const auto container_display = container_->GetCSSStyle()->GetDisplay(
      container_->GetLayoutConfigs(), container_->attr_map());
  for (int i = 0; i < container_->GetChildCount(); ++i) {
    LayoutObject* child = static_cast<LayoutObject*>(container_->Find(i));
    const ComputedCSSStyle* child_style = child->GetCSSStyle();
    if (child_style->GetDisplay(container_->GetLayoutConfigs(),
                                container_->attr_map()) == DisplayType::kNone) {
      child->LayoutDisplayNone();
      continue;
    }

    child->GetBoxInfo()->InitializeBoxInfo(container_constraints_, *child,
                                           child->GetLayoutConfigs());

    if (!(container_->GetLayoutConfigs().IsFullQuirksMode() &&
          container_display != DisplayType::kFlex) &&
        (child_style->GetPosition() == PositionType::kAbsolute ||
         child_style->GetPosition() == PositionType::kFixed)) {
      absolute_or_fixed_items_.push_back(child);
      continue;
    } else if (child_style->GetPosition() == PositionType::kSticky) {
      sticky_items.push_back(child);
    }

    inflow_items_.push_back(child);

    if (child_style->GetOrder()) need_order = true;
  }
  if (need_order) {
    sort(inflow_items_.begin(), inflow_items_.end(),
         [](LayoutObject* obj1, LayoutObject* obj2) -> bool {
           return obj1->GetCSSStyle()->GetOrder() <
                  obj2->GetCSSStyle()->GetOrder();
         });
  }
}

bool LayoutAlgorithm::IsInflowSubTreeInSync() const {
  for (const auto* item : inflow_items_) {
    if (!item->IsInflowSubTreeInSyncWithLastMeasurement()) {
      return false;
    }
  }
  return true;
}

void LayoutAlgorithm::UpdateAvailableSizeAndMode(
    const Constraints& constraints) {
  container_constraints_ = Constraints();
  if (constraints[kHorizontal].Mode() != SLMeasureModeIndefinite) {
    container_constraints_[kHorizontal] =
        OneSideConstraint(constraints[kHorizontal].Size() -
                              container_->GetPaddingAndBorderHorizontal(),
                          constraints[kHorizontal].Mode());
  }
  if (constraints[kVertical].Mode() != SLMeasureModeIndefinite) {
    container_constraints_[kVertical] =
        OneSideConstraint(constraints[kVertical].Size() -
                              container_->GetPaddingAndBorderVertical(),
                          constraints[kVertical].Mode());
  }
}

FloatSize LayoutAlgorithm::PostLayoutProcessingAndResultBorderBoxSize() {
  FloatSize result;
  DCHECK(container_constraints_[kHorizontal].Mode() == SLMeasureModeDefinite);
  DCHECK(container_constraints_[kVertical].Mode() == SLMeasureModeDefinite);
  result.width_ = container_->GetBorderBoxWidthFromInnerWidth(
      container_constraints_[kHorizontal].Size());
  result.height_ = container_->GetBorderBoxHeightFromInnerHeight(
      container_constraints_[kVertical].Size());
  result.width_ = container_->ClampExactWidth(result.width_);
  result.height_ = container_->ClampExactHeight(result.height_);
  container_constraints_[kHorizontal] = OneSideConstraint::Definite(
      container_->GetInnerWidthFromBorderBoxWidth(result.width_));
  container_constraints_[kVertical] = OneSideConstraint::Definite(
      container_->GetInnerHeightFromBorderBoxHeight(result.height_));

  AfterResultBorderBoxSize();
  return result;
}

void LayoutAlgorithm::AfterResultBorderBoxSize() {}

void LayoutAlgorithm::AlignAbsoluteAndFixedItems() {
  for (LayoutObject* item : absolute_or_fixed_items_) {
    auto item_initial_position = GetAbsoluteOrFixedItemInitialPosition(item);

    std::array<Direction, 2> directions;
    directions[kHorizontal] = HorizontalFront();
    directions[kVertical] = VerticalFront();
    position_utils::CalcAbsoluteOrFixedPosition(
        item, container_, container_constraints_, item_initial_position,
        directions);
  }
}

// Absolute | Fixed
void LayoutAlgorithm::MeasureAbsoluteAndFixed() {
  for (LayoutObject* item : absolute_or_fixed_items_) {
    Constraints item_size_mode =
        position_utils::GetAbsoluteOrFixedItemSizeAndMode(
            item, container_, container_constraints_);

    item->UpdateMeasure(item_size_mode, true);
  }
}

void LayoutAlgorithm::HandleRelativePosition() {
  if (container_->GetLayoutConfigs().IsFullQuirksMode() &&
      container_->GetCSSStyle()->GetDisplay(container_->GetLayoutConfigs(),
                                            container_->attr_map()) !=
          DisplayType::kFlex) {
    return;
  }

  for (LayoutObject* item : inflow_items_) {
    if (item->GetCSSStyle()->GetPosition() == PositionType::kRelative) {
      position_utils::CalcRelativePosition(item, container_constraints_);
    }
  }
}

void LayoutAlgorithm::ItemsUpdateAlignment() {
  for (LayoutObject* item : inflow_items_) {
    item->UpdateAlignment();
  }
  for (LayoutObject* item : absolute_or_fixed_items_) {
    item->UpdateAlignment();
  }

  for (LayoutObject* item : sticky_items) {
    position_utils::UpdateStickyItemPosition(item, ScreenWidth(),
                                             container_constraints_);
  }
}

void LayoutAlgorithm::Alignment() {
  // The measure of absolute and fixed object is on align stage to avoid
  // unnecessary measurement
  MeasureAbsoluteAndFixed();

  AlignInFlowItems();

  AlignAbsoluteAndFixedItems();

  HandleRelativePosition();

  ItemsUpdateAlignment();
}

FloatSize LayoutAlgorithm::SizeDetermination() {
  SizeDeterminationByAlgorithm();

  return PostLayoutProcessingAndResultBorderBoxSize();
}

Constraints LayoutAlgorithm::GenerateDefaultConstraint(
    const LayoutObject& child) const {
  return property_utils::GenerateDefaultConstraints(child,
                                                    container_constraints_);
}

void LayoutAlgorithm::SetContainerBaseline() {}

}  // namespace starlight
}  // namespace lynx
