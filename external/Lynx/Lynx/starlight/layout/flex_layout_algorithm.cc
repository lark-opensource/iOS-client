// Copyright 2017 The Lynx Authors. All rights reserved.

#include "starlight/layout/flex_layout_algorithm.h"

#include <math.h>

#include <algorithm>
#include <vector>

#include "base/compiler_specific.h"
#include "base/float_comparison.h"
#include "starlight/layout/box_info.h"
#include "starlight/layout/elastic_layout_utils.h"
#include "starlight/layout/flex_info.h"
#include "starlight/layout/layout_object.h"
#include "starlight/layout/logic_direction_utils.h"
#include "starlight/layout/position_layout_utils.h"
#include "starlight/layout/property_resolving_utils.h"

namespace lynx {
namespace starlight {
FlexLayoutAlgorithm::FlexLayoutAlgorithm(LayoutObject* container)
    : LayoutAlgorithm(container) {}

void FlexLayoutAlgorithm::InitializeAlgorithmEnv() {
  flex_info_ = std::make_unique<FlexInfo>(inflow_items_.size());
}

void FlexLayoutAlgorithm::Reset() { flex_info_->Reset(); }

void FlexLayoutAlgorithm::SizeDeterminationByAlgorithm() {
  /*Algorithm-3
   * Determine the flex base size and hypothetical main size of each item:*/
  float total_hypothetical_main_size =
      DetermineFlexBaseSizeAndHypotheticalMainSize();
  /*Algorithm-4
   * Calculate the main size of the flex container using the rules
   * of the formatting context in which it participates.
   * And collect flex items into flex lines:
   * single-line: collect all the flex items into a single flex line.
   * otherwise: ....*/
  float flex_container_main_size =
      CalculateFlexContainerMainSize(total_hypothetical_main_size);
  /*Algorithm-5
   * Determine the main size of the flex container*/
  DetermineFlexContainerMainSize(flex_container_main_size);

  // Resolve each line
  for (auto line_info : flex_info_->line_info_) {
    // Algorithm-6 Resolve the flexible lengths of all the flex items to find
    // their used main size.
    ResolveFlexibleLengths(line_info);
  }

  DetermineHypotheticalCrossSize();

  CalculateCrossSizeOfEachFlexLine();

  DetermineContainerCrossSize();

  DetermineUsedCrossSizeOfEachFlexItem();
}

void FlexLayoutAlgorithm::AlignInFlowItems() {
  float cross_axis_start = 0.0f;
  float cross_axis_interval = 0.0f;
  CalculateAlignContent(cross_axis_start, cross_axis_interval);
  float line_cross_offset = cross_axis_start;

  for (LineInfo* line_info : flex_info_->line_info_) {
    // Main-Axis Alignment
    DistributeRemainingFreeSpace(line_info);
    // Cross-Axis Alignment
    CrossAxisAlignment(line_info, line_cross_offset);
    line_cross_offset += cross_axis_interval;
  }

  CalculateWrapReverse();
}

/*Algorithm-3
 * Determine the flex base size and hypothetical main size of each item:*/
float FlexLayoutAlgorithm::DetermineFlexBaseSizeAndHypotheticalMainSize() {
  std::vector<float>& base_size = flex_info_->flex_base_size_;
  for (size_t idx = 0; idx < inflow_items_.size(); ++idx) {
    LayoutObject* item = inflow_items_[idx];
    if (base::FloatsEqual(base_size[idx], 0.0f)) {
      base_size[idx] = ChildCalculateFlexBasis(item);
    }

    if (item->GetCSSStyle()->GetFlexGrow() != 0)
      flex_info_->has_item_flex_grow_ = 1;
    if (item->GetCSSStyle()->GetFlexShrink() != 0)
      flex_info_->has_item_flex_shrink_ = 1;
  }
  return ElasticLayoutUtils::ComputeHypotheticalSizes(
      inflow_items_, base_size, *this, flex_info_->hypothetical_main_size_);
}

float FlexLayoutAlgorithm::ChildCalculateFlexBasis(LayoutObject* child) {
  const bool is_row = IsHorizontal();
  const ComputedCSSStyle* child_style = child->GetCSSStyle();
  const LayoutUnit& flex_basis =
      NLengthToLayoutUnit(child_style->GetFlexBasis(),
                          container_constraints_[kMainAxis].ToPercentBase());

  if (flex_basis.IsDefinite()) {
    return flex_basis.ToFloat();
  }

  // auto或不确定的container主轴长度下的百分比值，使用主轴上的数据
  auto child_constraints = GenerateDefaultConstraint(*child);
  if (child_constraints[MainAxis()].Mode() == SLMeasureModeDefinite) {
    return child_constraints[MainAxis()].Size();
  }

  // Here we need to measure child.
  if (container_style_->GetOverflow() == OverflowType::kScroll) {
    child_constraints[MainAxis()] = OneSideConstraint::Indefinite();
  }
  //  }

  /* TRY TO RESOLVE STRETCH */
  FlexAlignType align = child_style->GetAlignSelf();
  if (align == FlexAlignType::kAuto) align = container_style_->GetAlignItems();
  const bool child_stretch = align == FlexAlignType::kStretch;

  if (!IsSLDefiniteMode(child_constraints[CrossAxis()].Mode()) &&
      child_stretch &&
      IsSLDefiniteMode(container_constraints_[CrossAxis()].Mode()) &&
      !logic_direction_utils::GetCSSDimensionSize(child_style, CrossAxis())
           .IsIntrinsic()) {
    child_constraints[CrossAxis()] =
        OneSideConstraint::Definite(child_constraints[CrossAxis()].Size());
  }

  FloatSize result = child->UpdateMeasure(child_constraints, false);
  return is_row ? result.width_ : result.height_;
}

// Algorithm-4 Calculate the main size of the flex container(auto margins on
// flex items are treated as 0), according to the mode and previous
// container_main_size_. Then, collect flex items into flex lines, container
// main size will shrink to max flex line size if container main axis mode is
// atmost
float FlexLayoutAlgorithm::CalculateFlexContainerMainSize(
    float total_hypothetical_main_size) {
  if (IsSLDefiniteMode(container_constraints_[kMainAxis].Mode())) {
    // TODO(zhangmin): After Clamping is unified and is done before this step,
    // use return here.
    // return;
    total_hypothetical_main_size = container_constraints_[kMainAxis].Size();
  } else if (IsSLAtMostMode(container_constraints_[kMainAxis].Mode())) {
    total_hypothetical_main_size = std::min(
        total_hypothetical_main_size, container_constraints_[kMainAxis].Size());
  }

  // Apply min-max size to content box
  BoxInfo* box_info = container_->GetBoxInfo();
  float main_axis_min_size = box_info->min_size_[kMainAxis];
  main_axis_min_size -= logic_direction_utils::GetPaddingAndBorderDimensionSize(
      container_, MainAxis());
  total_hypothetical_main_size =
      std::max(total_hypothetical_main_size, main_axis_min_size);
  total_hypothetical_main_size = std::max(total_hypothetical_main_size, 0.0f);

  // Collect flex items into flex lines, after preliminary calculating the main
  // size of the flex container
  float sum_hypothetical_main_size = 0;
  float sum_flex_base_size = 0;
  // For this step, the size of a flex item is its outer hypothetical main
  // size.(Note: This can be negative.)

  if (container_style_->GetFlexWrap() == FlexWrapType::kNowrap) {
    for (size_t idx = 0; idx < inflow_items_.size(); ++idx) {
      sum_hypothetical_main_size +=
          GetOuterHypotheticalMainSize(static_cast<int>(idx));
      sum_flex_base_size += GetOuterFlexBaseMainSIze(static_cast<int>(idx));
    }
    bool is_flex_grow =
        sum_hypothetical_main_size <= total_hypothetical_main_size;
    flex_info_->line_info_.push_back(new LineInfo(
        0, static_cast<int>(inflow_items_.size()), 0,
        total_hypothetical_main_size - sum_flex_base_size, is_flex_grow));
    return total_hypothetical_main_size;
  }

  size_t start = 0, idx = start;
  // Record the max flex line size, and the container main size will shrink to
  // max flex line size if the container main axis mode is atmost
  float max_flex_line_size = 0.0f;
  while (idx < inflow_items_.size()) {
    if (!base::FloatsLarger(
            sum_hypothetical_main_size +
                GetOuterHypotheticalMainSize(static_cast<int>(idx)),
            total_hypothetical_main_size)) {
      sum_hypothetical_main_size +=
          GetOuterHypotheticalMainSize(static_cast<int>(idx));
      sum_flex_base_size += GetOuterFlexBaseMainSIze(static_cast<int>(idx));
      max_flex_line_size =
          base::FloatsLarger(sum_hypothetical_main_size, max_flex_line_size)
              ? sum_hypothetical_main_size
              : max_flex_line_size;
      idx++;
      continue;
    }
    // It will shrink if the first item is larger than container_main_size
    // (total_hypothetical_main_size)
    if (start == idx) {
      flex_info_->line_info_.push_back(
          new LineInfo(static_cast<int>(start), static_cast<int>(start + 1), 0,
                       total_hypothetical_main_size -
                           GetOuterFlexBaseMainSIze(static_cast<int>(idx)),
                       false));
      max_flex_line_size = total_hypothetical_main_size;
      start = ++idx;
      continue;
    }
    // It will be flex-grow if more than one item in a flex line
    flex_info_->line_info_.push_back(
        new LineInfo(static_cast<int>(start), static_cast<int>(idx), 0,
                     total_hypothetical_main_size - sum_flex_base_size, true));
    sum_hypothetical_main_size = 0;
    sum_flex_base_size = 0;
    start = idx;
  }
  flex_info_->line_info_.push_back(new LineInfo(
      static_cast<int>(start), static_cast<int>(inflow_items_.size()), 0,
      total_hypothetical_main_size - sum_flex_base_size, true));
  // Container main size will shrink to max flex line size if container main
  // axis mode is atmost
  if (IsSLAtMostMode(container_constraints_[kMainAxis].Mode()) &&
      !container_->GetLayoutConfigs().IsFlexWrapQuirksMode()) {
    return max_flex_line_size;
  } else
    return total_hypothetical_main_size;
}

// Algorithm-5 Determine the main size of the flex container
void FlexLayoutAlgorithm::DetermineFlexContainerMainSize(
    float flex_container_main_size) {
  UpdateContainerMainSize(flex_container_main_size);
}

// Algorithm-6 Resolve the flexible lengths of all the flex items to find
// their used main size.
void FlexLayoutAlgorithm::ResolveFlexibleLengths(LineInfo* line_info) {
  ElasticLayoutUtils::ElasticInfos infos(
      inflow_items_, flex_info_->flex_base_size_,
      flex_info_->hypothetical_main_size_, line_info->is_flex_grow_, *this,
      line_info->start_, line_info->end_);

  ElasticLayoutUtils::ElasticFactorGetter factor_getter;
  if (line_info->is_flex_grow_) {
    factor_getter = [](const LayoutObject& item) -> float {
      return item.GetCSSStyle()->GetFlexGrow();
    };
  } else {
    factor_getter = [](const LayoutObject& item) -> float {
      return item.GetCSSStyle()->GetFlexShrink();
    };
  }
  line_info->remaining_free_space_ =
      ElasticLayoutUtils::ComputeElasticItemSizes(
          infos, container_constraints_[kMainAxis].Size(), factor_getter,
          flex_info_->flex_main_size_);
}

// Algorithm-7 Determine the hypothetical cross size of each item
void FlexLayoutAlgorithm::DetermineHypotheticalCrossSize() {
  bool is_row = IsHorizontal();
  for (size_t idx = 0; idx < inflow_items_.size(); ++idx) {
    const ComputedCSSStyle* item_style = inflow_items_[idx]->GetCSSStyle();
    const LayoutUnit& length_on_cross_axis = NLengthToLayoutUnit(
        logic_direction_utils::GetCSSDimensionSize(item_style, CrossAxis()),
        container_constraints_[CrossAxis()].ToPercentBase());
    const LayoutUnit& length_on_main_axis = NLengthToLayoutUnit(
        logic_direction_utils::GetCSSDimensionSize(item_style, MainAxis()),
        container_constraints_[MainAxis()].ToPercentBase());

    FlexAlignType align = item_style->GetAlignSelf();
    if (align == FlexAlignType::kAuto)
      align = container_style_->GetAlignItems();
    const bool child_stretch = align == FlexAlignType::kStretch;

    Constraints child_constraints =
        GenerateDefaultConstraint(*inflow_items_[idx]);
    child_constraints[MainAxis()] =
        OneSideConstraint::Definite(flex_info_->flex_main_size_[idx]);

    if (!inflow_items_[idx]->GetLayoutConfigs().IsFullQuirksMode() ||
        length_on_main_axis.IsDefinite()) {
      if (length_on_cross_axis.IsIndefinite() &&
          !base::FloatsEqual(item_style->GetAspectRatio(), -1.0f)) {
        child_constraints[CrossAxis()] = OneSideConstraint::Indefinite();
        property_utils::ApplyAspectRatio(inflow_items_[idx], child_constraints);
      }
    }

    if (IsSLAtMostMode(child_constraints[kCrossAxis].Mode()) &&
        !logic_direction_utils::GetCSSDimensionSize(item_style, CrossAxis())
             .IsIntrinsic()) {
      if (child_stretch &&
          IsSLDefiniteMode(container_constraints_[kCrossAxis].Mode()) &&
          container_style_->GetFlexWrap() == FlexWrapType::kNowrap) {
        child_constraints[CrossAxis()] =
            OneSideConstraint::Definite(child_constraints[CrossAxis()].Size());
      }
    }
    FloatSize result;
    flex_info_->apply_stretch_later_[idx] =
        ShouldApplyStretchAndLayoutLater(static_cast<int>(idx));

    if (flex_info_->apply_stretch_later_[idx] &&
        IsSLDefiniteMode(child_constraints[CrossAxis()].Mode())) {
      if (is_row) {
        result.height_ = child_constraints[CrossAxis()].Size();
      } else {
        result.width_ = child_constraints[CrossAxis()].Size();
      }
    } else {
      result = inflow_items_[idx]->UpdateMeasure(child_constraints,
                                                 container_->GetFinalMeasure());
    }

    flex_info_->hypothetical_cross_size_[idx] =
        container_style_->IsRow(container_->GetLayoutConfigs(),
                                container_->attr_map())
            ? result.height_
            : result.width_;
    // clamp min-max size
    flex_info_->hypothetical_cross_size_[idx] =
        is_row ? inflow_items_[idx]->ClampExactHeight(
                     flex_info_->hypothetical_cross_size_[idx])
               : inflow_items_[idx]->ClampExactWidth(
                     flex_info_->hypothetical_cross_size_[idx]);
  }
}

// Algorithm-8 Calculate the cross size of each flex line.
void FlexLayoutAlgorithm::CalculateCrossSizeOfEachFlexLine() {
  // If the flex container is single-line and has a definite cross size, the
  // cross size of the flex line is the flex container’s inner cross size.
  if (container_style_->GetFlexWrap() == FlexWrapType::kNowrap &&
      container_constraints_[kCrossAxis].Mode() == SLMeasureModeDefinite) {
    flex_info_->line_info_[0]->line_cross_size_ =
        container_constraints_[kCrossAxis].Size();
    return;
  }

  float line_cross_size_sum = 0.0f;
  for (LineInfo* line_info : flex_info_->line_info_) {
    float largest_outer_hypothetical_cross_size = 0;
    // 8-2 Among all the items not collected by the previous step, find the
    // largest outer hypothetical cross size.
    for (int idx = line_info->start_; idx < line_info->end_; ++idx) {
      float item_outer_hypothetical_cross_size =
          GetOuterHypotheticalCrossSize(idx);
      largest_outer_hypothetical_cross_size =
          item_outer_hypothetical_cross_size >
                  largest_outer_hypothetical_cross_size
              ? item_outer_hypothetical_cross_size
              : largest_outer_hypothetical_cross_size;

      if (container_->GetBaselineFlag()) {
        const LayoutObject* item = inflow_items_[idx];

        if (item->HasBaseline()) {
          line_info->baseline_ =
              std::max(line_info->baseline_, item->GetBaseline());
        } else {
          line_info->baseline_ = std::max(
              line_info->baseline_, flex_info_->hypothetical_cross_size_[idx]);
        }
      }
    }
    // 8-3 The used cross-size of the flex line is the largest of the numbers
    // found in the previous two steps and zero.
    line_info->line_cross_size_ =
        std::max(largest_outer_hypothetical_cross_size, 0.0f);
    line_cross_size_sum += line_info->line_cross_size_;
  }

  // calc align-content:stretch
  if (container_style_->GetAlignContent() == AlignContentType::kStretch &&
      IsSLDefiniteMode(container_constraints_[kCrossAxis].Mode()) &&
      line_cross_size_sum < container_constraints_[kCrossAxis].Size()) {
    float stretch_to_distribute =
        (container_constraints_[kCrossAxis].Size() - line_cross_size_sum) /
        (flex_info_->line_info_).size();
    for (LineInfo* line_info : flex_info_->line_info_) {
      line_info->line_cross_size_ += stretch_to_distribute;
    }
  }
}

// Algorithm-11 Determine the used cross size of each flex item
void FlexLayoutAlgorithm::DetermineUsedCrossSizeOfEachFlexItem() {
  for (LineInfo* line_info : flex_info_->line_info_) {
    for (int idx = line_info->start_; idx < line_info->end_; ++idx) {
      // If a flex item has align-self: stretch, its computed cross size
      // property is auto, and neither of its cross-axis margins are auto, the
      // used outer cross size is the used cross size of its flex line, clamped
      // according to the item’s used min and max cross sizes.
      LayoutObject* item = inflow_items_[idx];
      if (flex_info_->apply_stretch_later_[idx]) {
        Constraints child_constraint;
        // percent may become resolvable in this stage, so recompute the
        // preferred size
        const auto preferred_size =
            property_utils::ComputePreferredSize(*item, container_constraints_);
        float child_cross_size = line_info->line_cross_size_ -
                                 item->GetBoxInfo()->margin_[kCrossFront] -
                                 item->GetBoxInfo()->margin_[kCrossBack];
        if (preferred_size[CrossAxis()].IsDefinite()) {
          child_cross_size = preferred_size[CrossAxis()].ToFloat();
        }
        child_constraint[CrossAxis()] =
            OneSideConstraint::Definite(child_cross_size);
        child_constraint[MainAxis()] =
            OneSideConstraint::Definite(flex_info_->flex_main_size_[idx]);
        FloatSize result;
        result = item->UpdateMeasure(child_constraint,
                                     container_->GetFinalMeasure());

        flex_info_->flex_cross_size_[idx] =
            logic_direction_utils::SizeDimension(result, CrossAxis());
        // TODO: clamp
      } else {
        // Otherwise, the used cross size is the item’s hypothetical cross size.
        flex_info_->flex_cross_size_[idx] =
            flex_info_->hypothetical_cross_size_[idx];
      }

      if (container_->GetBaselineFlag()) {
        if (item->HasBaseline()) {
          line_info->baseline_ =
              std::max(line_info->baseline_, item->GetBaseline());
        } else {
          line_info->baseline_ =
              std::max(line_info->baseline_, flex_info_->flex_cross_size_[idx]);
        }
      }
    }
  }
}

bool FlexLayoutAlgorithm::ShouldApplyStretchAndLayoutLater(int idx) {
  FlexAlignType align_type = inflow_items_[idx]->GetCSSStyle()->GetAlignSelf();
  if (align_type == FlexAlignType::kAuto) {
    align_type = container_style_->GetAlignItems();
  }
  return align_type == FlexAlignType::kStretch &&
         IsCrossSizeAutoAndMarginNonAuto(idx);
}

bool FlexLayoutAlgorithm::IsCrossSizeAutoAndMarginNonAuto(int idx) {
  const auto preferred_size = property_utils::ComputePreferredSize(
      *inflow_items_[idx], container_constraints_);
  const auto* child_style = inflow_items_[idx]->GetCSSStyle();
  const auto is_row = IsHorizontal();
  const auto min_cross =
      is_row ? child_style->GetMinHeight() : child_style->GetMinWidth();
  const auto max_cross =
      is_row ? child_style->GetMaxHeight() : child_style->GetMaxWidth();
  const auto length_cross =
      is_row ? child_style->GetHeight() : child_style->GetWidth();
  const NLength& cross_margin_start =
      is_row ? child_style->GetMarginTop() : child_style->GetMarginLeft();
  const NLength& cross_margin_end =
      is_row ? child_style->GetMarginBottom() : child_style->GetMarginRight();
  // container box的cross axis mode为indefinite，item的cross size为%时，同auto
  return ((preferred_size[CrossAxis()].IsIndefinite() &&
           !length_cross.IsIntrinsic()) ||
          (!IsSLDefiniteMode(container_constraints_[CrossAxis()].Mode()) &&
           (min_cross.IsPercent() || max_cross.IsPercent() ||
            length_cross.IsPercent()))) &&
         !(cross_margin_start.IsAuto() || cross_margin_end.IsAuto());
}

// Algorithm-12 Distribute any remaining free space
void FlexLayoutAlgorithm::DistributeRemainingFreeSpace(LineInfo* line_info) {
  Items line_items(inflow_items_.begin() + line_info->start_,
                   inflow_items_.begin() + line_info->end_);

  float line_start = 0;
  float line_interval = 0;
  if (!CalculateAndSetAutoMargins(line_items,
                                  line_info->remaining_free_space_)) {
    CalculateJustifyContent(line_info, line_start, line_interval);
  }
  MainAxisAlignment(line_items, line_start, line_interval);
}

bool FlexLayoutAlgorithm::CalculateAndSetAutoMargins(
    Items& line_items, float remaining_free_space) {
  std::vector<float*> auto_margins;
  bool is_row = IsHorizontal();
  for (LayoutObject* item : line_items) {
    FourValue& margin = item->GetBoxInfo()->margin_;
    if (is_row) {
      if (item->GetCSSStyle()->GetMarginLeft().IsAuto()) {
        auto_margins.push_back(&(margin[kLeft]));
      }
      if (item->GetCSSStyle()->GetMarginRight().IsAuto()) {
        auto_margins.push_back(&(margin[kRight]));
      }
    } else {
      if (item->GetCSSStyle()->GetMarginTop().IsAuto()) {
        auto_margins.push_back(&(margin[kTop]));
      }
      if (item->GetCSSStyle()->GetMarginBottom().IsAuto()) {
        auto_margins.push_back(&(margin[kBottom]));
      }
    }
  }

  if (auto_margins.empty()) {
    return false;
  }

  float margin_value = remaining_free_space / auto_margins.size();
  for (float* margin : auto_margins) {
    *margin = margin_value;
  }
  return true;
}

void FlexLayoutAlgorithm::CalculateJustifyContent(LineInfo* line_info,
                                                  float& main_axis_start,
                                                  float& main_axis_interval) {
  int current_line_count = line_info->end_ - line_info->start_;
  logic_direction_utils::ResolveJustifyContent(
      container_style_, current_line_count, line_info->remaining_free_space_,
      main_axis_interval, main_axis_start);
}

void FlexLayoutAlgorithm::MainAxisAlignment(Items line_items,
                                            float main_axis_start,
                                            float main_axis_interval) {
  float offset = main_axis_start - main_axis_interval;
  float item_size = 0;
  float accumulated_error = 0;
  ALLOW_UNUSED_LOCAL(accumulated_error);

  for (auto item : line_items) {
    offset += main_axis_interval;

    logic_direction_utils::SetBoundOffsetFrom(
        item, MainFront(), BoundType::kMargin, BoundType::kContent, offset);

    item_size =
        logic_direction_utils::GetMarginBoundDimensionSize(item, MainAxis());

    offset += item_size;
  }
}

void FlexLayoutAlgorithm::CalculateAlignContent(float& cross_axis_start,
                                                float& cross_axis_interval) {
  const AlignContentType align_content = container_style_->GetAlignContent();
  if (align_content == AlignContentType::kStretch) {
    return;
  }
  float line_height_sum = 0.0f;
  for (auto line_info : flex_info_->line_info_) {
    line_height_sum += line_info->line_cross_size_;
  }

  int32_t item_count = static_cast<int32_t>(flex_info_->line_info_.size());
  float available_space =
      container_constraints_[kCrossAxis].Size() - line_height_sum;

  logic_direction_utils::ResolveAlignContent(
      container_style_, item_count, available_space, cross_axis_interval,
      cross_axis_start);
}

void FlexLayoutAlgorithm::CrossAxisAlignment(LineInfo* line_info,
                                             float& line_cross_offset) {
  for (int idx = line_info->start_; idx < line_info->end_; ++idx) {
    AlignItems(idx, line_info->line_cross_size_, line_cross_offset,
               line_info->baseline_);
  }
  line_cross_offset += line_info->line_cross_size_;
}

// Algorithm-14 Align all flex items along the cross-axis per align-self
void FlexLayoutAlgorithm::AlignItems(int idx, float line_cross_size,
                                     float line_cross_offset,
                                     float line_baseline) {
  float offset = line_cross_offset;
  LayoutObject* item = inflow_items_[idx];
  float cross_margin_bound =
      logic_direction_utils::GetMarginBoundDimensionSize(item, CrossAxis());

  const ComputedCSSStyle* item_style = inflow_items_[idx]->GetCSSStyle();
  const NLength& margin_cross_front =
      logic_direction_utils::GetMargin(item_style, CrossFront());
  const NLength& margin_cross_after =
      logic_direction_utils::GetMargin(item_style, CrossBack());
  if (margin_cross_front.IsAuto() || margin_cross_after.IsAuto()) {
    float content_size = logic_direction_utils::GetBorderBoundDimensionSize(
        container_, CrossAxis());
    logic_direction_utils::ResolveAutoMargins(inflow_items_[idx], content_size,
                                              CrossAxis());
  } else {
    FlexAlignType align = item->GetCSSStyle()->GetAlignSelf();
    if (align == FlexAlignType::kAuto) {
      align = container_style_->GetAlignItems();
    }

    switch (align) {
      case FlexAlignType::kFlexStart:
      case FlexAlignType::kStretch:
      case FlexAlignType::kAuto:
        // do nothing
        break;
      case FlexAlignType::kFlexEnd:
        offset += line_cross_size - cross_margin_bound;
        break;

      case FlexAlignType::kCenter:
        offset += (line_cross_size - cross_margin_bound) / 2.0f;
        break;
      case FlexAlignType::kBaseline:
        if (container_style_->IsRow(container_->GetLayoutConfigs(),
                                    container_->attr_map())) {
          offset += line_baseline - item->GetBaseline();
        }
        break;
    }
  }

  logic_direction_utils::SetBoundOffsetFrom(
      item, CrossFront(), BoundType::kMargin, BoundType::kContent, offset);
}

void FlexLayoutAlgorithm::CalculateWrapReverse() {
  if (container_style_->GetFlexWrap() != FlexWrapType::kWrapReverse) {
    return;
  }

  for (LayoutObject* item : inflow_items_) {
    float available_space_offset = logic_direction_utils::GetBoundOffsetFrom(
        item, CrossAxis(), BoundType::kMargin, BoundType::kContent);
    float content_space = logic_direction_utils::GetContentBoundDimensionSize(
        container_, CrossAxis());

    float reverse_offset =
        content_space - available_space_offset -
        logic_direction_utils::GetMarginBoundDimensionSize(item, CrossAxis());

    logic_direction_utils::SetBoundOffsetFrom(
        item, CrossFront(), BoundType::kMargin, BoundType::kContent,
        reverse_offset);
  }
}

// Algorithm-15 Determine the flex container’s used cross size:
void FlexLayoutAlgorithm::DetermineContainerCrossSize() {
  // If the cross size property is a definite size, use that,
  if (container_constraints_[kCrossAxis].Mode() == SLMeasureModeDefinite) {
    // just use the size do nothing
    return;
  }
  // Otherwise, use the sum of the flex lines' cross sizes
  float cross_size_sum = 0;
  for (LineInfo* line_info : flex_info_->line_info_) {
    cross_size_sum += line_info->line_cross_size_;
  }

  // clamped by the used min and max cross sizes of the flex container.
  BoxInfo* box_info = container_->GetBoxInfo();
  float border = IsHorizontal()
                     ? container_style_->GetBorderFinalWidthVertical()
                     : container_style_->GetBorderFinalWidthHorizontal();

  float cross_axis_max_size = box_info->max_size_[CrossAxis()];
  cross_axis_max_size -=
      box_info->padding_[kCrossFront] + box_info->padding_[kCrossBack] + border;
  float cross_axis_min_size = box_info->min_size_[CrossAxis()];
  cross_axis_min_size -=
      box_info->padding_[kCrossFront] + box_info->padding_[kCrossBack] + border;
  cross_size_sum = std::min(cross_size_sum, cross_axis_max_size);
  cross_size_sum = std::max(cross_size_sum, cross_axis_min_size);
  cross_size_sum = std::max(cross_size_sum, 0.0f);
  if (IsSLAtMostMode(container_constraints_[kCrossAxis].Mode())) {
    cross_size_sum =
        std::min(cross_size_sum, container_constraints_[kCrossAxis].Size());
  }
  UpdateCrossSize(cross_size_sum);
  return;
}

BoxPositions FlexLayoutAlgorithm::GetAbsoluteOrFixedItemInitialPosition(
    LayoutObject* absolute_or_fixed_item) {
  BoxPositions item_position;

  item_position[MainAxis()] =
      GetAbsoluteOrFixedItemMainAxisPosition(absolute_or_fixed_item);
  item_position[CrossAxis()] =
      GetAbsoluteOrFixedItemCrossAxisPosition(absolute_or_fixed_item);

  return item_position;
}

Position FlexLayoutAlgorithm::GetAbsoluteOrFixedItemCrossAxisPosition(
    LayoutObject* absolute_or_fixed_item) {
  Position cross_axis_position = Position::kStart;

  const ComputedCSSStyle* absolute_or_fixed_item_style =
      absolute_or_fixed_item->GetCSSStyle();

  FlexAlignType align = container_style_->GetAlignItems();
  if (absolute_or_fixed_item_style->GetAlignSelf() != FlexAlignType::kAuto) {
    align = absolute_or_fixed_item_style->GetAlignSelf();
  }
  switch (align) {
    case FlexAlignType::kFlexStart:
    case FlexAlignType::kStretch:
    case FlexAlignType::kAuto:
    case FlexAlignType::kBaseline:
      cross_axis_position = Position::kStart;
      break;
    case FlexAlignType::kFlexEnd:
      cross_axis_position = Position::kEnd;
      break;
    case FlexAlignType::kCenter:
      cross_axis_position = Position::kCenter;
      break;
  }

  // if container FlexWrapType is kWrapReverse, reverse
  if (container_style_->GetFlexWrap() == FlexWrapType::kWrapReverse) {
    cross_axis_position = position_utils::ReversePosition(cross_axis_position);
  }

  return cross_axis_position;
}

Position FlexLayoutAlgorithm::GetAbsoluteOrFixedItemMainAxisPosition(
    LayoutObject* absolute_or_fixed_item) {
  Position main_axis_position = Position::kStart;

  switch (container_style_->GetJustifyContent()) {
    // stretch is not supported by flex, it behaves as flex-start.
    case JustifyContentType::kStretch:
    case JustifyContentType::kFlexStart:
    case JustifyContentType::kSpaceBetween:
      main_axis_position = Position::kStart;
      break;
    case JustifyContentType::kFlexEnd:
      main_axis_position = Position::kEnd;
      break;
    case JustifyContentType::kCenter:
    case JustifyContentType::kSpaceAround:
    case JustifyContentType::kSpaceEvenly:
      main_axis_position = Position::kCenter;
      break;
  }

  return main_axis_position;
}

// 一些功能
void FlexLayoutAlgorithm::UpdateContainerMainSize(float container_main_size) {
  if (container_constraints_[kMainAxis].Mode() == SLMeasureModeDefinite &&
      base::FloatsEqual(container_constraints_[kMainAxis].Size(),
                        container_main_size)) {
    return;
  }
  container_constraints_[kMainAxis] =
      OneSideConstraint::Definite(container_main_size);

  // TODO(zhixuan): circular update dependencies below.
  for (LayoutObject* item : inflow_items_) {
    item->GetBoxInfo()->UpdateBoxData(container_constraints_, *item,
                                      item->GetLayoutConfigs());
  }
}

void FlexLayoutAlgorithm::UpdateCrossSize(float container_cross_size) {
  if (container_constraints_[CrossAxis()].Mode() == SLMeasureModeDefinite &&
      base::FloatsEqual(container_constraints_[CrossAxis()].Size(),
                        container_cross_size)) {
    return;
  }
  container_constraints_[CrossAxis()] =
      OneSideConstraint::Definite(container_cross_size);

  if (!container_->GetLayoutConfigs().IsFlexAlignQuirksMode()) {
    // update flex line info.
    CalculateCrossSizeOfEachFlexLine();
  }

  // TODO(zhixuan): circular update dependencies below.
  for (LayoutObject* item : inflow_items_) {
    item->GetBoxInfo()->UpdateBoxData(container_constraints_, *item,
                                      item->GetLayoutConfigs());
  }
}

float FlexLayoutAlgorithm::GetOuterHypotheticalMainSize(int idx) {
  FourValue& margin = inflow_items_[idx]->GetBoxInfo()->margin_;
  return flex_info_->hypothetical_main_size_[idx] + margin[kMainFront] +
         margin[kMainBack];
}
float FlexLayoutAlgorithm::GetOuterFlexBaseMainSIze(int idx) {
  FourValue& margin = inflow_items_[idx]->GetBoxInfo()->margin_;
  return flex_info_->flex_base_size_[idx] + margin[kMainFront] +
         margin[kMainBack];
}
float FlexLayoutAlgorithm::GetOuterHypotheticalCrossSize(int idx) {
  FourValue& margin = inflow_items_[idx]->GetBoxInfo()->margin_;
  return flex_info_->hypothetical_cross_size_[idx] + margin[kCrossFront] +
         margin[kCrossBack];
}

void FlexLayoutAlgorithm::SetContainerBaseline() {
  if (IsHorizontal()) {
    float cross_axis_start = 0.0f;
    float cross_axis_interval = 0.0f;
    CalculateAlignContent(cross_axis_start, cross_axis_interval);
    float line_cross_offset = cross_axis_start;
    float max_possible_baseline = flex_info_->line_info_[0]->baseline_;

    for (int idx = flex_info_->line_info_[0]->start_;
         idx < flex_info_->line_info_[0]->end_; ++idx) {
      float offset = line_cross_offset;
      LayoutObject* item = inflow_items_[idx];

      FlexAlignType align = item->GetCSSStyle()->GetAlignSelf();
      if (align == FlexAlignType::kAuto) {
        align = container_style_->GetAlignItems();
      }

      if (!(align == FlexAlignType::kFlexEnd ||
            align == FlexAlignType::kCenter))
        continue;

      float cross_margin_bound =
          logic_direction_utils::GetMarginBoundDimensionSize(item, CrossAxis());

      if (item->HasBaseline()) {
        offset = item->GetBaseline();
      } else {
        offset = flex_info_->flex_cross_size_[idx];
      }

      if (align == FlexAlignType::kFlexEnd) {
        offset +=
            flex_info_->line_info_[0]->line_cross_size_ - cross_margin_bound;
      } else if (align == FlexAlignType::kCenter) {
        offset +=
            (flex_info_->line_info_[0]->line_cross_size_ - cross_margin_bound) /
            2.0f;
      }

      max_possible_baseline = std::max(max_possible_baseline, offset);
    }

    container_->SetBaseline(
        std::max(flex_info_->line_info_[0]->baseline_, max_possible_baseline));
  }
}
}  // namespace starlight
}  // namespace lynx
